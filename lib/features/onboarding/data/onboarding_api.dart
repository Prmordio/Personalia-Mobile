import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

class OnboardingProfile {
  OnboardingProfile({this.name, this.gender, this.birthDate, this.weight, this.height, this.email, this.cpf, this.phone});
  final String? name;
  final String? gender;
  final String? birthDate;
  final num? weight;
  final num? height;
  final String? email;
  final String? cpf;

  /// Número do WhatsApp da conta (só leitura). Null fora do WhatsApp.
  final String? phone;

  factory OnboardingProfile.fromJson(Map<String, dynamic>? json) => OnboardingProfile(
        name: json?['name'],
        gender: json?['gender'],
        birthDate: json?['birthDate'],
        weight: json?['weight'],
        height: json?['height'],
        email: json?['email'],
        cpf: json?['cpf'],
        phone: json?['phone'],
      );
}

class OnboardingAnamnesis {
  OnboardingAnamnesis({
    this.mainGoal,
    this.hasDiseases,
    this.diseases,
    this.hasPhysicalLimitations,
    this.physicalLimitations,
    this.physicalActivityLevel,
  });
  final String? mainGoal;
  final bool? hasDiseases;
  final String? diseases;
  final bool? hasPhysicalLimitations;
  final String? physicalLimitations;
  final String? physicalActivityLevel;

  factory OnboardingAnamnesis.fromJson(Map<String, dynamic>? json) => OnboardingAnamnesis(
        mainGoal: json?['mainGoal'],
        hasDiseases: json?['hasDiseases'],
        diseases: json?['diseases'],
        hasPhysicalLimitations: json?['hasPhysicalLimitations'],
        physicalLimitations: json?['physicalLimitations'],
        physicalActivityLevel: json?['physicalActivityLevel'],
      );
}

class OnboardingTrainingPreferences {
  OnboardingTrainingPreferences({
    this.minTrainingDuration,
    this.maxTrainingDuration,
    this.trainingDaysPerWeek,
    this.wantsCardio,
    this.trainingFocus,
    this.preferredGymTime,
  });
  final int? minTrainingDuration;
  final int? maxTrainingDuration;
  final int? trainingDaysPerWeek;
  final bool? wantsCardio;
  final String? trainingFocus;
  final String? preferredGymTime;

  factory OnboardingTrainingPreferences.fromJson(Map<String, dynamic>? json) => OnboardingTrainingPreferences(
        minTrainingDuration: json?['minTrainingDuration'],
        maxTrainingDuration: json?['maxTrainingDuration'],
        trainingDaysPerWeek: json?['trainingDaysPerWeek'],
        wantsCardio: json?['wantsCardio'],
        trainingFocus: json?['trainingFocus'],
        preferredGymTime: json?['preferredGymTime'],
      );
}

class OnboardingStatus {
  OnboardingStatus({
    required this.profile,
    required this.disclaimerAccepted,
    required this.anamnesis,
    required this.trainingPreferences,
    required this.nextStep,
    required this.completed,
  });
  final OnboardingProfile profile;
  final bool disclaimerAccepted;
  final OnboardingAnamnesis? anamnesis;
  final OnboardingTrainingPreferences? trainingPreferences;
  final String nextStep;
  final bool completed;

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) => OnboardingStatus(
        profile: OnboardingProfile.fromJson(json['profile']),
        disclaimerAccepted: json['disclaimerAccepted'] ?? false,
        anamnesis: json['anamnesis'] != null ? OnboardingAnamnesis.fromJson(json['anamnesis']) : null,
        trainingPreferences:
            json['trainingPreferences'] != null ? OnboardingTrainingPreferences.fromJson(json['trainingPreferences']) : null,
        nextStep: json['nextStep'] ?? 'PROFILE',
        completed: json['completed'] ?? false,
      );
}

/// Erros de validação de campo devolvidos pelo backend (400 `{ errors: {...} }`) — mesmas
/// mensagens em português já usadas pelo bot do WhatsApp (InputValidatorService).
class OnboardingValidationException implements Exception {
  OnboardingValidationException(this.errors);
  final Map<String, String> errors;
}

/// Conflito de unicidade (409 `{ field, message }`), ex: email ou CPF já cadastrado.
class OnboardingConflictException implements Exception {
  OnboardingConflictException(this.field, this.message);
  final String field;
  final String message;
}

class OnboardingApi {
  OnboardingApi(this._dio);
  final Dio _dio;

  Future<OnboardingStatus> getStatus() async {
    final response = await _dio.get('/app/onboarding');
    return OnboardingStatus.fromJson(response.data);
  }

  Future<void> updateProfile({
    required String name,
    required String gender,
    required String birthDate,
    required num weight,
    required num height,
    required String email,
    String? cpf,
  }) async {
    await _handle(() => _dio.put('/app/onboarding/profile', data: {
          if (cpf != null && cpf.isNotEmpty) 'cpf': cpf,
          'name': name,
          'gender': gender,
          'birthDate': birthDate,
          'weight': weight,
          'height': height,
          'email': email,
        }));
  }

  Future<void> acceptDisclaimer({required bool accepted, required String cpf}) async {
    await _handle(() => _dio.put('/app/onboarding/disclaimer', data: {'accepted': accepted, 'cpf': cpf}));
  }

  /// Define a senha pra login alternativo (email+senha, sem OTP) — usado por quem criou
  /// perfil só pelo app, sem WhatsApp.
  Future<void> setPassword(String password) async {
    await _handle(() => _dio.put('/app/onboarding/password', data: {'password': password}));
  }

  Future<void> saveAnamnesis({
    required String mainGoal,
    required bool hasDiseases,
    String? diseases,
    required bool hasPhysicalLimitations,
    String? physicalLimitations,
    required String physicalActivityLevel,
  }) async {
    await _handle(() => _dio.put('/app/onboarding/anamnesis', data: {
          'mainGoal': mainGoal,
          'hasDiseases': hasDiseases,
          if (hasDiseases) 'diseases': diseases,
          'hasPhysicalLimitations': hasPhysicalLimitations,
          if (hasPhysicalLimitations) 'physicalLimitations': physicalLimitations,
          'physicalActivityLevel': physicalActivityLevel,
        }));
  }

  Future<void> saveTrainingPreferences({
    required int minTrainingDuration,
    required int maxTrainingDuration,
    required int trainingDaysPerWeek,
    required bool wantsCardio,
    required String trainingFocus,
    String? preferredGymTime,
  }) async {
    await _handle(() => _dio.put('/app/onboarding/training-preferences', data: {
          'minTrainingDuration': minTrainingDuration,
          'maxTrainingDuration': maxTrainingDuration,
          'trainingDaysPerWeek': trainingDaysPerWeek,
          'wantsCardio': wantsCardio,
          'trainingFocus': trainingFocus,
          if (preferredGymTime != null) 'preferredGymTime': preferredGymTime,
        }));
  }

  Future<void> _handle(Future<Response> Function() call) async {
    try {
      await call();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      if (status == 400 && data is Map && data['errors'] is Map) {
        throw OnboardingValidationException(Map<String, String>.from(data['errors']));
      }
      if (status == 409 && data is Map) {
        throw OnboardingConflictException((data['field'] ?? '').toString(), (data['message'] ?? 'Conflito.').toString());
      }
      rethrow;
    }
  }
}

final onboardingApiProvider = Provider<OnboardingApi>((ref) => OnboardingApi(ref.watch(apiClientProvider).dio));
