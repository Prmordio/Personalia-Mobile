import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/app_update/app_update_controller.dart';
import 'package:personalia_app/core/app_update/update_gate.dart';
import 'package:personalia_app/core/app_update/version_policy.dart';
import 'package:personalia_app/features/workout/state/review_prompt.dart';
import 'package:personalia_app/l10n/app_localizations.dart';

AppVersion v(String s) => AppVersion.tryParse(s)!;

class _MemoryDismissed implements DismissedUpdateStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String version) async => value = version;
}

class _MemoryReviewStore implements ReviewPromptStore {
  int count = 0;
  DateTime? last;
  @override
  Future<int> completedWorkouts() async => count;
  @override
  Future<void> setCompletedWorkouts(int value) async => count = value;
  @override
  Future<DateTime?> lastPromptAt() async => last;
  @override
  Future<void> setLastPromptAt(DateTime value) async => last = value;
}

class _FakeLauncher implements StoreReviewLauncher {
  _FakeLauncher({this.available = true});
  final bool available;
  int requests = 0;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<void> requestReview() async => requests++;
}

void main() {
  group('AppVersion', () {
    test('parses versions with build numbers and short forms', () {
      expect(v('3.4.2+42'), const AppVersion(3, 4, 2));
      expect(v('3.5'), const AppVersion(3, 5, 0));
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse('banana'), isNull);
    });
    test('compares numerically, not lexically', () {
      expect(v('3.10.0') < v('3.9.9'), isFalse);
      expect(v('3.4.2') < v('3.4.10'), isTrue);
    });
  });

  group('evaluateUpdate', () {
    test('below minimum is required', () {
      expect(evaluateUpdate(current: v('3.4.2'), minimum: v('3.5.0')), UpdateRequirement.required);
    });
    test('below recommended only is recommended', () {
      expect(
        evaluateUpdate(current: v('3.4.2'), minimum: v('3.0.0'), recommended: v('3.5.0')),
        UpdateRequirement.recommended,
      );
    });
    test('missing config or unknown version never blocks', () {
      expect(evaluateUpdate(current: v('3.4.2')), UpdateRequirement.none);
      expect(evaluateUpdate(current: null, minimum: v('9.0.0')), UpdateRequirement.none);
      expect(evaluateUpdate(current: v('3.5.0'), minimum: v('3.5.0')), UpdateRequirement.none);
    });
  });

  group('UpdateGate', () {
    Future<_MemoryDismissed> pump(WidgetTester tester, UpdateStatus status, {String? dismissed}) async {
      final store = _MemoryDismissed()..value = dismissed;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            updateStatusProvider.overrideWith((ref) async => status),
            dismissedUpdateStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => UpdateGate(child: child!),
            home: const Scaffold(body: Text('app body')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return store;
    }

    testWidgets('blocks the app below the minimum version', (tester) async {
      await pump(tester, UpdateStatus(requirement: UpdateRequirement.required, target: v('3.5.0')));
      expect(find.byType(ForceUpdateScreen), findsOneWidget);
      expect(find.text('app body'), findsNothing);
    });

    testWidgets('suggests once and remembers the dismissal per version', (tester) async {
      final store = await pump(tester, UpdateStatus(requirement: UpdateRequirement.recommended, target: v('3.5.0')));
      expect(find.text('app body'), findsOneWidget);
      expect(find.text('New version available'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.text('New version available'), findsNothing);
      expect(store.value, '3.5.0');
    });

    testWidgets('does not suggest a version already dismissed', (tester) async {
      await pump(
        tester,
        UpdateStatus(requirement: UpdateRequirement.recommended, target: v('3.5.0')),
        dismissed: '3.5.0',
      );
      expect(find.text('New version available'), findsNothing);
    });
  });

  group('ReviewPromptPolicy', () {
    const policy = ReviewPromptPolicy();
    final now = DateTime(2026, 11, 18);
    test('waits for the habit to form', () {
      expect(policy.shouldPrompt(completedWorkouts: 2, lastPromptAt: null, now: now, mood: '🔥'), isFalse);
      expect(policy.shouldPrompt(completedWorkouts: 3, lastPromptAt: null, now: now, mood: '🔥'), isTrue);
    });
    test('skips bad moods', () {
      expect(policy.shouldPrompt(completedWorkouts: 10, lastPromptAt: null, now: now, mood: '😤'), isFalse);
    });
    test('respects the cooldown', () {
      final recent = now.subtract(const Duration(days: 30));
      final old = now.subtract(const Duration(days: 121));
      expect(policy.shouldPrompt(completedWorkouts: 10, lastPromptAt: recent, now: now, mood: '🔥'), isFalse);
      expect(policy.shouldPrompt(completedWorkouts: 10, lastPromptAt: old, now: now, mood: '🔥'), isTrue);
    });
  });

  group('ReviewPromptService', () {
    test('counts workouts and prompts on the third good one, once', () async {
      final store = _MemoryReviewStore();
      final launcher = _FakeLauncher();
      final service = ReviewPromptService(store: store, launcher: launcher, clock: () => DateTime(2026, 11, 18));
      expect(await service.onWorkoutCompleted(mood: '🔥'), isFalse);
      expect(await service.onWorkoutCompleted(mood: '🔥'), isFalse);
      expect(await service.onWorkoutCompleted(mood: '🔥'), isTrue);
      expect(await service.onWorkoutCompleted(mood: '🔥'), isFalse, reason: 'cooldown');
      expect(launcher.requests, 1);
      expect(store.count, 4);
    });

    test('does not record a prompt when the store review is unavailable', () async {
      final store = _MemoryReviewStore()..count = 5;
      final service = ReviewPromptService(store: store, launcher: _FakeLauncher(available: false));
      expect(await service.onWorkoutCompleted(mood: '🔥'), isFalse);
      expect(store.last, isNull);
    });
  });
}
