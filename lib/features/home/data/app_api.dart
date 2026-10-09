import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

class WorkoutExercise {
  WorkoutExercise({
    required this.nome,
    required this.series,
    required this.repeticoes,
    this.modeloDeTreino,
    this.descanso,
  });
  final String nome;
  final String? series;
  final String? repeticoes;
  final String? modeloDeTreino;
  final String? descanso;

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) => WorkoutExercise(
        nome: json['nome'] ?? json['name'] ?? '',
        series: json['series']?.toString(),
        repeticoes: json['repeticoes']?.toString(),
        modeloDeTreino: json['modeloDeTreino'],
        // GET /users/:id/training devolve `intervaloDescanso` ("90seg"); o treino de hoje, `descanso`.
        descanso: (json['descanso'] ?? json['intervaloDescanso'])?.toString(),
      );
}

class WorkoutDay {
  WorkoutDay({required this.dayName, required this.exercises});
  final String dayName;
  final List<WorkoutExercise> exercises;

  factory WorkoutDay.fromJson(Map<String, dynamic> json) => WorkoutDay(
        dayName: json['dayName'] ?? '',
        exercises: (json['exercises'] as List? ?? []).map((e) => WorkoutExercise.fromJson(e)).toList(),
      );
}

class CurrentWorkout {
  CurrentWorkout({required this.name, required this.days});
  final String name;
  final List<WorkoutDay> days;
}

class LastWorkoutExercise {
  LastWorkoutExercise({required this.name, this.weight, this.observation});
  final String name;
  final String? weight;
  final String? observation;
}

class LastWorkout {
  LastWorkout({required this.date, this.startedAt, required this.dayName, required this.exercises, this.isToday = false});
  final DateTime? date;
  final DateTime? startedAt;
  final String dayName;
  final List<LastWorkoutExercise> exercises;
  final bool isToday;

  Duration? get duration {
    if (date == null || startedAt == null) return null;
    return date!.difference(startedAt!);
  }
}

class WorkoutHistoryEntry {
  WorkoutHistoryEntry({
    required this.id,
    required this.dayName,
    this.date,
    this.startedAt,
    this.isToday = false,
    this.durationMinutes,
    required this.exercises,
  });
  final String id;
  final String dayName;
  final DateTime? date;
  final DateTime? startedAt;
  final bool isToday;
  final int? durationMinutes;
  final List<LastWorkoutExercise> exercises;

  factory WorkoutHistoryEntry.fromJson(Map<String, dynamic> data) => WorkoutHistoryEntry(
        id: data['id'] ?? '',
        dayName: data['dayName'] ?? '',
        date: data['date'] != null ? DateTime.tryParse(data['date']) : null,
        startedAt: data['startedAt'] != null ? DateTime.tryParse(data['startedAt']) : null,
        isToday: data['isToday'] == true,
        durationMinutes: data['durationMinutes'] as int?,
        exercises: (data['exercises'] as List? ?? [])
            .map((e) => LastWorkoutExercise(name: e['name'] ?? '', weight: e['weight']?.toString(), observation: e['observation']))
            .toList(),
      );
}

class DailyTip {
  DailyTip({required this.categoria, required this.texto});
  final String? categoria;
  final String? texto;
}

class ReferralInfo {
  ReferralInfo({required this.eligible, this.code, this.inviteLink});
  final bool eligible;
  final String? code;
  final String? inviteLink;
}

class TodayWorkout {
  TodayWorkout({required this.isRest, required this.dayName, required this.focusLabel, required this.exercises});
  final bool isRest;
  final String dayName;
  final String focusLabel;
  final List<WorkoutExercise> exercises;

  factory TodayWorkout.fromJson(Map<String, dynamic> json) => TodayWorkout(
        isRest: json['isRest'] ?? false,
        dayName: json['dayName'] ?? '',
        focusLabel: json['focusLabel'] ?? '',
        exercises: (json['exercises'] as List? ?? []).map((e) => WorkoutExercise.fromJson(e)).toList(),
      );
}

