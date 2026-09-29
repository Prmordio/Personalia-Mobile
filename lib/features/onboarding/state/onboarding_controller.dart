import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/data/app_api.dart';
import '../data/onboarding_api.dart';

enum OnboardingStep {
  name,
  cpf,
  disclaimer,
  gender,
  birthDate,
  weight,
  height,
  email,
  password,
  profileConfirmation,
  mainGoal,
  healthConditions,
  activityLevel,
  anamnesisConfirmation,
  trainingDuration,
  trainingDays,
  gymTime,
  cardio,
  trainingFocus,
  freeTrial,
  generating,
  done,
}

class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.name,
    this.loading = false,
    this.error,
    this.fieldErrors = const {},
    this.resumed = false,
    this.name = '',
    this.gender,
    this.birthDate,
    this.weight,
    this.height,
    this.email = '',
    this.password = '',
    this.disclaimerAccepted = false,
    this.cpf = '',
    this.mainGoal,
    this.hasDiseases,
    this.diseases = '',
    this.hasPhysicalLimitations,
    this.physicalLimitations = '',
    this.physicalActivityLevel,
    this.minTrainingDuration,
    this.maxTrainingDuration,
    this.trainingDaysPerWeek,
    this.wantsCardio,
    this.trainingFocus,
    this.preferredGymTime,
    this.generationTimedOut = false,
  });

  final OnboardingStep step;
  final bool loading;
  final String? error;
  final Map<String, String> fieldErrors;
  final bool resumed;

  // Perfil (nome → CPF → disclaimer → o restante)
  final String name;
  final String? gender;
  final DateTime? birthDate;
  final num? weight;
  final num? height;
  final String email;
  final String password;

  // Disclaimer + CPF
  final bool disclaimerAccepted;
  final String cpf;

  // Anamnese
  final String? mainGoal;
  final bool? hasDiseases;
  final String diseases;
  final bool? hasPhysicalLimitations;
  final String physicalLimitations;
  final String? physicalActivityLevel;

  // Preferências de treino
  final int? minTrainingDuration;
  final int? maxTrainingDuration;
  final int? trainingDaysPerWeek;
  final bool? wantsCardio;
  final String? trainingFocus;
  final String? preferredGymTime;

  final bool generationTimedOut;

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? loading,
    String? error,
    Map<String, String>? fieldErrors,
    bool? resumed,
    String? name,
    String? gender,
    DateTime? birthDate,
    num? weight,
    num? height,
    String? email,
    String? password,
    bool? disclaimerAccepted,
    String? cpf,
    String? mainGoal,
    bool? hasDiseases,
    String? diseases,
    bool? hasPhysicalLimitations,
    String? physicalLimitations,
    String? physicalActivityLevel,
    int? minTrainingDuration,
    int? maxTrainingDuration,
    int? trainingDaysPerWeek,
    bool? wantsCardio,
    String? trainingFocus,
    String? preferredGymTime,
    bool clearPreferredGymTime = false,
    bool? generationTimedOut,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      loading: loading ?? this.loading,
      error: error,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      resumed: resumed ?? this.resumed,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      email: email ?? this.email,
      password: password ?? this.password,
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
      cpf: cpf ?? this.cpf,
      mainGoal: mainGoal ?? this.mainGoal,
      hasDiseases: hasDiseases ?? this.hasDiseases,
      diseases: diseases ?? this.diseases,
      hasPhysicalLimitations: hasPhysicalLimitations ?? this.hasPhysicalLimitations,
      physicalLimitations: physicalLimitations ?? this.physicalLimitations,
      physicalActivityLevel: physicalActivityLevel ?? this.physicalActivityLevel,
      minTrainingDuration: minTrainingDuration ?? this.minTrainingDuration,
      maxTrainingDuration: maxTrainingDuration ?? this.maxTrainingDuration,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      wantsCardio: wantsCardio ?? this.wantsCardio,
      trainingFocus: trainingFocus ?? this.trainingFocus,
      preferredGymTime: clearPreferredGymTime ? null : (preferredGymTime ?? this.preferredGymTime),
      generationTimedOut: generationTimedOut ?? this.generationTimedOut,
    );
  }
}

