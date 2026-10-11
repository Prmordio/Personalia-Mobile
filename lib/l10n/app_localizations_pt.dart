// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'PersonalIA';

  @override
  String get continuar => 'Continuar';

  @override
  String get confirmar => 'Confirmar';

  @override
  String get pular => 'Pular';

  @override
  String get cancelar => 'Cancelar';

  @override
  String get salvar => 'Salvar';

  @override
  String get sim => 'Sim';

  @override
  String get nao => 'Não';

  @override
  String get entrar => 'Entrar';

  @override
  String get ativar => 'Ativar';

  @override
  String get agoraNao => 'Agora não';

  @override
  String get voltar => 'Voltar';

  @override
  String get genericError => 'Não foi possível concluir. Tente novamente.';

  @override
  String get welcomeBiometricButton => 'Entrar com biometria';

  @override
  String get welcomeEmailButton => 'Entrar com email e senha';

  @override
  String get welcomeWhatsAppButton => 'Já uso o PersonalIA no WhatsApp';

  @override
  String get welcomeNewUserButton =>
      'Ainda não uso o PersonalIA — criar perfil';

  @override
  String get errAuthBiometricExpired =>
      'Sua biometria expirou ou foi desativada. Entre com email e senha.';

  @override
  String get errAuthBiometricFailed =>
      'Não foi possível entrar agora. Tente novamente.';

  @override
  String get loginCreateProfileTitle => 'Criar perfil';

  @override
  String get loginSyncTitle => 'Sincronizar conta';

  @override
  String get loginCreateProfileDesc =>
      'Digite seu telefone com DDI e DDD pra criar seu perfil e receber um código de acesso.';

  @override
  String get loginSyncDesc =>
      'Digite o telefone da sua conta PersonalIA no WhatsApp pra receber um código de acesso.';

  @override
  String get loginHowToReceive => 'Como você quer receber o código?';

  @override
  String loginReceiveVia(String channel) {
    return 'Receber por $channel';
  }

  @override
  String get loginEnterCode => 'Digite o código';

  @override
  String loginCodeSentVia(String channel) {
    return 'Enviamos um código de 6 dígitos por $channel.';
  }

  @override
  String get loginResendCode => 'Reenviar código';

  @override
  String get loginUseOtherPhone => 'Usar outro número';

  @override
  String get errAuthCannotVerifyPhone =>
      'Não foi possível verificar esse número.';

  @override
  String get errAuthCannotSendCode =>
      'Não foi possível enviar o código. Tente novamente.';

  @override
  String get infoAuthCodeResent => 'Código reenviado.';

  @override
  String get errAuthCannotResendCode =>
      'Não foi possível reenviar o código. Tente novamente.';

  @override
  String get errAuthInvalidCode => 'Código inválido ou expirado.';

  @override
  String get errAuthLoginFailed => 'Não foi possível entrar. Tente novamente.';

  @override
  String get passwordLoginTitle => 'Entrar com email';

  @override
  String get passwordHint => 'Senha';

  @override
  String get forgotPasswordLink => 'Esqueci minha senha';

  @override
  String get forgotPasswordTitle => 'Redefinir senha';

  @override
  String get forgotPasswordEnterCodeDesc =>
      'Digite o código que chegou no seu email e escolha uma nova senha.';

  @override
  String get forgotPasswordEnterEmailDesc =>
      'Informe o email da sua conta. Vamos enviar um código para você criar uma nova senha.';

  @override
  String get forgotPasswordCodeHint => 'Código de 6 dígitos';

  @override
  String get forgotPasswordNewPasswordHint =>
      'Nova senha (mínimo 8 caracteres)';

  @override
  String get forgotPasswordSendCode => 'Enviar código';

  @override
  String get forgotPasswordSavePassword => 'Salvar nova senha';

  @override
  String get forgotPasswordNoCode => 'Não recebi o código / trocar email';

  @override
  String forgotPasswordCodeSentFor(String email) {
    return 'Se houver uma conta com $email, enviamos um código de 6 dígitos. Confira também o spam.';
  }

  @override
  String get appAccessTitle => 'Acessar o app';

  @override
  String get appAccessEmailCodeTitle => 'Código do email';

  @override
  String get appAccessPhoneCodeTitle => 'Código do WhatsApp';

  @override
  String get appAccessConfirmEmailTitle => 'Confirme seu email';

  @override
  String get appAccessPasswordTitle => 'Crie sua senha';

  @override
  String get appAccessSendCodeAction => 'Enviar código';

  @override
  String get appAccessSavePassword => 'Salvar senha e entrar';

  @override
  String get appAccessConfirmCode => 'Confirmar código';

  @override
  String get appAccessStartDesc =>
      'Informe o telefone que você usa no WhatsApp com o PersonalIA e o seu email.';

  @override
  String get appAccessPhoneHint => 'Telefone com DDD';

  @override
  String get appAccessPhoneCodeDesc =>
      'Se você falou com o PersonalIA no WhatsApp nas últimas 24h, o código já deve ter chegado lá. Se não chegou, toque em \"Abrir WhatsApp\" e envie a mensagem pronta — respondemos com o código.';

  @override
  String get appAccessOpenWhatsApp => 'Abrir WhatsApp';

  @override
  String get appAccessConfirmEmailDesc =>
      'Número confirmado ✅ Confira seu email (corrija se precisar) — vamos enviar um código para ele.';

  @override
  String get appAccessPasswordDesc =>
      'Tudo confirmado ✅ Agora é só criar a senha para entrar com email e senha.';

  @override
  String get appAccessRepeatPasswordHint => 'Repita a senha';

  @override
  String get appAccessCodeHint => 'Código de 6 dígitos';

  @override
  String get appAccessFixEmail => 'Email errado? Corrigir';

  @override
  String get appAccessNoEmail => 'Não recebi o email / email errado';

  @override
  String get appAccessRestart => 'Recomeçar';

  @override
  String get appAccessInfoCodeRequested =>
      'Se houver cadastro com esses dados, enviamos um código para o email e/ou WhatsApp cadastrados.';

  @override
  String get appAccessInfoEmailConfirmed =>
      'Email confirmado ✅ Agora confirme seu número pelo WhatsApp.';

  @override
  String appAccessInfoPhoneConfirmed(String email) {
    return 'Número confirmado ✅ Digite o código que enviamos para $email.';
  }

  @override
  String appAccessInfoCodeSentTo(String email) {
    return 'Enviamos um código para $email.';
  }

  @override
  String get errAppAccessPhone => 'Informe o telefone com DDD.';

  @override
  String get errAppAccessEmail => 'Informe um email válido.';

  @override
  String get errAuthCodeLength => 'O código tem 6 dígitos.';

  @override
  String get errAuthPasswordTooShort =>
      'A senha deve ter pelo menos 8 caracteres.';

  @override
  String get errAuthPasswordMismatch => 'As senhas não conferem.';

  @override
  String get errPasswordMismatch => 'As senhas não coincidem.';

  @override
  String get biometricOfferTitle => 'Entrar com biometria?';

  @override
  String get biometricOfferDesc =>
      'Da próxima vez, entre com sua digital ou rosto, sem digitar a senha.';

  @override
  String get biometricEnabled => 'Biometria ativada ✅';

  @override
  String get errBiometricActivateFailed =>
      'Não foi possível ativar a biometria. Tente de novo pelo Menu.';

  @override
  String get biometricToggleTitle => 'Entrar com biometria';

  @override
  String get biometricToggleSubtitle => 'Digital ou rosto em vez da senha';

  @override
  String get errBiometricToggleFailed =>
      'Não foi possível ativar a biometria. Tente novamente.';

  @override
  String get biometricConfirmPrompt =>
      'Confirme para ativar o login por biometria';

  @override
  String get biometricLoginPrompt => 'Entre no PersonalIA';

  @override
  String get menuTitle => 'Menu';

  @override
  String get menuCurrentWorkout => 'Meu Treino Atual';

  @override
  String get menuHistory => 'Histórico';

  @override
  String get menuSearchMachine => 'Pesquisar máquina';

  @override
  String get menuAskDoubt => 'Tirar dúvidas';

  @override
  String get menuUpdateProfile => 'Atualizar Meu Perfil';

  @override
  String get menuTrainingPreferences => 'Preferências de Treino';

  @override
  String get menuAppearance => 'Aparência';

  @override
  String get menuLanguage => 'Idioma';

  @override
  String get menuLogout => 'Sair';

  @override
  String get appearanceSystem => 'Sistema';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceDark => 'Escuro';

  @override
  String get errAppearanceSave =>
      'Não foi possível salvar a aparência. Tente novamente.';

  @override
  String get langSystem => 'Sistema';

  @override
  String get langPortuguese => 'Português';

  @override
  String get langEnglish => 'English';

  @override
  String get langSpanish => 'Español';

  @override
  String get errLanguageSave =>
      'Não foi possível salvar o idioma. Tente novamente.';

  @override
  String get onboardingNameTitle => 'Qual é o seu nome completo?';

  @override
  String get onboardingNameHint => 'Nome e sobrenome';

  @override
  String get onboardingGenderTitle => 'Qual o seu gênero?';

  @override
  String get genderMale => 'Masculino';

  @override
  String get genderFemale => 'Feminino';

  @override
  String get onboardingBirthDateTitle => 'Qual a sua data de nascimento?';

  @override
  String get onboardingPickDate => 'Selecionar data';

  @override
  String get onboardingWeightTitle => 'Qual o seu peso? (kg)';

  @override
  String get onboardingWeightHint => 'Ex: 70.5';

  @override
  String get onboardingHeightTitle => 'Qual a sua altura? (cm)';

  @override
  String get onboardingHeightHint => 'Ex: 175';

  @override
  String get onboardingEmailTitle => 'Qual o seu email?';

  @override
  String get onboardingEmailHint => 'seuemail@exemplo.com';

  @override
  String get onboardingConfirmDataTitle => 'Confira seus dados';

  @override
  String get onboardingCpfTitle => 'Qual o seu CPF?';

  @override
  String get onboardingCpfHint => '000.000.000-00';

  @override
  String get summaryName => 'Nome';

  @override
  String get summaryCpf => 'CPF';

  @override
  String get summaryTerms => 'Termos de uso';

  @override
  String get summaryGender => 'Gênero';

  @override
  String get summaryBirthDate => 'Data de nascimento';

  @override
  String get summaryWeight => 'Peso';

  @override
  String get summaryHeight => 'Altura';

  @override
  String get summaryEmail => 'Email';

  @override
  String get summaryAccepted => 'Aceito';

  @override
  String get summaryNotAccepted => 'Não aceito';

  @override
  String unitKg(String weight) {
    return '$weight kg';
  }

  @override
  String unitCm(String height) {
    return '$height cm';
  }

  @override
  String get disclaimerTitle => 'Antes de continuar';

  @override
  String get disclaimerSubtitle =>
      'Você declara estar apto fisicamente para treinar e aceita nossos termos de uso?';

  @override
  String get disclaimerCheckbox =>
      'Declaro estar apto fisicamente para treinar e aceito os termos de uso.';

  @override
  String get disclaimerReadTerms => 'Ler os termos de uso completos';

  @override
  String get onboardingCreatePasswordTitle => 'Crie uma senha';

  @override
  String get onboardingCreatePasswordSubtitle =>
      'Assim você também pode entrar com email e senha, sem precisar de um novo código toda vez.';

  @override
  String get onboardingPasswordHint => 'Senha (mínimo 8 caracteres)';

  @override
  String get onboardingConfirmPasswordHint => 'Confirmar senha';

  @override
  String get onboardingMainGoalTitle => 'Qual é o seu objetivo principal?';

  @override
  String get goalMassGain => 'Ganho de massa';

  @override
  String get goalWeightLoss => 'Perda de peso';

  @override
  String get goalStrength => 'Força';

  @override
  String get goalConditioning => 'Condicionamento';

  @override
  String get onboardingHealthTitle => 'Saúde e limitações';

  @override
  String get onboardingHasDiseases =>
      'Você possui alguma doença ou condição médica?';

  @override
  String get onboardingDiseasesHint => 'Ex: Hipertensão controlada';

  @override
  String get onboardingHasLimitations => 'Você possui alguma limitação física?';

  @override
  String get onboardingLimitationsHint => 'Ex: Lesão no ombro direito';

  @override
  String get onboardingActivityLevelTitle =>
      'Qual o seu nível de atividade física atual?';

  @override
  String get activitySedentary => 'Sedentário';

  @override
  String get activityLight => 'Leve (1-3 dias/semana)';

  @override
  String get activityModerate => 'Moderado (3-5 dias/semana)';

  @override
  String get activityIntense => 'Intenso (6-7 dias/semana)';

  @override
  String get activityAthlete => 'Atleta ou trabalho físico pesado';

  @override
  String get onboardingConfirmAnamnesisTitle => 'Confira sua anamnese';

  @override
  String get summaryGoal => 'Objetivo';

  @override
  String get summaryDiseases => 'Doenças';

  @override
  String get summaryPhysicalLimitations => 'Limitações físicas';

  @override
  String get summaryActivityLevel => 'Nível de atividade';

  @override
  String get onboardingDurationTitle => 'Duração do treino';

  @override
  String get onboardingDurationSubtitle => 'Entre 30 e 180 minutos.';

  @override
  String get onboardingDurationMin => 'Duração mínima (minutos)';

  @override
  String get onboardingDurationMax => 'Duração máxima (minutos)';

  @override
  String get onboardingTrainingDaysTitle =>
      'Quantos dias por semana você quer treinar?';

  @override
  String get onboardingTrainingDaysSubtitle => 'Entre 1 e 7 dias.';

  @override
  String suffixDays(int count) {
    return '$count dias';
  }

  @override
  String get onboardingGymTimeTitle =>
      'Qual o seu horário preferido de treino?';

  @override
  String get onboardingGymTimeSubtitle =>
      'Opcional — você pode pular esta etapa.';

  @override
  String get onboardingCardioTitle => 'Você quer incluir cardio no seu treino?';

  @override
  String get onboardingCardioInclude => 'Incluir cardio no fim do treino';

  @override
  String get onboardingTrainingFocusTitle => 'Qual o foco do seu treino?';

  @override
  String get focusUpper => 'Membros superiores';

  @override
  String get focusLower => 'Membros inferiores';

  @override
  String get focusFullBody => 'Corpo todo';

  @override
  String freeTrialTitle(String name) {
    return '🎁 7 dias grátis liberados, $name!';
  }

  @override
  String get freeTrialSubtitle =>
      'Aproveite pra deixar seu treino pronto e explorar o app à vontade.';

  @override
  String get generateWorkoutButton => 'Gerar meu treino';

  @override
  String get generatingWorkoutWait => 'Isso pode levar alguns minutos.';

  @override
  String get generatingWorkoutTimeout =>
      'Isso está demorando mais que o normal.';

  @override
  String get generatingWorkoutTimeoutDesc =>
      'Você pode continuar pelo início — seu treino aparece por lá assim que ficar pronto.';

  @override
  String get generatingWorkoutGoHome => 'Ir para o início';

  @override
  String get thinkingStep0 => 'Analisando seu perfil...';

  @override
  String get thinkingStep1 => 'Pensando no melhor plano...';

  @override
  String get thinkingStep2 => 'Calculando séries e cargas...';

  @override
  String get thinkingStep3 => 'Escolhendo os exercícios certos...';

  @override
  String get thinkingStep4 => 'Ajustando o volume de treino...';

  @override
  String get thinkingStep5 => 'Alinhando com o seu objetivo...';

  @override
  String get thinkingStep6 => 'Finalizando os detalhes...';

  @override
  String get errOnboardingCannotSaveProfile =>
      'Não foi possível salvar seu perfil. Tente novamente.';

  @override
  String get errOnboardingCannotSaveTerms =>
      'Não foi possível aceitar os termos. Tente novamente.';

  @override
  String get errOnboardingCannotSavePassword =>
      'Não foi possível salvar sua senha. Tente novamente.';

  @override
  String get errOnboardingCannotSaveAnamnesis =>
      'Não foi possível salvar sua anamnese. Tente novamente.';

  @override
  String get errOnboardingCannotSavePrefs =>
      'Não foi possível salvar suas preferências. Tente novamente.';

  @override
  String get errOnboardingAnswerDisease =>
      'Responda se você possui alguma doença ou condição médica.';

  @override
  String get errOnboardingDescribeDisease =>
      'Descreva suas doenças ou condições (ou volte e responda Não).';

  @override
  String get errOnboardingAnswerLimitation =>
      'Responda se você possui alguma limitação física.';

  @override
  String get errOnboardingDescribeLimitation =>
      'Descreva suas limitações físicas (ou volte e responda Não).';

  @override
  String get homeAppBarTitle => 'PersonalIA';

  @override
  String get subscriptionFreeTrial => 'Período grátis ativo';

  @override
  String get subscriptionActive => 'Assinatura ativa';

  @override
  String get subscriptionInactive => 'Sem assinatura ativa';

  @override
  String subscriptionValidUntil(String date) {
    return 'Válido até $date';
  }

  @override
  String subscriptionNextCharge(String date) {
    return 'Próxima cobrança em $date';
  }

  @override
  String get subscriptionSignupPrompt =>
      'Assine para continuar gerando treinos.';

  @override
  String get subscriptionButton => 'Assinar';

  @override
  String get dailyTipTitle => 'Dica do dia';

  @override
  String get errLoadWorkout => 'Não foi possível carregar seu treino.';

  @override
  String get noWorkoutIdleTitle => 'Você ainda não tem um treino ativo.';

  @override
  String get noWorkoutGeneratingTitle => 'Gerando seu treino...';

  @override
  String get noWorkoutGeneratingSubtitle =>
      'Isso pode levar alguns minutos. Ele aparece aqui assim que ficar pronto.';

  @override
  String get noWorkoutFailedTitle => 'Não conseguimos gerar seu treino agora.';

  @override
  String get noWorkoutFailedSubtitle =>
      'Nossa IA teve um problema ao montar o plano. Tente de novo em instantes.';

  @override
  String get noWorkoutTimedOutTitle =>
      'Seu treino está demorando mais que o normal.';

  @override
  String get noWorkoutTimedOutSubtitle =>
      'Ele aparece aqui assim que ficar pronto.';

  @override
  String get btnSendingRequest => 'Enviando pedido...';

  @override
  String get btnGenerating => 'Gerando...';

  @override
  String get btnRetry => 'Tentar novamente';

  @override
  String get btnCheckAgain => 'Verificar novamente';

  @override
  String get errCannotStartGeneration =>
      'Não foi possível iniciar a geração. Tente novamente.';

  @override
  String get workoutDoneToday => 'Treino concluído hoje! ✅';

  @override
  String get workoutInProgress => 'Treino em andamento';

  @override
  String get workoutStart => 'Iniciar Treino';

  @override
  String get workoutStatusInProgress => '● Em andamento';

  @override
  String workoutExerciseCount(int count, int total) {
    return '$count/$total exercícios';
  }

  @override
  String get workoutRestDay => 'Hoje é dia de descanso. 😴';

  @override
  String get btnTrainAgain => 'Treinar novamente';

  @override
  String get btnContinueWorkout => 'Continuar Treino';

  @override
  String get btnSwitchWorkout => 'Trocar treino';

  @override
  String get chooseWorkoutDayTitle => 'Qual treino você quer fazer hoje?';

  @override
  String exercisesCount(int n) {
    return '$n exercícios';
  }

  @override
  String get errLoadTodayWorkout =>
      'Não foi possível carregar o treino de hoje.';

  @override
  String get viewPlanTitle => 'Visualizar Plano';

  @override
  String get viewPlanDesc =>
      'Veja todos os dias do seu treino e os exercícios de cada um.';

  @override
  String get viewPlanButton => 'Visualizar plano';

  @override
  String get progressTitle => 'Sua Evolução';

  @override
  String get progressAddMeasures => 'Toque para inserir seu peso e altura.';

  @override
  String get progressWeight => 'Peso';

  @override
  String get progressHeight => 'Altura';

  @override
  String get progressLast90Days => 'Últimos 90 dias';

  @override
  String get updateMeasuresTitle => 'Atualizar medidas';

  @override
  String get weightLabel => 'Peso (kg)';

  @override
  String get heightLabel => 'Altura (cm)';

  @override
  String get weightHint => 'ex: 85.5';

  @override
  String get heightHint => 'ex: 175';

  @override
  String get errSaveMeasures =>
      'Não foi possível salvar as medidas. Tente novamente.';

  @override
  String get errLoadProgress => 'Não foi possível carregar sua evolução.';

  @override
  String get subscriptionAlreadyActive => 'Sua assinatura já está ativa ✅';

  @override
  String get errOpenPaymentPage =>
      'Não foi possível abrir a página de pagamento.';

  @override
  String get errGeneratePayment =>
      'Não foi possível gerar o pagamento. Tente novamente.';

  @override
  String get subscriptionRequiredTitle => 'Assinatura necessária';

  @override
  String get subscriptionRequiredDesc =>
      'Seu período grátis ou sua assinatura terminou. Assine o PersonalIA para gerar seu treino — depois de pagar, volte aqui e toque em \"Gerar meu treino\" de novo.';

  @override
  String get btnNotNow => 'Agora não';

  @override
  String get todayWorkoutTitle => 'Treino de Hoje';

  @override
  String get todayNoExercises => 'Nenhum exercício encontrado para hoje.';

  @override
  String showCompleted(int n) {
    return 'Mostrar concluídos ($n)';
  }

  @override
  String hideCompleted(int n) {
    return 'Ocultar concluídos ($n)';
  }

  @override
  String exerciseSwapped(String name) {
    return 'Trocado: $name';
  }

  @override
  String get exerciseCompleted => 'Concluído';

  @override
  String get exerciseRunning => 'Em execução';

  @override
  String exerciseSetsProgress(int done, int total) {
    return '$done/$total séries';
  }

  @override
  String get statGoal => 'Meta';

  @override
  String get statTime => 'Tempo';

  @override
  String get statLastTime => 'Último tempo';

  @override
  String get statSets => 'Séries';

  @override
  String get statReps => 'Repetições';

  @override
  String get statRest => 'Descanso';

  @override
  String get statLastWeight => 'Último peso';

  @override
  String get statLastObs => 'Última obs.';

  @override
  String get btnVideos => 'Vídeos';

  @override
  String get btnSwap => 'Trocar';

  @override
  String get btnFinishWorkout => 'Finalizar treino';

  @override
  String get finishWorkoutTitle => 'Finalizar treino?';

  @override
  String get finishWorkoutConfirmMsg =>
      'Ainda há exercícios não concluídos. Deseja finalizar assim mesmo?';

  @override
  String get btnYesFinish => 'Sim, finalizar';

  @override
  String get exerciseInProgressTitle => 'Exercício em andamento';

  @override
  String exerciseInProgressMsg(String current, String next) {
    return '\"$current\" ainda está em andamento.\n\nDeseja abandoná-lo e iniciar \"$next\"?';
  }

  @override
  String get btnYesSwap => 'Sim, trocar';

  @override
  String get makePermanentTitle => 'Tornar troca permanente?';

  @override
  String makePermanentMsg(String original, String replacement) {
    return 'Deseja substituir \"$original\" por \"$replacement\" no seu plano de treino?';
  }

  @override
  String get btnThisTimeOnly => 'Só desta vez';

  @override
  String get btnYesChangePlan => 'Sim, alterar plano';

  @override
  String get errChangePlan =>
      'Não foi possível alterar o plano. Tente novamente.';

  @override
  String get workoutFinishedTitle => 'Treino finalizado! 🎉';

  @override
  String workoutSummaryLabel(String dayName) {
    return '📊 Resumo — $dayName';
  }

  @override
  String get statDuration => '⏱️ Duração';

  @override
  String get statExercisesCompleted => '🏆 Exercícios';

  @override
  String get statVolume => '⚖️ Volume';

  @override
  String get moodQuestion => 'Como você se sentiu?';

  @override
  String get moodExhausted => 'Exausto';

  @override
  String get moodOk => 'Mais ou menos';

  @override
  String get moodGood => 'Bom / Rendimento ok';

  @override
  String get moodExcellent => 'Excelente / Superei limites!';

  @override
  String get moodCustomLabel => 'Outro emoji ou sentimento';

  @override
  String get moodCustomHelper => 'Ex: 🥵 Destruído!';

  @override
  String get btnGenerateCard => 'Gerar card do treino';

  @override
  String get btnFinishWithoutCard => 'Finalizar sem card';

  @override
  String get currentWorkoutTitle => 'Meu Treino Atual';

  @override
  String get currentWorkoutNoWorkout => 'Nenhum treino ativo.';

  @override
  String get currentWorkoutPlanLabel => 'Seu plano';

  @override
  String currentWorkoutDaysExercises(int days, int exercises) {
    return '$days dias de treino · $exercises exercícios';
  }

  @override
  String get errLoadCurrentWorkout => 'Não foi possível carregar seu treino.';

  @override
  String get dayRecovery => 'Dia de recuperação';

  @override
  String exercisesCountLabel(int n) {
    return '$n exercícios';
  }

  @override
  String exercisesCountWithCardio(int n) {
    return '$n exercícios · com cardio';
  }

  @override
  String get swapExerciseTitle => 'Trocar Exercício';

  @override
  String swapExerciseSearching(String name) {
    return 'Buscando alternativas para\n$name...';
  }

  @override
  String get swapExerciseError =>
      'Não foi possível buscar alternativas.\nTente novamente mais tarde.';

  @override
  String get swapExerciseRetry => 'Tentar novamente';

  @override
  String get swapNoAlternatives =>
      'Nenhuma alternativa encontrada para este exercício.';

  @override
  String swapAltSeries(String n) {
    return '$n séries';
  }

  @override
  String get lastWorkoutTitle => 'Histórico';

  @override
  String get reportsTitle => 'Relatórios';

  @override
  String get reportsYourReports => 'Seus relatórios';

  @override
  String get reportLoadEvolution => 'Evolução de cargas';

  @override
  String get reportLoadEvolutionDesc =>
      'Quanto suas cargas subiram em cada exercício';

  @override
  String get reportBody => 'Medidas corporais';

  @override
  String get reportBodyDesc => 'Peso, IMC e histórico de pesagens';

  @override
  String get reportVolume => 'Volume de treino';

  @override
  String get reportVolumeDesc => 'Tonelagem levantada em cada treino';

  @override
  String get reportFrequency => 'Frequência';

  @override
  String get reportFrequencyDesc => 'Calendário do mês e treinos por semana';

  @override
  String get reportPlanPdf => 'Plano de treino (PDF)';

  @override
  String get reportPlanPdfDesc => 'Todos os dias e exercícios do seu plano';

  @override
  String get errLoadWeeklySummary =>
      'Não foi possível carregar o resumo da semana.';

  @override
  String get weeklySummaryTitle => 'Resumo da semana';

  @override
  String get statWorkouts => 'Treinos';

  @override
  String get statTonnage => 'Tonelagem';

  @override
  String tonnageEvolutionUp(String pct) {
    return '📈 +$pct% de tonelagem vs. semana passada';
  }

  @override
  String tonnageEvolutionDown(String pct) {
    return '📉 $pct% de tonelagem vs. semana passada';
  }

  @override
  String get assistantCameraError =>
      'Não foi possível acessar a câmera/galeria. Verifique as permissões.';

  @override
  String get assistantTakePhoto => 'Tirar foto do aparelho';

  @override
  String get assistantChooseGallery => 'Escolher da galeria';

  @override
  String get assistantTitle => 'Tire suas dúvidas';

  @override
  String get assistantSearchMachine => 'Pesquisar máquina';

  @override
  String get assistantPhotoTooltip => 'Enviar foto de aparelho';

  @override
  String get assistantSendTooltip => 'Enviar';

  @override
  String get assistantInputHint => 'Escreva sua dúvida...';

  @override
  String get assistantVideoBtn => 'Ver vídeos de execução';

  @override
  String get editProfileTitle => 'Atualizar meu perfil';

  @override
  String get editTrainingPrefsTitle => 'Preferências de Treino';

  @override
  String get errLoadProfile => 'Não foi possível carregar seu perfil.';

  @override
  String get errLoadPrefs => 'Não foi possível carregar suas preferências.';

  @override
  String get profileFieldName => 'Nome';

  @override
  String get profileFieldGender => 'Gênero';

  @override
  String get profileFieldBirthDate => 'Data de nascimento';

  @override
  String get profileFieldWeight => 'Peso (kg)';

  @override
  String get profileFieldHeight => 'Altura (cm)';

  @override
  String get profileFieldCpf => 'CPF (opcional)';

  @override
  String get profileFieldPhone => 'Telefone';

  @override
  String get profileFieldEmail => 'Email';

  @override
  String get profileGenderMale => 'Masculino';

  @override
  String get profileGenderFemale => 'Feminino';

  @override
  String get profileSelectDate => 'Selecionar data';

  @override
  String get profilePhoneHelper =>
      'É o seu número do WhatsApp — identifica sua conta.';

  @override
  String get profileEmailHelper =>
      'O email é o seu login e não pode ser alterado aqui.';

  @override
  String get profileSaved => 'Perfil atualizado ✅';

  @override
  String get errSaveProfile => 'Não foi possível salvar. Tente novamente.';

  @override
  String get errProfileName => 'Informe seu nome.';

  @override
  String get errProfileGender => 'Selecione o gênero.';

  @override
  String get errProfileBirthDate => 'Informe sua data de nascimento.';

  @override
  String get errProfileWeight => 'Informe seu peso em kg.';

  @override
  String get errProfileHeight => 'Informe sua altura em cm.';

  @override
  String get errProfileCpf => 'O CPF tem 11 dígitos.';

  @override
  String get prefsFieldMinDuration => 'Duração mínima';

  @override
  String get prefsFieldMaxDuration => 'Duração máxima';

  @override
  String get prefsFieldDaysPerWeek => 'Dias por semana';

  @override
  String get prefsFieldFocus => 'Foco do treino';

  @override
  String get prefsFieldCardio => 'Cardio';

  @override
  String get prefsFieldGymTime => 'Horário preferido';

  @override
  String get prefsSaved => 'Preferências salvas ✅';

  @override
  String get errSavePrefs =>
      'Não foi possível salvar as preferências. Tente novamente.';

  @override
  String get errOnboardingDurationRange =>
      'A duração máxima deve ser maior ou igual à mínima.';

  @override
  String get errOnboardingChooseFocus => 'Escolha o foco do treino.';

  @override
  String get errOnboardingGymTime =>
      'Horário inválido. Use HH:MM (ex.: 18:30).';

  @override
  String get restStatSeries => 'Séries';

  @override
  String get restStatReps => 'Repetições';

  @override
  String get restStatRest => 'Descanso';

  @override
  String get restStatLastWeight => 'Último peso';

  @override
  String get restStatLastObs => 'Última obs.';

  @override
  String get restBtnVideos => 'Vídeos';

  @override
  String get restBtnSwap => 'Trocar';

  @override
  String get restFinishedTitle => 'Descanso finalizado!';

  @override
  String get restInterExerciseMsg =>
      'Ótimo trabalho! Pronto para o próximo exercício.';

  @override
  String get restBtnNextExercise => 'Próximo exercício';

  @override
  String get restSetFinishedMsg => 'Hora da próxima série!';

  @override
  String get restBtnLetsGo => 'Vamos lá!';

  @override
  String get restTimerDone => 'Pronto!';

  @override
  String get restBtnReset => 'Reiniciar';

  @override
  String get restBtnStartInterExercise => 'Iniciar descanso entre exercícios';

  @override
  String get restBtnConfirmLastSet => 'Confirmar última série';

  @override
  String get restBtnStartRest => 'Iniciar descanso';

  @override
  String get restExerciseDone => 'Exercício concluído!';

  @override
  String get restWeightLabel => 'Peso utilizado (kg)';

  @override
  String get restObservationLabel => 'Observação (opcional)';

  @override
  String get restWeightHint => 'Digite o peso para finalizar';

  @override
  String get restBtnFinishExercise => 'Finalizar exercício';

  @override
  String get restCardioLastTime => 'Último tempo';

  @override
  String get restCardioRunning => 'Em execução';

  @override
  String get restCardioTapToStart => 'Toque para iniciar';

  @override
  String get restCardioPaused => 'Pausado';

  @override
  String get restCardioDone => 'Concluído! ✅';

  @override
  String get restCardioGoalReached => 'Meta atingida! 🎉';

  @override
  String get restBtnFinishCardio => 'Finalizar cardio';

  @override
  String get restBtnCardioDone => 'Cardio concluído!';

  @override
  String get historyEmpty => 'Você ainda não finalizou nenhum treino.';

  @override
  String get errLoadHistory => 'Não foi possível carregar o histórico.';

  @override
  String get historyToday => 'Hoje';

  @override
  String get daySummaryExercises => 'exercícios';

  @override
  String get daySummarySeries => 'séries';

  @override
  String get daySummaryCardio => 'cardio';

  @override
  String get dayHintTapForVideos =>
      'Toque em um exercício para ver vídeos de execução.';

  @override
  String get dayRecoveryMsg => 'Dia de recuperação — sem exercícios.';

  @override
  String get cardTitle => 'Card do treino';

  @override
  String get cardBtnRemovePhoto => 'Remover foto';

  @override
  String get cardBtnAddPhoto => 'Adicionar foto';

  @override
  String get cardBtnChangePhoto => 'Trocar foto';

  @override
  String get cardBtnGenerating => 'Gerando...';

  @override
  String get cardBtnShare => 'Compartilhar';

  @override
  String cardShareText(String dayName) {
    return 'Treino $dayName concluído! 💪 #PersonaliA';
  }

  @override
  String get cardStatExercises => 'Exercícios';

  @override
  String get navHome => 'Início';

  @override
  String get navReports => 'Relatórios';

  @override
  String get navReferral => 'Indicar';

  @override
  String get navMenu => 'Menu';

  @override
  String get navAssistantTooltip => 'Tirar dúvidas';

  @override
  String get referralTitle => 'Indicar Amigo';

  @override
  String get referralNotEligible =>
      'Você precisa de uma assinatura ativa pra indicar amigos.';

  @override
  String get referralYourCoupon => 'Seu cupom';

  @override
  String get referralShareLink => 'Compartilhar link';

  @override
  String get errLoadReferral => 'Não foi possível carregar.';
}
