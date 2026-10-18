import 'active_workout_session.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The native copy also accepts actions while Flutter is suspended. Timestamps,
/// rather than periodic background work, drive both platforms' visible clocks.
class WorkoutLiveState {
  WorkoutLiveState(this.data);
  final Map<String, dynamic> data;
  List<dynamic> get exercises => data['exercises'] as List<dynamic>;
  int get index => (data['index'] as num).toInt();
  Map<String, dynamic> get exercise =>
      Map<String, dynamic>.from(exercises[index] as Map);
  String get name => exercise['name'] as String;
  String get phase => data['phase'] as String;
  bool get running => data['running'] == true;
  int get completed => (data['completed'][index] as num).toInt();
  int get totalSets => (exercise['sets'] as num).toInt();
  int get currentSet =>
      (phase == 'rest' || data['pendingRestCounted'] == true
              ? completed
              : completed + 1)
          .clamp(1, totalSets);
  bool get hasWeight =>
      (data['weights']?[name] as String? ?? '').trim().isNotEmpty;
  bool get hasNext => index + 1 < exercises.length;
  DateTime? get startedAt {
    final stored = data['startedAt'];
    if (stored is num) {
      return DateTime.fromMillisecondsSinceEpoch(stored.toInt());
    }
    // Older snapshots only have the most recent timer anchor.
    final anchor = (data['anchor'] as num?)?.toInt() ?? 0;
    return anchor > 0 &&
            (phase != 'ready' ||
                (data['completed'] as List).any((c) => (c as num) > 0))
        ? DateTime.fromMillisecondsSinceEpoch(anchor)
        : null;
  }

  ActiveWorkoutSession? restoreSession(
    ActiveWorkoutSession? current, {
    DateTime? now,
  }) {
    final start = startedAt;
    final day = data['day'] as String;
    if (start == null ||
        (current != null &&
            current.dayName == day &&
            !start.isBefore(current.startedAt))) {
      return current;
    }
    return ActiveWorkoutSession(dayName: day, startedAt: start);
  }

  /// A completed final rest (or moving on) also finalizes the list entry.
  bool exerciseFinished(int exerciseIndex) {
    final item = exercises[exerciseIndex] as Map;
    final count = (data['completed'][exerciseIndex] as num).toInt();
    return (data['weights']?[item['name']] as String? ?? '')
            .trim()
            .isNotEmpty &&
        count >= (item['sets'] as num).toInt() &&
        (exerciseIndex < index || (exerciseIndex == index && phase == 'done'));
  }

  int get seconds {
    final stored = (data['seconds'] as num).toInt();
    if (!running || phase != 'rest') return stored;
    final elapsed =
        ((DateTime.now().millisecondsSinceEpoch - (data['anchor'] as num)) /
                1000)
            .floor();
    return (stored - elapsed).clamp(0, 86400);
  }

  WorkoutLiveState restOnly() {
    if (data['flowVersion'] == 2) return this;
    final legacyExecution = phase == 'exercise' || phase == 'awaitRest';
    return WorkoutLiveState({
      ...data,
      'flowVersion': 2,
      if (phase == 'awaitRest') 'pendingRestCounted': true,
      if (legacyExecution) ...{
        'phase': 'ready',
        'running': false,
        'seconds': 0,
      },
      'revision': (data['revision'] as num).toInt() + 1,
    });
  }

  WorkoutLiveState resolveAt(int now) {
    final migrated = restOnly();
    if (!identical(migrated, this)) return migrated.resolveAt(now);
    if (phase != 'rest' ||
        !running ||
        now < (data['anchor'] as num) + (data['seconds'] as num) * 1000) {
      return this;
    }
    return WorkoutLiveState({
      ...data,
      'phase': completed >= totalSets ? 'done' : 'ready',
      'running': false,
      'seconds': 0,
      'revision': (data['revision'] as num).toInt() + 1,
    });
  }

