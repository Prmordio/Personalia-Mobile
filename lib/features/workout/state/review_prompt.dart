import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_review/in_app_review.dart';

/// Quando pedir avaliação na loja: só depois de criar o hábito (algumas sessões concluídas),
/// num momento bom (treino terminado sem humor negativo) e no máximo a cada [cooldown].
/// As lojas ainda limitam por conta própria quantas vezes a janela aparece.
class ReviewPromptPolicy {
  const ReviewPromptPolicy({this.minCompletedWorkouts = 3, this.cooldown = const Duration(days: 120)});

  final int minCompletedWorkouts;
  final Duration cooldown;

  /// Humores do fim do treino que indicam experiência ruim (ex.: 😤 exausto).
  static const negativeMoods = {'😤', '😑'};

  bool shouldPrompt({
    required int completedWorkouts,
    required DateTime? lastPromptAt,
    required DateTime now,
    required String mood,
  }) {
    if (completedWorkouts < minCompletedWorkouts) return false;
    if (negativeMoods.contains(mood.trim())) return false;
    return lastPromptAt == null || now.difference(lastPromptAt) >= cooldown;
  }
}

abstract interface class ReviewPromptStore {
  Future<int> completedWorkouts();
  Future<void> setCompletedWorkouts(int value);
  Future<DateTime?> lastPromptAt();
  Future<void> setLastPromptAt(DateTime value);
}

class SecureReviewPromptStore implements ReviewPromptStore {
  static const _storage = FlutterSecureStorage();
  static const _countKey = 'review_completed_workouts';
  static const _lastKey = 'review_last_prompt_at';

  @override
  Future<int> completedWorkouts() async => int.tryParse(await _storage.read(key: _countKey) ?? '') ?? 0;

  @override
  Future<void> setCompletedWorkouts(int value) => _storage.write(key: _countKey, value: '$value');

  @override
  Future<DateTime?> lastPromptAt() async => DateTime.tryParse(await _storage.read(key: _lastKey) ?? '');

  @override
  Future<void> setLastPromptAt(DateTime value) => _storage.write(key: _lastKey, value: value.toIso8601String());
}

/// Abertura da janela nativa de avaliação (abstração para testes).
abstract interface class StoreReviewLauncher {
  Future<bool> isAvailable();
  Future<void> requestReview();
}

class InAppReviewLauncher implements StoreReviewLauncher {
  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}

/// Chamado ao concluir um treino: conta a sessão e, se a política permitir, abre a janela
/// nativa de avaliação. Nunca lança — avaliação é opcional.
class ReviewPromptService {
  ReviewPromptService({
    required this._store,
    required this._launcher,
    this.policy = const ReviewPromptPolicy(),
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now;

  final ReviewPromptStore _store;
  final StoreReviewLauncher _launcher;
  final ReviewPromptPolicy policy;
  final DateTime Function() _clock;

  /// `true` quando a janela foi solicitada.
  Future<bool> onWorkoutCompleted({required String mood}) async {
    try {
      final count = await _store.completedWorkouts() + 1;
      await _store.setCompletedWorkouts(count);
      final now = _clock();
      final allowed = policy.shouldPrompt(
        completedWorkouts: count,
        lastPromptAt: await _store.lastPromptAt(),
        now: now,
        mood: mood,
      );
      if (!allowed || !await _launcher.isAvailable()) return false;
      await _store.setLastPromptAt(now);
      await _launcher.requestReview();
      return true;
    } catch (error) {
      debugPrint('[Review] skipped: ${error.runtimeType}');
      return false;
    }
  }
}

final reviewPromptServiceProvider = Provider<ReviewPromptService>(
  (ref) => ReviewPromptService(store: SecureReviewPromptStore(), launcher: InAppReviewLauncher()),
);