const _anamnesisOrder = [
  OnboardingStep.mainGoal,
  OnboardingStep.healthConditions,
  OnboardingStep.activityLevel,
];

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._api, this._appApi) : super(const OnboardingState());

  final OnboardingApi _api;
  final AppApi _appApi;

  /// Carrega o status atual (chamado ao entrar na wizard) e pula pro passo certo,
  /// pré-preenchendo o que já foi salvo — cobre o caso do usuário fechar o app no meio.
  Future<void> resume() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final status = await _api.getStatus();
      final p = status.profile;
      final a = status.anamnesis;
      final t = status.trainingPreferences;
      state = state.copyWith(
        loading: false,
        resumed: true,
        name: p.name ?? '',
        gender: p.gender,
        birthDate: p.birthDate != null ? _parseBrDate(p.birthDate!) : null,
        weight: p.weight,
        height: p.height,
        email: p.email ?? '',
        cpf: p.cpf ?? '',
        disclaimerAccepted: status.disclaimerAccepted,
        mainGoal: a?.mainGoal,
        hasDiseases: a?.hasDiseases,
        diseases: a?.diseases ?? '',
        hasPhysicalLimitations: a?.hasPhysicalLimitations,
        physicalLimitations: a?.physicalLimitations ?? '',
        physicalActivityLevel: a?.physicalActivityLevel,
        minTrainingDuration: t?.minTrainingDuration,
        maxTrainingDuration: t?.maxTrainingDuration,
        trainingDaysPerWeek: t?.trainingDaysPerWeek,
        wantsCardio: t?.wantsCardio,
        trainingFocus: t?.trainingFocus,
        preferredGymTime: t?.preferredGymTime,
        step: _stepFor(status.nextStep),
      );
    } catch (_) {
      // Falha ao consultar o status: segue do início (perfil) em vez de travar a wizard.
      state = state.copyWith(loading: false, resumed: true);
    }
  }

  OnboardingStep _stepFor(String nextStep) {
    switch (nextStep) {
      case 'DISCLAIMER_CPF':
        return OnboardingStep.cpf;
      case 'ANAMNESIS':
        return OnboardingStep.mainGoal;
      case 'TRAINING_PREFERENCES':
        return OnboardingStep.trainingDuration;
      case 'DONE':
        return OnboardingStep.done;
      default:
        return OnboardingStep.name;
    }
  }

  DateTime? _parseBrDate(String ddMMyyyy) {
    final parts = ddMMyyyy.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _formatBrDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void clearError() => state = state.copyWith(error: null, fieldErrors: const {});

  void goTo(OnboardingStep step) => state = state.copyWith(step: step);

  // --- Nome → CPF → Disclaimer ---

  void setName(String value) => state = state.copyWith(name: value, step: OnboardingStep.cpf);

  void setCpf(String value) => state = state.copyWith(cpf: value, step: OnboardingStep.disclaimer);

  void setDisclaimerAccepted(bool value) => state = state.copyWith(disclaimerAccepted: value);

  void confirmDisclaimer() {
    if (!state.disclaimerAccepted) return;
    state = state.copyWith(step: OnboardingStep.gender);
  }

  // --- Resto do perfil ---

  void setGender(String value) => state = state.copyWith(gender: value, step: OnboardingStep.birthDate);

  /// Só guarda a data escolhida no picker — o avanço de passo acontece em [confirmBirthDate],
  /// disparado pelo botão "Continuar" (o picker sozinho não deve pular de tela).
  void pickBirthDate(DateTime value) => state = state.copyWith(birthDate: value);

  void confirmBirthDate() {
    if (state.birthDate == null) return;
    state = state.copyWith(step: OnboardingStep.weight);
  }

  void setWeight(num value) => state = state.copyWith(weight: value, step: OnboardingStep.height);

  void setHeight(num value) => state = state.copyWith(height: value, step: OnboardingStep.email);

  void setEmail(String value) => state = state.copyWith(email: value, step: OnboardingStep.password);

  static const _minPasswordLength = 8;

  /// Senha pra login alternativo (email+senha, sem OTP) — obrigatória pra quem cria perfil
  /// só pelo app. Validação local, o backend não expõe leitura desse campo em lugar nenhum.
  void confirmPassword(String value) {
    if (value.length < _minPasswordLength) {
      state = state.copyWith(
        fieldErrors: {'password': 'A senha deve ter pelo menos $_minPasswordLength caracteres.'},
      );
      return;
    }
    state = state.copyWith(password: value, fieldErrors: const {}, step: OnboardingStep.profileConfirmation);
  }

  /// Confirma perfil + CPF/disclaimer + senha juntos (telas separadas, mas um único ponto de
  /// envio, na revisão final). Ordem importa: o endpoint de disclaimer exige name/email já
  /// persistidos no backend, por isso perfil vai primeiro.
  Future<bool> submitProfile() async {
    if (state.birthDate == null || state.gender == null) return false;
    state = state.copyWith(loading: true, error: null, fieldErrors: const {});
    try {
      await _api.updateProfile(
        name: state.name,
        gender: state.gender!,
        birthDate: _formatBrDate(state.birthDate!),
        weight: state.weight!,
        height: state.height!,
        email: state.email,
      );
    } on OnboardingValidationException catch (e) {
      state = state.copyWith(loading: false, fieldErrors: e.errors, step: OnboardingStep.name);
      return false;
    } on OnboardingConflictException catch (e) {
      state = state.copyWith(loading: false, fieldErrors: {e.field: e.message}, step: OnboardingStep.email);
      return false;
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Não foi possível salvar seu perfil. Tente novamente.');
      return false;
    }

    try {
      await _api.acceptDisclaimer(accepted: state.disclaimerAccepted, cpf: state.cpf);
    } on OnboardingValidationException catch (e) {
      final step = e.errors.containsKey('cpf') ? OnboardingStep.cpf : OnboardingStep.disclaimer;
      state = state.copyWith(loading: false, fieldErrors: e.errors, step: step);
      return false;
    } on OnboardingConflictException catch (e) {
      state = state.copyWith(loading: false, fieldErrors: {e.field: e.message}, step: OnboardingStep.cpf);
      return false;
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Não foi possível aceitar os termos. Tente novamente.');
      return false;
    }

    try {
      await _api.setPassword(state.password);
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Não foi possível salvar sua senha. Tente novamente.', step: OnboardingStep.password);
      return false;
    }

    state = state.copyWith(loading: false, step: OnboardingStep.mainGoal);
    return true;
  }

  // --- Anamnese ---

  void setMainGoal(String value) => state = state.copyWith(mainGoal: value, step: OnboardingStep.healthConditions);

  // --- Doenças + limitações físicas (uma tela só, com campo de texto condicional) ---

  void setHasDiseases(bool value) => state = state.copyWith(
        hasDiseases: value,
        diseases: value ? state.diseases : '',
        fieldErrors: const {},
      );

  void setDiseases(String value) => state = state.copyWith(diseases: value);

  void setHasLimitations(bool value) => state = state.copyWith(
        hasPhysicalLimitations: value,
        physicalLimitations: value ? state.physicalLimitations : '',
        fieldErrors: const {},
      );

  void setLimitations(String value) => state = state.copyWith(physicalLimitations: value);

  /// Valida as duas perguntas juntas antes de avançar: cada uma respondida, e com texto
  /// preenchido quando a resposta for "Sim" (mesma regra do backend, InputValidatorService).
  void confirmHealthConditions() {
    final errors = <String, String>{};
    if (state.hasDiseases == null) {
      errors['hasDiseases'] = 'Responda se você possui alguma doença ou condição médica.';
    } else if (state.hasDiseases == true && state.diseases.trim().length < 2) {
      errors['diseases'] = 'Descreva suas doenças ou condições (ou volte e responda Não).';
    }
    if (state.hasPhysicalLimitations == null) {
      errors['hasLimitations'] = 'Responda se você possui alguma limitação física.';
    } else if (state.hasPhysicalLimitations == true && state.physicalLimitations.trim().length < 2) {
      errors['limitations'] = 'Descreva suas limitações físicas (ou volte e responda Não).';
    }
    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return;
    }
    state = state.copyWith(fieldErrors: const {}, step: OnboardingStep.activityLevel);
  }

  void setActivityLevel(String value) =>
      state = state.copyWith(physicalActivityLevel: value, step: OnboardingStep.anamnesisConfirmation);

  Future<bool> submitAnamnesis() async {
    state = state.copyWith(loading: true, error: null, fieldErrors: const {});
    try {
      await _api.saveAnamnesis(
        mainGoal: state.mainGoal!,
        hasDiseases: state.hasDiseases ?? false,
        diseases: state.diseases,
        hasPhysicalLimitations: state.hasPhysicalLimitations ?? false,
        physicalLimitations: state.physicalLimitations,
        physicalActivityLevel: state.physicalActivityLevel!,
      );
      state = state.copyWith(loading: false, step: OnboardingStep.trainingDuration);
      return true;
    } on OnboardingValidationException catch (e) {
      state = state.copyWith(loading: false, fieldErrors: e.errors, step: _anamnesisOrder.first);
      return false;
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Não foi possível salvar sua anamnese. Tente novamente.');
      return false;
    }
  }

  // --- Preferências de treino ---

  /// Duração mín./máx. ficam na mesma tela (dois spinners) — ajusta o máximo pra cima
  /// automaticamente se o usuário sobe o mínimo além dele, e vice-versa.
  void setMinDurationDraft(int value) {
    final currentMax = state.maxTrainingDuration ?? 60;
    state = state.copyWith(minTrainingDuration: value, maxTrainingDuration: currentMax < value ? value : currentMax);
  }

  void setMaxDurationDraft(int value) {
    final currentMin = state.minTrainingDuration ?? 45;
    state = state.copyWith(maxTrainingDuration: value, minTrainingDuration: currentMin > value ? value : currentMin);
  }

  void confirmDurationRange() => state = state.copyWith(
        minTrainingDuration: state.minTrainingDuration ?? 45,
        maxTrainingDuration: state.maxTrainingDuration ?? 60,
        step: OnboardingStep.trainingDays,
      );

  void setTrainingDaysDraft(int value) => state = state.copyWith(trainingDaysPerWeek: value);

  void confirmTrainingDays() =>
      state = state.copyWith(trainingDaysPerWeek: state.trainingDaysPerWeek ?? 3, step: OnboardingStep.gymTime);

  /// Só guarda o horário digitado — o avanço de passo acontece em [confirmGymTime] ou
  /// [skipGymTime] (o campo sozinho não deve pular de tela).
  void pickGymTime(String value) => state = state.copyWith(preferredGymTime: value);

  void confirmGymTime() => state = state.copyWith(step: OnboardingStep.cardio);

  void skipGymTime() => state = state.copyWith(clearPreferredGymTime: true, step: OnboardingStep.cardio);

  void setWantsCardio(bool value) => state = state.copyWith(wantsCardio: value, step: OnboardingStep.trainingFocus);

  void setTrainingFocus(String value) => state = state.copyWith(trainingFocus: value);

  Future<bool> submitTrainingPreferences() async {
    state = state.copyWith(loading: true, error: null, fieldErrors: const {});
    try {
      await _api.saveTrainingPreferences(
        minTrainingDuration: state.minTrainingDuration!,
        maxTrainingDuration: state.maxTrainingDuration!,
        trainingDaysPerWeek: state.trainingDaysPerWeek!,
        wantsCardio: state.wantsCardio ?? false,
        trainingFocus: state.trainingFocus!,
        preferredGymTime: state.preferredGymTime,
      );
      state = state.copyWith(loading: false, step: OnboardingStep.freeTrial);
      return true;
    } on OnboardingValidationException catch (e) {
      state = state.copyWith(loading: false, fieldErrors: e.errors, step: OnboardingStep.trainingDuration);
      return false;
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Não foi possível salvar suas preferências. Tente novamente.');
      return false;
    }
  }

  // --- Geração automática do treino ---

  /// Chamado pela tela de anúncio do período grátis — só depois disso a geração de verdade
  /// começa (o backend concede o trial, se elegível, no início de POST /app/workout/generate).
  void proceedToGenerate() => unawaited(_startGenerating());

  Future<void> _startGenerating() async {
    state = state.copyWith(step: OnboardingStep.generating, loading: true, generationTimedOut: false);
    try {
      final started = await _appApi.generateWorkout();
      if (!started) {
        // Sem assinatura (trial já usado): nada vai ser gerado — vai pra Home, que mostra o "Assinar".
        state = state.copyWith(step: OnboardingStep.done, loading: false);
        return;
      }
    } catch (_) {
      // Fire-and-forget, igual o botão "Gerar meu treino" da Home — segue pro polling mesmo assim.
    }

    const maxAttempts = 40; // ~2min a 3s de intervalo
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final workout = await _appApi.getCurrentWorkout();
        if (workout != null) {
          state = state.copyWith(step: OnboardingStep.done, loading: false);
          return;
        }
      } catch (_) {
        // Mantém tentando — erro transitório de rede não deve interromper o polling.
      }
    }
    state = state.copyWith(loading: false, generationTimedOut: true);
  }
}

final onboardingControllerProvider = StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController(ref.watch(onboardingApiProvider), ref.watch(appApiProvider));
});