  /// Pressing rest records the series just performed and starts ONLY a countdown.
  WorkoutLiveState act(String action, {int? now}) {
    final time = now ?? DateTime.now().millisecondsSinceEpoch;
    final resolved = resolveAt(time);
    if (!identical(resolved, this)) return resolved.act(action, now: time);
    final d = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    final value = running && phase == 'rest'
        ? ((d['seconds'] as num).toInt() -
                  ((time - (d['anchor'] as num)) / 1000).floor())
              .clamp(0, 86400)
        : (d['seconds'] as num).toInt();
    d['seconds'] = value;
    d['anchor'] = time;
    if (action == 'rest' && phase == 'ready' && completed < totalSets) {
      if (d.remove('pendingRestCounted') != true) {
        d['completed'][index] = completed + 1;
      }
      d['startedAt'] ??= time;
      d['phase'] = 'rest';
      d['running'] = true;
      d['seconds'] = exercise['restSeconds'];
    } else if (action == 'toggle' && phase == 'rest') {
      d['running'] = !running;
    } else if (action == 'add' && phase == 'rest') {
      d['seconds'] = value + 30;
    } else if (action == 'skip' && phase == 'rest') {
      d['phase'] = completed >= totalSets ? 'done' : 'ready';
      d['running'] = false;
      d['seconds'] = 0;
    } else if (action == 'next' && phase == 'done' && hasNext && hasWeight) {
      d['index'] = index + 1;
      d['phase'] = 'ready';
      d['running'] = false;
      d['seconds'] = 0;
    } else {
      return this;
    }
    d['revision'] = (d['revision'] as num).toInt() + 1;
    return WorkoutLiveState(d).resolveAt(time);
  }
}