class ProgressInfo {
  ProgressInfo({this.currentWeight, this.currentHeight, this.weightLostPercent});
  final num? currentWeight;
  final num? currentHeight;
  final num? weightLostPercent;
}

class SubscriptionInfo {
  SubscriptionInfo({required this.isValid, this.status, this.dueDate, required this.isFreeTrial});
  final bool isValid;
  final String? status;
  final DateTime? dueDate;
  final bool isFreeTrial;

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) => SubscriptionInfo(
        isValid: json['isValid'] ?? false,
        status: json['status'],
        dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
        isFreeTrial: json['isFreeTrial'] ?? false,
      );
}

class ExerciseVideo {
  ExerciseVideo({this.title, this.url, this.thumbnail, this.duration, this.views});
  final String? title;
  final String? url;
  final String? thumbnail;
  final String? duration;
  final String? views;

  factory ExerciseVideo.fromJson(Map<String, dynamic> json) => ExerciseVideo(
        title: json['title'],
        url: json['url'],
        thumbnail: json['thumbnail'],
        duration: json['duration'],
        views: json['views'],
      );
}

class ExerciseAlternative {
  ExerciseAlternative({required this.nome, this.series, this.repeticoes});
  final String nome;
  final String? series;
  final String? repeticoes;

  factory ExerciseAlternative.fromJson(Map<String, dynamic> json) => ExerciseAlternative(
        nome: json['nome'] ?? json['name'] ?? '',
        series: json['series']?.toString(),
        repeticoes: json['repeticoes']?.toString(),
      );
}

class AppApi {
  AppApi(this._dio);
  final Dio _dio;

  Future<CurrentWorkout?> getCurrentWorkout() async {
    final response = await _dio.get('/app/workout/current');
    final data = response.data;
    if (data == null || data['lastWorkout'] == null) return null;
    final workout = data['lastWorkout'];
    return CurrentWorkout(
      name: workout['name'] ?? 'Treino',
      days: (workout['days'] as List? ?? []).map((d) => WorkoutDay.fromJson(d)).toList(),
    );
  }

  Future<LastWorkout?> getLastWorkout() async {
    final response = await _dio.get('/app/workout/last');
    final data = response.data;
    if (data == null) return null;
    return LastWorkout(
      date: data['date'] != null ? DateTime.tryParse(data['date']) : null,
      startedAt: data['startedAt'] != null ? DateTime.tryParse(data['startedAt']) : null,
      isToday: data['isToday'] == true,
      dayName: data['dayName'] ?? '',
      exercises: (data['exercises'] as List? ?? [])
          .map((e) => LastWorkoutExercise(name: e['name'] ?? '', weight: e['weight']?.toString(), observation: e['observation']))
          .toList(),
    );
  }

  Future<void> logWorkout({
    required String dayName,
    required DateTime startedAt,
    required DateTime endedAt,
    String? mood,
    required List<Map<String, dynamic>> exercises,
  }) async {
    await _dio.post('/app/workout/log', data: {
      'dayName': dayName,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'mood': mood,
      'exercises': exercises,
    });
  }

  /// false quando o backend recusa por falta de assinatura (`reason: subscription_required`) —
  /// nesse caso nada é gerado e o app deve oferecer o "Assinar".
  Future<bool> generateWorkout() async {
    final response = await _dio.post('/app/workout/generate');
    return response.data?['started'] != false;
  }

  /// 'idle' | 'running' | 'failed' — 'failed' quando a última geração terminou sem treino.
  Future<String> getGenerationStatus() async {
    final response = await _dio.get('/app/workout/generation');
    return (response.data?['status'] as String?) ?? 'idle';
  }

  /// Link do Mercado Pago para assinar; null se a assinatura já está ativa.
  Future<String?> getCheckoutUrl() async {
    final response = await _dio.post('/app/subscription/checkout');
    return response.data['paymentUrl'] as String?;
  }

  Future<DailyTip> getTodayTip() async {
    final response = await _dio.get('/app/tips/today');
    return DailyTip(categoria: response.data['categoria'], texto: response.data['texto']);
  }

