// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'PersonalIA';

  @override
  String get continuar => 'Continuar';

  @override
  String get confirmar => 'Confirmar';

  @override
  String get pular => 'Omitir';

  @override
  String get cancelar => 'Cancelar';

  @override
  String get salvar => 'Guardar';

  @override
  String get sim => 'Sí';

  @override
  String get nao => 'No';

  @override
  String get entrar => 'Iniciar sesión';

  @override
  String get ativar => 'Activar';

  @override
  String get agoraNao => 'Ahora no';

  @override
  String get voltar => 'Volver';

  @override
  String get genericError => 'No se pudo completar. Inténtalo de nuevo.';

  @override
  String get welcomeBiometricButton => 'Iniciar sesión con biometría';

  @override
  String get welcomeEmailButton => 'Iniciar sesión con email y contraseña';

  @override
  String get welcomeWhatsAppButton => 'Ya uso PersonalIA en WhatsApp';

  @override
  String get welcomeNewUserButton => 'Aún no uso PersonalIA — crear perfil';

  @override
  String get errAuthBiometricExpired =>
      'Tu biometría venció o fue desactivada. Ingresa con email y contraseña.';

  @override
  String get errAuthBiometricFailed =>
      'No se pudo iniciar sesión ahora. Inténtalo de nuevo.';

  @override
  String get loginCreateProfileTitle => 'Crear perfil';

  @override
  String get loginSyncTitle => 'Sincronizar cuenta';

  @override
  String get loginCreateProfileDesc =>
      'Ingresa tu teléfono con código de país y área para crear tu perfil y recibir un código de acceso.';

  @override
  String get loginSyncDesc =>
      'Ingresa el teléfono de tu cuenta PersonalIA en WhatsApp para recibir un código de acceso.';

  @override
  String get loginHowToReceive => '¿Cómo quieres recibir el código?';

  @override
  String loginReceiveVia(String channel) {
    return 'Recibir por $channel';
  }

  @override
  String get loginEnterCode => 'Ingresa el código';

  @override
  String loginCodeSentVia(String channel) {
    return 'Enviamos un código de 6 dígitos por $channel.';
  }

  @override
  String get loginResendCode => 'Reenviar código';

  @override
  String get loginUseOtherPhone => 'Usar otro número';

  @override
  String get errAuthCannotVerifyPhone => 'No se pudo verificar este número.';

  @override
  String get errAuthCannotSendCode =>
      'No se pudo enviar el código. Inténtalo de nuevo.';

  @override
  String get infoAuthCodeResent => 'Código reenviado.';

  @override
  String get errAuthCannotResendCode =>
      'No se pudo reenviar el código. Inténtalo de nuevo.';

  @override
  String get errAuthInvalidCode => 'Código inválido o expirado.';

  @override
  String get errAuthLoginFailed =>
      'No se pudo iniciar sesión. Inténtalo de nuevo.';

  @override
  String get passwordLoginTitle => 'Iniciar sesión con email';

  @override
  String get passwordHint => 'Contraseña';

  @override
  String get forgotPasswordLink => 'Olvidé mi contraseña';

  @override
  String get forgotPasswordTitle => 'Restablecer contraseña';

  @override
  String get forgotPasswordEnterCodeDesc =>
      'Ingresa el código que llegó a tu email y elige una nueva contraseña.';

  @override
  String get forgotPasswordEnterEmailDesc =>
      'Ingresa el email de tu cuenta. Te enviaremos un código para crear una nueva contraseña.';

  @override
  String get forgotPasswordCodeHint => 'Código de 6 dígitos';

  @override
  String get forgotPasswordNewPasswordHint =>
      'Nueva contraseña (mínimo 8 caracteres)';

  @override
  String get forgotPasswordSendCode => 'Enviar código';

  @override
  String get forgotPasswordSavePassword => 'Guardar nueva contraseña';

  @override
  String get forgotPasswordNoCode => 'No recibí el código / cambiar email';

  @override
  String forgotPasswordCodeSentFor(String email) {
    return 'Si existe una cuenta con $email, enviamos un código de 6 dígitos. Revisa también el spam.';
  }

  @override
  String get appAccessTitle => 'Acceder a la app';

  @override
  String get appAccessEmailCodeTitle => 'Código del email';

  @override
  String get appAccessPhoneCodeTitle => 'Código de WhatsApp';

  @override
  String get appAccessConfirmEmailTitle => 'Confirma tu email';

  @override
  String get appAccessPasswordTitle => 'Crea tu contraseña';

  @override
  String get appAccessSendCodeAction => 'Enviar código';

  @override
  String get appAccessSavePassword => 'Guardar contraseña e iniciar sesión';

  @override
  String get appAccessConfirmCode => 'Confirmar código';

  @override
  String get appAccessStartDesc =>
      'Ingresa el teléfono que usas en WhatsApp con PersonalIA y tu email.';

  @override
  String get appAccessPhoneHint => 'Teléfono con código de área';

  @override
  String get appAccessPhoneCodeDesc =>
      'Si hablaste con PersonalIA en WhatsApp en las últimas 24h, el código ya debería estar ahí. Si no llegó, toca \"Abrir WhatsApp\" y envía el mensaje listo — respondemos con el código.';

  @override
  String get appAccessOpenWhatsApp => 'Abrir WhatsApp';

  @override
  String get appAccessConfirmEmailDesc =>
      'Número confirmado ✅ Revisa tu email (corrígelo si es necesario) — te enviaremos un código.';

  @override
  String get appAccessPasswordDesc =>
      'Todo confirmado ✅ Ahora solo crea la contraseña para iniciar sesión con email y contraseña.';

  @override
  String get appAccessRepeatPasswordHint => 'Repetir contraseña';

  @override
  String get appAccessCodeHint => 'Código de 6 dígitos';

  @override
  String get appAccessFixEmail => '¿Email incorrecto? Corregir';

  @override
  String get appAccessNoEmail => 'No recibí el email / email incorrecto';

  @override
  String get appAccessRestart => 'Volver a empezar';

  @override
  String get appAccessInfoCodeRequested =>
      'Si existe una cuenta con estos datos, enviamos un código al email y/o WhatsApp registrados.';

  @override
  String get appAccessInfoEmailConfirmed =>
      'Email confirmado ✅ Ahora confirma tu número por WhatsApp.';

  @override
  String appAccessInfoPhoneConfirmed(String email) {
    return 'Número confirmado ✅ Ingresa el código que enviamos a $email.';
  }

  @override
  String appAccessInfoCodeSentTo(String email) {
    return 'Enviamos un código a $email.';
  }

  @override
  String get errAppAccessPhone => 'Ingresa tu teléfono con código de área.';

  @override
  String get errAppAccessEmail => 'Ingresa un email válido.';

  @override
  String get errAuthCodeLength => 'El código tiene 6 dígitos.';

  @override
  String get errAuthPasswordTooShort =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String get errAuthPasswordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get errPasswordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get biometricOfferTitle => '¿Iniciar sesión con biometría?';

  @override
  String get biometricOfferDesc =>
      'La próxima vez, ingresa con tu huella o rostro, sin escribir la contraseña.';

  @override
  String get biometricEnabled => 'Biometría activada ✅';

  @override
  String get errBiometricActivateFailed =>
      'No se pudo activar la biometría. Inténtalo de nuevo desde el Menú.';

  @override
  String get biometricToggleTitle => 'Iniciar sesión con biometría';

  @override
  String get biometricToggleSubtitle => 'Huella o rostro en vez de contraseña';

  @override
  String get errBiometricToggleFailed =>
      'No se pudo activar la biometría. Inténtalo de nuevo.';

  @override
  String get biometricConfirmPrompt =>
      'Confirma para activar el inicio de sesión biométrico';

  @override
  String get biometricLoginPrompt => 'Ingresa a PersonalIA';

  @override
  String get menuTitle => 'Menú';

  @override
  String get menuCurrentWorkout => 'Mi Entrenamiento Actual';

  @override
  String get menuHistory => 'Historial';

  @override
  String get menuSearchMachine => 'Buscar máquina';

  @override
  String get menuAskDoubt => 'Hacer una pregunta';

  @override
  String get menuUpdateProfile => 'Actualizar Mi Perfil';

  @override
  String get menuTrainingPreferences => 'Preferencias de Entrenamiento';

  @override
  String get menuAppearance => 'Apariencia';

  @override
  String get menuLanguage => 'Idioma';

  @override
  String get menuLogout => 'Cerrar sesión';

  @override
  String get appearanceSystem => 'Sistema';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceDark => 'Oscuro';

  @override
  String get errAppearanceSave =>
      'No se pudo guardar la apariencia. Inténtalo de nuevo.';

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
      'No se pudo guardar el idioma. Inténtalo de nuevo.';

  @override
  String get onboardingNameTitle => '¿Cuál es tu nombre completo?';

  @override
  String get onboardingNameHint => 'Nombre y apellido';

  @override
  String get onboardingGenderTitle => '¿Cuál es tu género?';

  @override
  String get genderMale => 'Masculino';

  @override
  String get genderFemale => 'Femenino';

  @override
  String get onboardingBirthDateTitle => '¿Cuál es tu fecha de nacimiento?';

  @override
  String get onboardingPickDate => 'Seleccionar fecha';

  @override
  String get onboardingWeightTitle => '¿Cuál es tu peso? (kg)';

  @override
  String get onboardingWeightHint => 'Ej.: 70.5';

  @override
  String get onboardingHeightTitle => '¿Cuál es tu altura? (cm)';

  @override
  String get onboardingHeightHint => 'Ej.: 175';

  @override
  String get onboardingEmailTitle => '¿Cuál es tu email?';

  @override
  String get onboardingEmailHint => 'tuemail@ejemplo.com';

  @override
  String get onboardingConfirmDataTitle => 'Revisa tus datos';

  @override
  String get onboardingCpfTitle => '¿Cuál es tu CPF?';

  @override
  String get onboardingCpfHint => '000.000.000-00';

  @override
  String get summaryName => 'Nombre';

  @override
  String get summaryCpf => 'CPF';

  @override
  String get summaryTerms => 'Términos de uso';

  @override
  String get summaryGender => 'Género';

  @override
  String get summaryBirthDate => 'Fecha de nacimiento';

  @override
  String get summaryWeight => 'Peso';

  @override
  String get summaryHeight => 'Altura';

  @override
  String get summaryEmail => 'Email';

  @override
  String get summaryAccepted => 'Aceptado';

  @override
  String get summaryNotAccepted => 'No aceptado';

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
      '¿Declaras estar físicamente apto para entrenar y aceptas nuestros términos de uso?';

  @override
  String get disclaimerCheckbox =>
      'Declaro estar físicamente apto para entrenar y acepto los términos de uso.';

  @override
  String get disclaimerReadTerms => 'Leer los términos de uso completos';

  @override
  String get onboardingCreatePasswordTitle => 'Crea una contraseña';

  @override
  String get onboardingCreatePasswordSubtitle =>
      'Así también puedes iniciar sesión con email y contraseña, sin necesitar un nuevo código cada vez.';

  @override
  String get onboardingPasswordHint => 'Contraseña (mínimo 8 caracteres)';

  @override
  String get onboardingConfirmPasswordHint => 'Confirmar contraseña';

  @override
  String get onboardingMainGoalTitle => '¿Cuál es tu objetivo principal?';

  @override
  String get goalMassGain => 'Ganancia muscular';

  @override
  String get goalWeightLoss => 'Pérdida de peso';

  @override
  String get goalStrength => 'Fuerza';

  @override
  String get goalConditioning => 'Acondicionamiento';

  @override
  String get onboardingHealthTitle => 'Salud y limitaciones';

  @override
  String get onboardingHasDiseases =>
      '¿Tienes alguna enfermedad o condición médica?';

  @override
  String get onboardingDiseasesHint => 'Ej.: Hipertensión controlada';

  @override
  String get onboardingHasLimitations => '¿Tienes alguna limitación física?';

  @override
  String get onboardingLimitationsHint => 'Ej.: Lesión en el hombro derecho';

  @override
  String get onboardingActivityLevelTitle =>
      '¿Cuál es tu nivel actual de actividad física?';

  @override
  String get activitySedentary => 'Sedentario';

  @override
  String get activityLight => 'Leve (1-3 días/semana)';

  @override
  String get activityModerate => 'Moderado (3-5 días/semana)';

  @override
  String get activityIntense => 'Intenso (6-7 días/semana)';

  @override
  String get activityAthlete => 'Atleta o trabajo físico pesado';

  @override
  String get onboardingConfirmAnamnesisTitle => 'Revisa tu anamnesis';

  @override
  String get summaryGoal => 'Objetivo';

  @override
  String get summaryDiseases => 'Enfermedades';

  @override
  String get summaryPhysicalLimitations => 'Limitaciones físicas';

  @override
  String get summaryActivityLevel => 'Nivel de actividad';

  @override
  String get onboardingDurationTitle => 'Duración del entrenamiento';

  @override
  String get onboardingDurationSubtitle => 'Entre 30 y 180 minutos.';

  @override
  String get onboardingDurationMin => 'Duración mínima (minutos)';

  @override
  String get onboardingDurationMax => 'Duración máxima (minutos)';

  @override
  String get onboardingTrainingDaysTitle =>
      '¿Cuántos días a la semana quieres entrenar?';

  @override
  String get onboardingTrainingDaysSubtitle => 'Entre 1 y 7 días.';

  @override
  String suffixDays(int count) {
    return '$count días';
  }

  @override
  String get onboardingGymTimeTitle =>
      '¿Cuál es tu horario preferido de entrenamiento?';

  @override
  String get onboardingGymTimeSubtitle => 'Opcional — puedes omitir este paso.';

  @override
  String get onboardingCardioTitle =>
      '¿Quieres incluir cardio en tu entrenamiento?';

  @override
  String get onboardingCardioInclude =>
      'Incluir cardio al final del entrenamiento';

  @override
  String get onboardingTrainingFocusTitle =>
      '¿Cuál es el enfoque de tu entrenamiento?';

  @override
  String get focusUpper => 'Tren superior';

  @override
  String get focusLower => 'Tren inferior';

  @override
  String get focusFullBody => 'Cuerpo completo';

  @override
  String freeTrialTitle(String name) {
    return '🎁 7 días gratis desbloqueados, $name!';
  }

  @override
  String get freeTrialSubtitle =>
      'Aprovecha para dejar tu entrenamiento listo y explorar la app libremente.';

  @override
  String get generateWorkoutButton => 'Generar mi entrenamiento';

  @override
  String get generatingWorkoutWait => 'Esto puede tardar unos minutos.';

  @override
  String get generatingWorkoutTimeout => 'Esto está tardando más de lo normal.';

  @override
  String get generatingWorkoutTimeoutDesc =>
      'Puedes ir al inicio — tu entrenamiento aparecerá allí cuando esté listo.';

  @override
  String get generatingWorkoutGoHome => 'Ir al inicio';

  @override
  String get thinkingStep0 => 'Analizando tu perfil...';

  @override
  String get thinkingStep1 => 'Pensando en el mejor plan...';

  @override
  String get thinkingStep2 => 'Calculando series y cargas...';

  @override
  String get thinkingStep3 => 'Eligiendo los ejercicios correctos...';

  @override
  String get thinkingStep4 => 'Ajustando el volumen de entrenamiento...';

  @override
  String get thinkingStep5 => 'Alineando con tu objetivo...';

  @override
  String get thinkingStep6 => 'Finalizando los detalles...';

  @override
  String get errOnboardingCannotSaveProfile =>
      'No se pudo guardar tu perfil. Inténtalo de nuevo.';

  @override
  String get errOnboardingCannotSaveTerms =>
      'No se pudieron aceptar los términos. Inténtalo de nuevo.';

  @override
  String get errOnboardingCannotSavePassword =>
      'No se pudo guardar tu contraseña. Inténtalo de nuevo.';

  @override
  String get errOnboardingCannotSaveAnamnesis =>
      'No se pudo guardar tu anamnesis. Inténtalo de nuevo.';

  @override
  String get errOnboardingCannotSavePrefs =>
      'No se pudieron guardar tus preferencias. Inténtalo de nuevo.';

  @override
  String get errOnboardingAnswerDisease =>
      'Responde si tienes alguna enfermedad o condición médica.';

  @override
  String get errOnboardingDescribeDisease =>
      'Describe tus enfermedades o condiciones (o vuelve y responde No).';

  @override
  String get errOnboardingAnswerLimitation =>
      'Responde si tienes alguna limitación física.';

  @override
  String get errOnboardingDescribeLimitation =>
      'Describe tus limitaciones físicas (o vuelve y responde No).';

  @override
  String get homeAppBarTitle => 'PersonalIA';

  @override
  String get subscriptionFreeTrial => 'Período de prueba activo';

  @override
  String get subscriptionActive => 'Suscripción activa';

  @override
  String get subscriptionInactive => 'Sin suscripción activa';

  @override
  String subscriptionValidUntil(String date) {
    return 'Válido hasta $date';
  }

  @override
  String subscriptionNextCharge(String date) {
    return 'Próximo cobro el $date';
  }

  @override
  String get subscriptionSignupPrompt =>
      'Suscríbete para continuar generando entrenamientos.';

  @override
  String get subscriptionButton => 'Suscribirse';

  @override
  String get dailyTipTitle => 'Consejo del día';

  @override
  String get errLoadWorkout => 'No se pudo cargar tu entrenamiento.';

  @override
  String get noWorkoutIdleTitle => 'Aún no tienes un entrenamiento activo.';

  @override
  String get noWorkoutGeneratingTitle => 'Generando tu entrenamiento...';

  @override
  String get noWorkoutGeneratingSubtitle =>
      'Esto puede tardar unos minutos. Aparecerá aquí cuando esté listo.';

  @override
  String get noWorkoutFailedTitle =>
      'No pudimos generar tu entrenamiento ahora.';

  @override
  String get noWorkoutFailedSubtitle =>
      'Nuestra IA tuvo un problema al armar el plan. Inténtalo de nuevo en unos instantes.';

  @override
  String get noWorkoutTimedOutTitle =>
      'Tu entrenamiento está tardando más de lo normal.';

  @override
  String get noWorkoutTimedOutSubtitle => 'Aparecerá aquí cuando esté listo.';

  @override
  String get btnSendingRequest => 'Enviando solicitud...';

  @override
  String get btnGenerating => 'Generando...';

  @override
  String get btnRetry => 'Intentar de nuevo';

  @override
  String get btnCheckAgain => 'Verificar de nuevo';

  @override
  String get errCannotStartGeneration =>
      'No se pudo iniciar la generación. Inténtalo de nuevo.';

  @override
  String get workoutDoneToday => '¡Entrenamiento completado hoy! ✅';

  @override
  String get workoutInProgress => 'Entrenamiento en curso';

  @override
  String get workoutStart => 'Iniciar Entrenamiento';

  @override
  String get workoutStatusInProgress => '● En curso';

  @override
  String workoutExerciseCount(int count, int total) {
    return '$count/$total ejercicios';
  }

  @override
  String get workoutRestDay => 'Hoy es día de descanso. 😴';

  @override
  String get btnTrainAgain => 'Entrenar de nuevo';

  @override
  String get btnContinueWorkout => 'Continuar Entrenamiento';

  @override
  String get btnSwitchWorkout => 'Cambiar entrenamiento';

  @override
  String get chooseWorkoutDayTitle => '¿Qué entrenamiento quieres hacer hoy?';

  @override
  String exercisesCount(int n) {
    return '$n ejercicios';
  }

  @override
  String get errLoadTodayWorkout =>
      'No se pudo cargar el entrenamiento de hoy.';

  @override
  String get viewPlanTitle => 'Ver Plan';

  @override
  String get viewPlanDesc =>
      'Ve todos los días de tu entrenamiento y los ejercicios de cada uno.';

  @override
  String get viewPlanButton => 'Ver plan';

  @override
  String get progressTitle => 'Tu Evolución';

  @override
  String get progressAddMeasures => 'Toca para ingresar tu peso y altura.';

  @override
  String get progressWeight => 'Peso';

  @override
  String get progressHeight => 'Altura';

  @override
  String get progressLast90Days => 'Últimos 90 días';

  @override
  String get updateMeasuresTitle => 'Actualizar medidas';

  @override
  String get weightLabel => 'Peso (kg)';

  @override
  String get heightLabel => 'Altura (cm)';

  @override
  String get weightHint => 'ej.: 85.5';

  @override
  String get heightHint => 'ej.: 175';

  @override
  String get errSaveMeasures =>
      'No se pudieron guardar las medidas. Inténtalo de nuevo.';

  @override
  String get errLoadProgress => 'No se pudo cargar tu evolución.';

  @override
  String get subscriptionAlreadyActive => 'Tu suscripción ya está activa ✅';

  @override
  String get errOpenPaymentPage => 'No se pudo abrir la página de pago.';

  @override
  String get errGeneratePayment =>
      'No se pudo generar el pago. Inténtalo de nuevo.';

  @override
  String get subscriptionRequiredTitle => 'Suscripción requerida';

  @override
  String get subscriptionRequiredDesc =>
      'Tu período de prueba o suscripción terminó. Suscríbete a PersonalIA para generar tu entrenamiento — después de pagar, vuelve aquí y toca \"Generar mi entrenamiento\" de nuevo.';

  @override
  String get btnNotNow => 'Ahora no';

  @override
  String get todayWorkoutTitle => 'Entrenamiento de Hoy';

  @override
  String get todayNoExercises => 'No se encontraron ejercicios para hoy.';

  @override
  String showCompleted(int n) {
    return 'Mostrar completados ($n)';
  }

  @override
  String hideCompleted(int n) {
    return 'Ocultar completados ($n)';
  }

  @override
  String exerciseSwapped(String name) {
    return 'Cambiado: $name';
  }

  @override
  String get exerciseCompleted => 'Completado';

  @override
  String get exerciseRunning => 'En ejecución';

  @override
  String exerciseSetsProgress(int done, int total) {
    return '$done/$total series';
  }

  @override
  String get statGoal => 'Meta';

  @override
  String get statTime => 'Tiempo';

  @override
  String get statLastTime => 'Último tiempo';

  @override
  String get statSets => 'Series';

  @override
  String get statReps => 'Repeticiones';

  @override
  String get statRest => 'Descanso';

  @override
  String get statLastWeight => 'Último peso';

  @override
  String get statLastObs => 'Última obs.';

  @override
  String get btnVideos => 'Videos';

  @override
  String get btnSwap => 'Cambiar';

  @override
  String get btnFinishWorkout => 'Finalizar entrenamiento';

  @override
  String get finishWorkoutTitle => '¿Finalizar entrenamiento?';

  @override
  String get finishWorkoutConfirmMsg =>
      'Todavía hay ejercicios sin completar. ¿Deseas finalizar de todas formas?';

  @override
  String get btnYesFinish => 'Sí, finalizar';

  @override
  String get exerciseInProgressTitle => 'Ejercicio en curso';

  @override
  String exerciseInProgressMsg(String current, String next) {
    return '\"$current\" todavía está en curso.\n\n¿Deseas abandonarlo e iniciar \"$next\"?';
  }

  @override
  String get btnYesSwap => 'Sí, cambiar';

  @override
  String get makePermanentTitle => '¿Hacer el cambio permanente?';

  @override
  String makePermanentMsg(String original, String replacement) {
    return '¿Deseas reemplazar \"$original\" por \"$replacement\" en tu plan de entrenamiento?';
  }

  @override
  String get btnThisTimeOnly => 'Solo esta vez';

  @override
  String get btnYesChangePlan => 'Sí, cambiar plan';

  @override
  String get errChangePlan => 'No se pudo cambiar el plan. Inténtalo de nuevo.';

  @override
  String get workoutFinishedTitle => '¡Entrenamiento finalizado! 🎉';

  @override
  String workoutSummaryLabel(String dayName) {
    return '📊 Resumen — $dayName';
  }

  @override
  String get statDuration => '⏱️ Duración';

  @override
  String get statExercisesCompleted => '🏆 Ejercicios';

  @override
  String get statVolume => '⚖️ Volumen';

  @override
  String get moodQuestion => '¿Cómo te sentiste?';

  @override
  String get moodExhausted => 'Agotado';

  @override
  String get moodOk => 'Más o menos';

  @override
  String get moodGood => 'Bien / Rendimiento ok';

  @override
  String get moodExcellent => '¡Excelente / Superé mis límites!';

  @override
  String get moodCustomLabel => 'Otro emoji o sentimiento';

  @override
  String get moodCustomHelper => 'Ej.: 🥵 ¡Destruido!';

  @override
  String get btnGenerateCard => 'Generar tarjeta del entrenamiento';

  @override
  String get btnFinishWithoutCard => 'Finalizar sin tarjeta';

  @override
  String get currentWorkoutTitle => 'Mi Entrenamiento Actual';

  @override
  String get currentWorkoutNoWorkout => 'Ningún entrenamiento activo.';

  @override
  String get currentWorkoutPlanLabel => 'Tu plan';

  @override
  String currentWorkoutDaysExercises(int days, int exercises) {
    return '$days días de entrenamiento · $exercises ejercicios';
  }

  @override
  String get errLoadCurrentWorkout => 'No se pudo cargar tu entrenamiento.';

  @override
  String get dayRecovery => 'Día de recuperación';

  @override
  String exercisesCountLabel(int n) {
    return '$n ejercicios';
  }

  @override
  String exercisesCountWithCardio(int n) {
    return '$n ejercicios · con cardio';
  }

  @override
  String get swapExerciseTitle => 'Cambiar Ejercicio';

  @override
  String swapExerciseSearching(String name) {
    return 'Buscando alternativas para\n$name...';
  }

  @override
  String get swapExerciseError =>
      'No se pudieron buscar alternativas.\nInténtalo más tarde.';

  @override
  String get swapExerciseRetry => 'Intentar de nuevo';

  @override
  String get swapNoAlternatives =>
      'No se encontraron alternativas para este ejercicio.';

  @override
  String swapAltSeries(String n) {
    return '$n series';
  }

  @override
  String get lastWorkoutTitle => 'Historial';

  @override
  String get reportsTitle => 'Informes';

  @override
  String get reportsYourReports => 'Tus informes';

  @override
  String get reportLoadEvolution => 'Evolución de cargas';

  @override
  String get reportLoadEvolutionDesc =>
      'Cuánto aumentaron tus cargas en cada ejercicio';

  @override
  String get reportBody => 'Medidas corporales';

  @override
  String get reportBodyDesc => 'Peso, IMC e historial de pesajes';

  @override
  String get reportVolume => 'Volumen de entrenamiento';

  @override
  String get reportVolumeDesc => 'Tonelaje levantado en cada entrenamiento';

  @override
  String get reportFrequency => 'Frecuencia';

  @override
  String get reportFrequencyDesc =>
      'Calendario del mes y entrenamientos por semana';

  @override
  String get reportPlanPdf => 'Plan de entrenamiento (PDF)';

  @override
  String get reportPlanPdfDesc => 'Todos los días y ejercicios de tu plan';

  @override
  String get errLoadWeeklySummary =>
      'No se pudo cargar el resumen de la semana.';

  @override
  String get weeklySummaryTitle => 'Resumen de la semana';

  @override
  String get statWorkouts => 'Entrenamientos';

  @override
  String get statTonnage => 'Tonelaje';

  @override
  String tonnageEvolutionUp(String pct) {
    return '📈 +$pct% de tonelaje vs. semana pasada';
  }

  @override
  String tonnageEvolutionDown(String pct) {
    return '📉 $pct% de tonelaje vs. semana pasada';
  }

  @override
  String get assistantCameraError =>
      'No se pudo acceder a la cámara/galería. Verifica los permisos.';

  @override
  String get assistantTakePhoto => 'Tomar foto del aparato';

  @override
  String get assistantChooseGallery => 'Elegir de la galería';

  @override
  String get assistantTitle => 'Haz tus preguntas';

  @override
  String get assistantSearchMachine => 'Buscar máquina';

  @override
  String get assistantPhotoTooltip => 'Enviar foto del equipo';

  @override
  String get assistantSendTooltip => 'Enviar';

  @override
  String get assistantInputHint => 'Escribe tu pregunta...';

  @override
  String get assistantVideoBtn => 'Ver videos de ejecución';

  @override
  String get editProfileTitle => 'Actualizar mi perfil';

  @override
  String get editTrainingPrefsTitle => 'Preferencias de Entrenamiento';

  @override
  String get errLoadProfile => 'No se pudo cargar tu perfil.';

  @override
  String get errLoadPrefs => 'No se pudieron cargar tus preferencias.';

  @override
  String get profileFieldName => 'Nombre';

  @override
  String get profileFieldGender => 'Género';

  @override
  String get profileFieldBirthDate => 'Fecha de nacimiento';

  @override
  String get profileFieldWeight => 'Peso (kg)';

  @override
  String get profileFieldHeight => 'Altura (cm)';

  @override
  String get profileFieldCpf => 'CPF (opcional)';

  @override
  String get profileFieldPhone => 'Teléfono';

  @override
  String get profileFieldEmail => 'Email';

  @override
  String get profileGenderMale => 'Masculino';

  @override
  String get profileGenderFemale => 'Femenino';

  @override
  String get profileSelectDate => 'Seleccionar fecha';

  @override
  String get profilePhoneHelper =>
      'Es tu número de WhatsApp — identifica tu cuenta.';

  @override
  String get profileEmailHelper =>
      'El email es tu login y no se puede cambiar aquí.';

  @override
  String get profileSaved => 'Perfil actualizado ✅';

  @override
  String get errSaveProfile => 'No se pudo guardar. Inténtalo de nuevo.';

  @override
  String get errProfileName => 'Ingresa tu nombre.';

  @override
  String get errProfileGender => 'Selecciona tu género.';

  @override
  String get errProfileBirthDate => 'Ingresa tu fecha de nacimiento.';

  @override
  String get errProfileWeight => 'Ingresa tu peso en kg.';

  @override
  String get errProfileHeight => 'Ingresa tu altura en cm.';

  @override
  String get errProfileCpf => 'El CPF tiene 11 dígitos.';

  @override
  String get prefsFieldMinDuration => 'Duración mínima';

  @override
  String get prefsFieldMaxDuration => 'Duración máxima';

  @override
  String get prefsFieldDaysPerWeek => 'Días por semana';

  @override
  String get prefsFieldFocus => 'Foco del entrenamiento';

  @override
  String get prefsFieldCardio => 'Cardio';

  @override
  String get prefsFieldGymTime => 'Horario preferido';

  @override
  String get prefsSaved => 'Preferencias guardadas ✅';

  @override
  String get errSavePrefs =>
      'No se pudieron guardar las preferencias. Inténtalo de nuevo.';

  @override
  String get errOnboardingDurationRange =>
      'La duración máxima debe ser mayor o igual a la mínima.';

  @override
  String get errOnboardingChooseFocus => 'Elige el enfoque del entrenamiento.';

  @override
  String get errOnboardingGymTime => 'Hora inválida. Usa HH:MM (ej.: 18:30).';

  @override
  String get restStatSeries => 'Series';

  @override
  String get restStatReps => 'Repeticiones';

  @override
  String get restStatRest => 'Descanso';

  @override
  String get restStatLastWeight => 'Último peso';

  @override
  String get restStatLastObs => 'Última obs.';

  @override
  String get restBtnVideos => 'Videos';

  @override
  String get restBtnSwap => 'Cambiar';

  @override
  String get restFinishedTitle => '¡Descanso terminado!';

  @override
  String get restInterExerciseMsg =>
      '¡Excelente! Listo para el siguiente ejercicio.';

  @override
  String get restBtnNextExercise => 'Siguiente ejercicio';

  @override
  String get restSetFinishedMsg => '¡Hora de la siguiente serie!';

  @override
  String get restBtnLetsGo => '¡Vamos!';

  @override
  String get restTimerDone => '¡Listo!';

  @override
  String get restBtnReset => 'Reiniciar';

  @override
  String get restBtnStartInterExercise => 'Iniciar descanso entre ejercicios';

  @override
  String get restBtnConfirmLastSet => 'Confirmar última serie';

  @override
  String get restBtnStartRest => 'Iniciar descanso';

  @override
  String get restExerciseDone => '¡Ejercicio completado!';

  @override
  String get restWeightLabel => 'Peso utilizado (kg)';

  @override
  String get restObservationLabel => 'Observación (opcional)';

  @override
  String get restWeightHint => 'Ingresa el peso para finalizar';

  @override
  String get restBtnFinishExercise => 'Finalizar ejercicio';

  @override
  String get restCardioLastTime => 'Último tiempo';

  @override
  String get restCardioRunning => 'En ejecución';

  @override
  String get restCardioTapToStart => 'Toca para iniciar';

  @override
  String get restCardioPaused => 'Pausado';

  @override
  String get restCardioDone => '¡Completado! ✅';

  @override
  String get restCardioGoalReached => '¡Meta alcanzada! 🎉';

  @override
  String get restBtnFinishCardio => 'Finalizar cardio';

  @override
  String get restBtnCardioDone => '¡Cardio completado!';

  @override
  String get historyEmpty => 'Aún no has finalizado ningún entrenamiento.';

  @override
  String get errLoadHistory => 'No se pudo cargar el historial.';

  @override
  String get historyToday => 'Hoy';

  @override
  String get daySummaryExercises => 'ejercicios';

  @override
  String get daySummarySeries => 'series';

  @override
  String get daySummaryCardio => 'cardio';

  @override
  String get dayHintTapForVideos =>
      'Toca un ejercicio para ver videos de ejecución.';

  @override
  String get dayRecoveryMsg => 'Día de recuperación — sin ejercicios.';

  @override
  String get cardTitle => 'Tarjeta de entrenamiento';

  @override
  String get cardBtnRemovePhoto => 'Quitar foto';

  @override
  String get cardBtnAddPhoto => 'Agregar foto';

  @override
  String get cardBtnChangePhoto => 'Cambiar foto';

  @override
  String get cardBtnGenerating => 'Generando...';

  @override
  String get cardBtnShare => 'Compartir';

  @override
  String cardShareText(String dayName) {
    return '¡Entrenamiento $dayName completado! 💪 #PersonaliA';
  }

  @override
  String get cardStatExercises => 'Ejercicios';

  @override
  String get navHome => 'Inicio';

  @override
  String get navReports => 'Informes';

  @override
  String get navReferral => 'Referir';

  @override
  String get navMenu => 'Menú';

  @override
  String get navAssistantTooltip => 'Hacer preguntas';

  @override
  String get referralTitle => 'Referir un Amigo';

  @override
  String get referralNotEligible =>
      'Necesitas una suscripción activa para referir amigos.';

  @override
  String get referralYourCoupon => 'Tu cupón';

  @override
  String get referralShareLink => 'Compartir enlace';

  @override
  String get errLoadReferral => 'No se pudo cargar.';
}
