import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/providers.dart';
import '../../home/data/app_api.dart';

abstract interface class WorkoutCacheStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureWorkoutCacheStore implements WorkoutCacheStore {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  @override
  Future<String?> read(String key) => storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);
}

String? workoutCacheOwner(String? token) {
  if (token == null) return null;
  try {
    final payload =
        jsonDecode(
              utf8.decode(
                base64Url.decode(base64Url.normalize(token.split('.')[1])),
              ),
            )
            as Map;
    return payload['sub'] as String?;
  } catch (_) {
    return null;
  }
}

String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

String workoutRecordKey((String, int, int) key) =>
    jsonEncode([key.$1, key.$2, key.$3]);

/// Durable session journal and outbox, isolated by authenticated account.
/// Native controls only represent a queue; this journal retains the whole plan.
class WorkoutSessionCache {
  WorkoutSessionCache(this.store, this.readToken, {this.send});
  final Future<void> Function(Map<String, dynamic>)? send;
  final WorkoutCacheStore store;
  final Future<String?> Function() readToken;
  String? owner;
  Map<String, dynamic> _data = {};
  Future<void> _writes = Future.value();
  Future<bool>? _loading;
  Future<void>? _sending;
  String? _inFlight;
  String? _cancelRetryId;
  Map<String, dynamic> get _drafts =>
      (_data['drafts'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _outbox =>
      (_data['outbox'] as Map<String, dynamic>?) ?? {};
  String? get activeId => _data['activeId'] as String?;
  Map<String, dynamic>? get active =>
      _drafts[activeId] as Map<String, dynamic>?;
  int get pendingCount => _outbox.length;
  bool isPending(String id) =>
      _outbox.entries.any((e) => e.key == id || e.value['sessionId'] == id);
  DateTime? get startedAt =>
      DateTime.tryParse(active?['startedAt'] as String? ?? '');
  Map<String, dynamic>? get lastCompletion =>
      _data['lastCompletion'] as Map<String, dynamic>?;
  bool restoring = false;

  Future<bool> bind() =>
      _loading ??= _bind().whenComplete(() => _loading = null);
  Future<bool> _bind() async {
    final nextOwner = workoutCacheOwner(await readToken());
    if (nextOwner == owner) return false;
    await _writes.catchError((Object _) {});
    // Never expose the previous account if reading the next account fails.
    owner = null;
    _cancelRetryId = null;
    _data = {};
    final raw = nextOwner == null
        ? null
        : await store.read('workout_sessions_v1_$nextOwner');
    // A malformed cache is not silently overwritten with an empty session.
    final nextData = raw == null
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    owner = nextOwner;
    _data = nextData;
    return true;
  }

  Future<void> _persist() {
    final account = owner;
    if (account == null) return Future.value();
    final snapshot = jsonEncode(_data);
    _writes = _writes
        .catchError((Object _) {})
        .then((_) => store.write('workout_sessions_v1_$account', snapshot));
    unawaited(
      _writes.catchError((Object e) {
        debugPrint('Workout cache: $e');
      }),
    );
    return _writes;
  }

  Future<void> flush() => _writes;

  Future<void> open(String day, List<Map<String, dynamic>> plan) async {
    await bind();
    if (owner == null) {
      throw StateError('Workout cache requires an authenticated account');
    }
    if (active != null && active!['day'] != day) {
      throw StateError('Another workout is in progress');
    }
    _data.putIfAbsent('drafts', () => <String, dynamic>{});
    final existing = _drafts.entries
        .where((e) => e.value['day'] == day && e.value['status'] == 'active')
        .firstOrNull;
    final id = existing?.key ?? _uuid();
    _drafts.putIfAbsent(
      id,
      () => <String, dynamic>{
        'id': id,
        'day': day,
        'status': 'active',
        'createdAt': DateTime.now().toIso8601String(),
        'plan': jsonDecode(jsonEncode(plan)),
        'originalPlan': jsonDecode(jsonEncode(plan)),
        'records': <String, dynamic>{},
        'swaps': <String, dynamic>{},
      },
    );
    _data['activeId'] = id;
    final draft = active!;
    if (draft['stagedVersion'] != 2) {
      draft['stagedVersion'] = 2;
      draft['startedAt'] ??= draft['createdAt'];
      _enqueue(draft, 'start', {
        'dayName': day,
        'startedAt': DateTime.parse(
          draft['startedAt'] as String,
        ).toUtc().toIso8601String(),
      });
      for (final entry in (draft['records'] as Map).entries.toList()) {
        _stageExercise(
          draft,
          entry.key as String,
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }
    await _persist();
    _kick();
  }

  Map<String, dynamic>? record((String, int, int) key) =>
      (active?['records'] as Map?)?[workoutRecordKey(key)]
          as Map<String, dynamic>?;
  Map<String, dynamic> get records =>
      Map<String, dynamic>.from(active?['records'] as Map? ?? {});
  void capture((String, int, int) key, Map<String, dynamic> state) {
    final draft = active;
    if (restoring || draft == null || draft['status'] != 'active') return;
    if (!(draft['plan'] as List).any((e) => e['nome'] == key.$1)) return;
    final records = draft['records'] as Map<String, dynamic>;
    final encodedKey = workoutRecordKey(key);
    if (jsonEncode(records[encodedKey]) == jsonEncode(state)) return;
    records[encodedKey] = state;
    _stageExercise(draft, encodedKey, state);
    unawaited(_persist());
    _kick();
  }

  void start(String day, DateTime date) {
    final draft = active;
    if (draft == null || draft['day'] != day || draft['status'] != 'active') {
      return;
    }
    final old = DateTime.tryParse(draft['startedAt'] as String? ?? '');
    if (old != null && !date.isBefore(old)) return;
    draft['startedAt'] = date.toIso8601String();
    unawaited(_persist());
  }

  Future<void> swap(String original, Map<String, dynamic> exercise) async {
    final draft = active;
    if (draft == null) return;
    (draft['swaps'] as Map)[original.trim().toLowerCase()] = exercise;
    final plan = draft['plan'] as List;
    final originals = draft['originalPlan'] as List? ?? plan;
    final index = originals.indexWhere(
      (e) =>
          (e['nome'] as String).trim().toLowerCase() ==
          original.trim().toLowerCase(),
    );
    if (index >= 0) plan[index] = exercise;
    await _persist();
  }

  bool ignoresNative(String name) =>
      (active?['nativeResets'] as List? ?? []).contains(name);
  Future<void> ignoreNative(String name) async {
    final draft = active;
    if (draft == null) return;
    final names = draft.putIfAbsent('nativeResets', () => <String>[]) as List;
    if (!names.contains(name)) names.add(name);
    await _persist();
  }

  Future<void> allowNative(String name) async {
    (active?['nativeResets'] as List?)?.remove(name);
    await _persist();
  }

  void mergeNative(Map<String, dynamic> native) {
    final draft = active;
    if (draft == null ||
        draft['day'] != native['day'] ||
        draft['status'] != 'active') {
      return;
    }
    final list = native['exercises'] as List;
    for (var i = 0; i < list.length; i++) {
      final e = list[i] as Map;
      if (ignoresNative(e['name'] as String)) continue;
      final key = (
        e['name'] as String,
        (e['restSeconds'] as num).toInt(),
        (e['sets'] as num).toInt(),
      );
      final previous = record(key);
      final count = (native['completed'][i] as num).toInt();
      final weight =
          previous?['weight'] as String? ??
          native['weights']?[key.$1] as String? ??
          '';
      final complete =
          count >= key.$3 &&
          (i < (native['index'] as num) ||
              (i == native['index'] && native['phase'] == 'done'));
      capture(key, {
        ...?previous,
        'completedSets': count,
        'weight': weight,
        'observation': previous?['observation'] ?? '',
        'finished':
            weight.trim().isNotEmpty &&
            (previous?['finished'] == true || complete),
        'remaining': 0,
        'running': false,
        'elapsed': previous?['elapsed'] ?? 0,
      });
    }
    if (native['startedAt'] is num) {
      start(
        native['day'] as String,
        DateTime.fromMillisecondsSinceEpoch(
          (native['startedAt'] as num).toInt(),
        ),
      );
    }
  }

  void _enqueue(
    Map<String, dynamic> draft,
    String action,
    Map<String, dynamic> body,
  ) {
    _data.putIfAbsent('outbox', () => <String, dynamic>{});
    _outbox[_uuid()] = jsonDecode(
      jsonEncode({
        ...body,
        'sessionId': draft['id'],
        'ownerId': owner,
        '_action': action,
      }),
    );
  }

  void _stageExercise(
    Map<String, dynamic> draft,
    String key,
    Map<String, dynamic> state,
  ) {
    final keys = jsonDecode(key) as List;
    final name = keys[0] as String;
    final plan = draft['plan'] as List;
    final index = plan.indexWhere((e) => e['nome'] == name);
    if (index < 0) return;
    final originals = draft['originalPlan'] as List? ?? plan;
    final slot = index.toString();
    final logs = draft.putIfAbsent('logs', () => <String, dynamic>{}) as Map;
    final intended =
        draft.putIfAbsent('intended', () => <String, dynamic>{}) as Map;
    final complete =
        state['finished'] == true &&
        (state['weight'] as String? ?? '').trim().isNotEmpty;
    if (!complete) {
      if (intended[slot] != null) {
        _enqueue(draft, 'removeExercise', {'logId': logs[slot]});
        intended.remove(slot);
      }
      return;
    }
    logs.putIfAbsent(slot, _uuid);
    final body = {
      'logId': logs[slot],
      'name': name,
      'originalName': originals[index]['nome'],
      'weight': state['weight'],
      'observation': state['observation'] ?? '',
    };
    final signature = jsonEncode(body);
    if (intended[slot] == signature) return;
    intended[slot] = signature;
    _enqueue(draft, 'exercise', body);
  }

  void _kick() {
    final sender = send;
    if (sender == null) return;
    unawaited(
      sync(sender).catchError((Object error) {
        debugPrint('Workout stage pending: $error');
      }),
    );
  }

  /// Terminal cancellation remains queued, including any unacknowledged start.
  Future<void> cancel() async {
    final draft = active ?? _drafts[_cancelRetryId] as Map<String, dynamic>?;
    if (draft == null) return;
    _cancelRetryId = draft['id'] as String;
    if (draft['status'] != 'cancelled') {
      // No need to upload exercises that the following DELETE will remove.
      // Keep an unacknowledged start to order requests after timeouts.
      _outbox.removeWhere(
        (key, value) =>
            value['sessionId'] == draft['id'] &&
            value['_action'] != 'start' &&
            key != _inFlight,
      );
      _enqueue(draft, 'cancel', {});
      draft['status'] = 'cancelled';
      _data['activeId'] = null;
    }
    // A repeated tap after a disk failure must still durably write the intent.
    await _persist();
    _cancelRetryId = null;
    _kick();
  }

  Future<void> stage(String id, Map<String, dynamic> payload) async {
    await bind();
    if (owner == null) throw StateError('Not authenticated');
    if ((_data['receipts'] as Map?)?.containsKey(id) == true) return;
    final draft = _drafts[id] as Map<String, dynamic>?;
    if (draft == null) throw StateError('Workout session not found');
    if (draft['status'] == 'pending') {
      await _persist();
      return;
    }
    final frozen =
        jsonDecode(jsonEncode({...payload, 'sessionId': id, 'ownerId': owner}))
            as Map<String, dynamic>;
    // The full summary is local recovery data; the server already has its logs.
    _enqueue(draft, 'finish', {
      'endedAt': frozen['endedAt'],
      'mood': frozen['mood'],
      'feedback': frozen['feedback'],
    });
    draft['status'] = 'pending';
    if (activeId == id) _data['activeId'] = null;
    _data['lastCompletion'] = frozen;
    await _persist();
  }

  Future<void> sync(Future<void> Function(Map<String, dynamic>) send) =>
      _sending ??= _sync(send).whenComplete(() => _sending = null);
  Future<void> _sync(Future<void> Function(Map<String, dynamic>) send) async {
    await bind();
    final account = owner;
    if (account == null) return;
    final blocked = <String>{};
    Object? firstError;
    while (true) {
      // Every operation must reach durable storage before it reaches the network.
      await flush();
      if (owner != account || workoutCacheOwner(await readToken()) != account) {
        return;
      }
      final entry = _outbox.entries
          .where(
            (e) => !blocked.contains((e.value['sessionId'] ?? e.key) as String),
          )
          .firstOrNull;
      if (entry == null) break;
      final operation = entry.key;
      final payload = Map<String, dynamic>.from(entry.value as Map);
      final id = (payload['sessionId'] ?? operation) as String;
      try {
        _inFlight = operation;
        try {
          await send(payload);
        } finally {
          _inFlight = null;
        }
        if (owner != account) return;
        final terminal =
            payload['_action'] == null ||
            payload['_action'] == 'finish' ||
            payload['_action'] == 'cancel';
        final draft = _drafts[id];
        _outbox.remove(operation);
        if (terminal) _drafts.remove(id);
        _data.putIfAbsent('receipts', () => <String, dynamic>{});
        final receipts = _data['receipts'] as Map<String, dynamic>;
        if (terminal) receipts[id] = payload['endedAt'] ?? 'cancelled';
        while (receipts.length > 100) {
          receipts.remove(receipts.keys.first);
        }
        try {
          await _persist();
        } catch (_) {
          // Preserve FIFO in memory too if writing the acknowledgment fails.
          _data['outbox'] = <String, dynamic>{operation: payload, ..._outbox};
          if (draft != null) _drafts[id] = draft;
          receipts.remove(id);
          rethrow;
        }
      } catch (error) {
        if (owner == account &&
            _drafts[id]?['status'] == 'cancelled' &&
            payload['_action'] != 'start' &&
            payload['_action'] != 'cancel') {
          // A failed exercise write cannot hold a full-session cancellation hostage.
          // Such a write cannot recreate the parent after its cascading DELETE.
          _outbox.remove(operation);
          await _persist();
          continue;
        }
        blocked.add(id); // Never finish/delete before earlier writes succeed.
        firstError ??= error;
      }
    }
    if (firstError != null) throw firstError;
  }
}

final workoutSessionCacheProvider = Provider<WorkoutSessionCache>(
  (ref) => WorkoutSessionCache(
    SecureWorkoutCacheStore(),
    () => ref.read(tokenStorageProvider).read(),
    send: (payload) => ref.read(appApiProvider).syncCachedWorkout(payload),
  ),
);