  Future<ReferralInfo> getReferral() async {
    final response = await _dio.get('/app/referral');
    return ReferralInfo(
      eligible: response.data['eligible'] ?? false,
      code: response.data['code'],
      inviteLink: response.data['inviteLink'],
    );
  }

  Future<TodayWorkout> getTodayWorkout() async {
    final response = await _dio.get('/app/workout/today');
    return TodayWorkout.fromJson(response.data);
  }

  Future<ProgressInfo> getProgress() async {
    final response = await _dio.get('/app/progress');
    return ProgressInfo(
      currentWeight: response.data['currentWeight'],
      currentHeight: response.data['currentHeight'],
      weightLostPercent: response.data['weightLostPercent'],
    );
  }

  Future<List<WorkoutHistoryEntry>> getWorkoutHistory() async {
    final response = await _dio.get('/app/workout/history');
    return (response.data as List? ?? []).map((e) => WorkoutHistoryEntry.fromJson(e)).toList();
  }

  Future<void> updateProgress({double? weight, double? height}) async {
    await _dio.put('/app/progress', data: {
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
    });
  }

  Future<SubscriptionInfo> getSubscription() async {
    final response = await _dio.get('/app/subscription');
    return SubscriptionInfo.fromJson(response.data);
  }

  Future<List<ExerciseVideo>> getExerciseVideos(String name) async {
    final response = await _dio.get('/agent/exercise-video', queryParameters: {'name': name});
    return (response.data['videos'] as List? ?? []).map((v) => ExerciseVideo.fromJson(v)).toList();
  }

  Future<List<ExerciseAlternative>> getExerciseAlternatives({
    required String exerciseName,
    String series = '3',
    String reps = '12',
    bool isCardio = false,
  }) async {
    final response = await _dio.post('/app/workout/exercise/alternatives', data: {
      'exerciseName': exerciseName,
      'series': series,
      'reps': reps,
      'isCardio': isCardio,
    });
    return (response.data['alternatives'] as List? ?? [])
        .map((a) => ExerciseAlternative.fromJson(a))
        .toList();
  }

  Future<void> swapExercisePermanently({
    required String originalExerciseName,
    required String newName,
    String? newSeries,
    String? newReps,
  }) async {
    await _dio.post('/app/workout/exercise/swap/permanent', data: {
      'originalExerciseName': originalExerciseName,
      'newName': newName,
      if (newSeries != null) 'newSeries': newSeries,
      if (newReps != null) 'newReps': newReps,
    });
  }

}

final appApiProvider = Provider<AppApi>((ref) => AppApi(ref.watch(apiClientProvider).dio));

final currentWorkoutProvider = FutureProvider.autoDispose<CurrentWorkout?>((ref) {
  return ref.watch(appApiProvider).getCurrentWorkout();
});

final lastWorkoutProvider = FutureProvider.autoDispose<LastWorkout?>((ref) {
  return ref.watch(appApiProvider).getLastWorkout();
});

final todayTipProvider = FutureProvider.autoDispose<DailyTip>((ref) {
  return ref.watch(appApiProvider).getTodayTip();
});

final referralProvider = FutureProvider.autoDispose<ReferralInfo>((ref) {
  return ref.watch(appApiProvider).getReferral();
});

final todayWorkoutProvider = FutureProvider.autoDispose<TodayWorkout>((ref) {
  return ref.watch(appApiProvider).getTodayWorkout();
});

final progressProvider = FutureProvider.autoDispose<ProgressInfo>((ref) {
  return ref.watch(appApiProvider).getProgress();
});

final exerciseVideosProvider = FutureProvider.autoDispose.family<List<ExerciseVideo>, String>((ref, name) {
  return ref.watch(appApiProvider).getExerciseVideos(name);
});

final subscriptionProvider = FutureProvider.autoDispose<SubscriptionInfo>((ref) {
  return ref.watch(appApiProvider).getSubscription();
});

final workoutHistoryProvider = FutureProvider.autoDispose<List<WorkoutHistoryEntry>>((ref) {
  return ref.watch(appApiProvider).getWorkoutHistory();
});