class WorkoutLiveController extends StateNotifier<WorkoutLiveState?>
    with WidgetsBindingObserver {
  WorkoutLiveController() : super(null) {
    WidgetsBinding.instance.addObserver(this);
    unawaited(refresh());
    _poll = Timer.periodic(const Duration(seconds: 1), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(refresh());
      }
    });
  }
  static const channel = MethodChannel('personalia/workout_live');
  Timer? _poll;
  Future<void> _pending = Future.value();
  bool _disposed = false;

  Future<void> _enqueue(Future<void> Function() task) {
    _pending = _pending.then((_) => task()).catchError((Object error) {
      debugPrint('Workout lock screen: $error');
    });
    return _pending;
  }

  Future<WorkoutLiveState?> _invoke(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    try {
      final json = await channel.invokeMethod<String>(method, arguments);
      return json == null
          ? null
          : WorkoutLiveState(jsonDecode(json) as Map<String, dynamic>);
    } on MissingPluginException {
      return state;
    }
  }

  void _accept(WorkoutLiveState? next) {
    if (_disposed) return;
    if (next != null && next.data['date'] != _today) {
      unawaited(end());
      return;
    }
    state = next?.resolveAt(DateTime.now().millisecondsSinceEpoch);
  }

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> refresh() =>
      _enqueue(() async => _accept(await _invoke('read')));

  Future<void> enableExactAlarm() async {
    try {
      await channel.invokeMethod<void>('requestExactAlarm');
    } on PlatformException catch (error) {
      debugPrint('Workout exact alarm: $error');
    } on MissingPluginException {
      // Other platforms use their own timer scheduling.
    }
  }

  Future<void> localize(Map<String, String> labels) => _enqueue(() async {
    final current = state ?? await _invoke('read');
    if (current == null || mapEquals(current.data['labels'] as Map?, labels)) {
      return;
    }
    final updated = await _invoke('localize', {'json': jsonEncode(labels)});
    _accept(updated ?? WorkoutLiveState({...current.data, 'labels': labels}));
  });

  Future<void> recordWeight(String name, String value) => _enqueue(() async {
    final current = state;
    if (current == null || !current.exercises.any((e) => e['name'] == name)) {
      return;
    }
    final updated = await _invoke('weight', {
      'id': current.data['id'],
      'name': name,
      'value': value,
    });
    _accept(
      updated == null || identical(updated, current)
          ? WorkoutLiveState({
              ...current.data,
              'weights': {...?current.data['weights'] as Map?, name: value},
            })
          : updated,
    );
  });

  Future<void> prepare({
    required String day,
    required List<Map<String, dynamic>> exercises,
    List<int>? completed,
    Map<String, String>? labels,
    bool recordOnly = false,
    DateTime? startedAt,
    Map<String, String>? weights,
  }) => _enqueue(() async {
    var existing = await _invoke('read');
    if (recordOnly ||
        (completed != null &&
            completed.isNotEmpty &&
            completed.first >= (exercises.first['sets'] as num))) {
      _accept(existing);
      return;
    }
    if (existing != null && weights != null) {
      for (final entry in weights.entries) {
        if (existing!.exercises.any((e) => e['name'] == entry.key) &&
            existing.data['weights']?[entry.key] != entry.value) {
          existing =
              await _invoke('weight', {
                'id': existing.data['id'],
                'name': entry.key,
                'value': entry.value,
              }) ??
              existing;
        }
      }
    }
    if (existing != null &&
        labels != null &&
        !mapEquals(existing.data['labels'] as Map?, labels)) {
      existing =
          await _invoke('localize', {'json': jsonEncode(labels)}) ??
          WorkoutLiveState({...existing.data, 'labels': labels});
    }
    if (existing != null &&
        existing.data['date'] == _today &&
        existing.data['day'] == day &&
        existing.name == exercises.first['name']) {
      _accept(existing);
      return;
    }
    if (existing != null &&
        existing.data['date'] == _today &&
        existing.data['day'] == day) {
      final selected = existing.exercises.indexWhere(
        (e) => e['name'] == exercises.first['name'],
      );
      if (selected >= 0 &&
          (existing.data['completed'][selected] as num) >=
              (existing.exercises[selected]['sets'] as num)) {
        _accept(existing);
        return;
      }
    }
    final initial = WorkoutLiveState({
      'flowVersion': 2,
      'labels': labels ?? <String, String>{},
      'weights': weights ?? <String, String>{},
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'date': _today,
      'day': day,
      'startedAt':
          (existing?.data['date'] == _today && existing?.data['day'] == day
                  ? existing?.startedAt ?? startedAt
                  : startedAt)
              ?.millisecondsSinceEpoch,
      'exercises': exercises,
      'index': 0,
      'completed': completed ?? List.filled(exercises.length, 0),
      'phase':
          completed != null &&
              completed.first >= (exercises.first['sets'] as int)
          ? 'done'
          : 'ready',
      'running': false,
      'seconds': 0,
      'anchor': 0,
      'revision': 0,
    });
    state = initial;
    _accept(
      await _invoke('prepare', {'json': jsonEncode(initial.data)}) ?? initial,
    );
  });

  Future<void> action(String action) => _enqueue(() async {
    final current = state;
    if (current == null) return;
    final next = await _invoke('action', {
      'action': action,
      'id': current.data['id'],
      'revision': current.data['revision'],
    });
    _accept(
      next == null || identical(next, current) ? current.act(action) : next,
    );
  });

  Future<void> resetCompleted(String name) => _enqueue(() async {
    final current = await _invoke('read') ?? state;
    if (current == null) return;
    final data = jsonDecode(jsonEncode(current.data)) as Map<String, dynamic>;
    final index = current.exercises.indexWhere((e) => e['name'] == name);
    if (index < 0) return;
    data['completed'][index] = 0;
    (data['weights'] as Map?)?.remove(name);
    data['revision'] = (data['revision'] as num).toInt() + 1;
    if (index == current.index) {
      data['phase'] = 'ready';
      data['running'] = false;
      data['seconds'] = 0;
      data.remove('pendingRestCounted');
    }
    final next = WorkoutLiveState(data);
    _accept(await _invoke('prepare', {'json': jsonEncode(data)}) ?? next);
  });

  Future<void> end() => _enqueue(() async {
    await _invoke('end');
    if (!_disposed) state = null;
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final workoutLiveProvider =
    StateNotifierProvider<WorkoutLiveController, WorkoutLiveState?>(
      (ref) => WorkoutLiveController(),
    );
