// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PersonalIA';

  @override
  String get continuar => 'Continue';

  @override
  String get confirmar => 'Confirm';

  @override
  String get pular => 'Skip';

  @override
  String get cancelar => 'Cancel';

  @override
  String get salvar => 'Save';

  @override
  String get sim => 'Yes';

  @override
  String get nao => 'No';

  @override
  String get entrar => 'Sign in';

  @override
  String get ativar => 'Activate';

  @override
  String get agoraNao => 'Not now';

  @override
  String get voltar => 'Back';

  @override
  String get genericError => 'Could not complete. Please try again.';

  @override
  String get welcomeBiometricButton => 'Sign in with biometrics';

  @override
  String get welcomeEmailButton => 'Sign in with email and password';

  @override
  String get welcomeWhatsAppButton => 'I already use PersonalIA on WhatsApp';

  @override
  String get welcomeNewUserButton =>
      'I don\'t use PersonalIA yet — create profile';

  @override
  String get errAuthBiometricExpired =>
      'Your biometrics expired or were disabled. Sign in with email and password.';

  @override
  String get errAuthBiometricFailed =>
      'Could not sign in right now. Please try again.';

  @override
  String get loginCreateProfileTitle => 'Create profile';

  @override
  String get loginSyncTitle => 'Sync account';

  @override
  String get loginCreateProfileDesc =>
      'Enter your phone number with country code and area code to create your profile and receive an access code.';

  @override
  String get signupTitle => 'Create account';

  @override
  String get signupEmailDesc =>
      'Enter your email. We\'ll send a 6-digit code to confirm it\'s yours.';

  @override
  String get signupPasswordDesc =>
      'Email confirmed ✅ Now create your password — you\'ll sign in to the app with email and password.';

  @override
  String get signupPhoneOptionalHint =>
      'Phone number with area code (optional)';

  @override
  String get signupPhoneOptionalHelp =>
      'Optional. We\'ll confirm it by SMS — used only to contact you, not to sign in.';

  @override
  String get signupCreateAccount => 'Create account';

  @override
  String get signupGoToLogin => 'I already have an account — sign in';

  @override
  String get signupPhoneCodeDesc =>
      'Enter the code we sent by SMS to confirm your phone number.';

  @override
  String signupPhoneCodeSentTo(String phone) {
    return 'We sent an SMS code to $phone. Enter it to confirm your phone number.';
  }

  @override
  String get signupPhoneSkip => 'Skip for now';

  @override
  String get errSignupPhoneInvalid =>
      'Invalid phone number. Enter area code + number.';

  @override
  String get signupLinkAccountDesc =>
      'Email confirmed ✅ We found your WhatsApp account with this email. Create your password and confirm your WhatsApp phone number to bring your workout history.';

  @override
  String get signupLinkPhoneHint =>
      'Your WhatsApp phone number, with area code';

  @override
  String get signupLinkPhoneHelp =>
      'We\'ll confirm by SMS that the number is yours.';

  @override
  String get errSignupPhoneRequired =>
      'Enter your WhatsApp phone number to continue.';

  @override
  String get loginSyncDesc =>
      'Enter the phone number of your PersonalIA WhatsApp account to receive an access code.';

  @override
  String get loginHowToReceive => 'How do you want to receive the code?';

  @override
  String loginReceiveVia(String channel) {
    return 'Receive via $channel';
  }

  @override
  String get loginEnterCode => 'Enter the code';

  @override
  String loginCodeSentVia(String channel) {
    return 'We sent a 6-digit code via $channel.';
  }

  @override
  String get loginResendCode => 'Resend code';

  @override
  String get loginUseOtherPhone => 'Use another number';

  @override
  String get errAuthCannotVerifyPhone => 'Could not verify this number.';

  @override
  String get errAuthCannotSendCode =>
      'Could not send the code. Please try again.';

  @override
  String get infoAuthCodeResent => 'Code resent.';

  @override
  String get errAuthCannotResendCode =>
      'Could not resend the code. Please try again.';

  @override
  String get errAuthInvalidCode => 'Invalid or expired code.';

  @override
  String get errAuthLoginFailed => 'Could not sign in. Please try again.';

  @override
  String get passwordLoginTitle => 'Sign in with email';

  @override
  String get passwordHint => 'Password';

  @override
  String get forgotPasswordLink => 'Forgot password';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordEnterCodeDesc =>
      'Enter the code you received by email and choose a new password.';

  @override
  String get forgotPasswordEnterEmailDesc =>
      'Enter your account email. We\'ll send you a code to create a new password.';

  @override
  String get forgotPasswordCodeHint => '6-digit code';

  @override
  String get forgotPasswordNewPasswordHint =>
      'New password (at least 8 characters)';

  @override
  String get forgotPasswordSendCode => 'Send code';

  @override
  String get forgotPasswordSavePassword => 'Save new password';

  @override
  String get forgotPasswordNoCode => 'Didn\'t receive the code / change email';

  @override
  String forgotPasswordCodeSentFor(String email) {
    return 'If an account with $email exists, we sent a 6-digit code. Also check your spam folder.';
  }

  @override
  String get appAccessTitle => 'Access the app';

  @override
  String get appAccessEmailCodeTitle => 'Email code';

  @override
  String get appAccessPhoneCodeTitle => 'WhatsApp code';

  @override
  String get appAccessConfirmEmailTitle => 'Confirm your email';

  @override
  String get appAccessPasswordTitle => 'Create your password';

  @override
  String get appAccessSendCodeAction => 'Send code';

  @override
  String get appAccessSavePassword => 'Save password and sign in';

  @override
  String get appAccessConfirmCode => 'Confirm code';

  @override
  String get appAccessStartDesc =>
      'Enter the phone number you use on WhatsApp with PersonalIA and your email.';

  @override
  String get appAccessPhoneHint => 'Phone with area code';

  @override
  String get appAccessPhoneCodeDesc =>
      'If you talked to PersonalIA on WhatsApp in the last 24h, the code should already be there. If not, tap \"Open WhatsApp\" and send the ready message — we\'ll reply with the code.';

  @override
  String get appAccessOpenWhatsApp => 'Open WhatsApp';

  @override
  String get appAccessConfirmEmailDesc =>
      'Number confirmed ✅ Check your email (correct it if needed) — we\'ll send a code to it.';

  @override
  String get appAccessPasswordDesc =>
      'All confirmed ✅ Now just create a password to sign in with email and password.';

  @override
  String get appAccessRepeatPasswordHint => 'Repeat password';

  @override
  String get appAccessCodeHint => '6-digit code';

  @override
  String get appAccessFixEmail => 'Wrong email? Fix it';

  @override
  String get appAccessNoEmail => 'Didn\'t receive the email / wrong email';

  @override
  String get appAccessRestart => 'Start over';

  @override
  String get appAccessInfoCodeRequested =>
      'If an account with these details exists, we sent a code to the registered email and/or WhatsApp.';

  @override
  String get appAccessInfoEmailConfirmed =>
      'Email confirmed ✅ Now confirm your number via WhatsApp.';

  @override
  String appAccessInfoPhoneConfirmed(String email) {
    return 'Number confirmed ✅ Enter the code we sent to $email.';
  }

  @override
  String appAccessInfoCodeSentTo(String email) {
    return 'We sent a code to $email.';
  }

  @override
  String get errAppAccessPhone => 'Enter your phone number with area code.';

  @override
  String get errAppAccessEmail => 'Enter a valid email address.';

  @override
  String get errAuthCodeLength => 'The code is 6 digits.';

  @override
  String get errAuthPasswordTooShort =>
      'Password must be at least 8 characters.';

  @override
  String get errAuthPasswordMismatch => 'Passwords do not match.';

  @override
  String get errPasswordMismatch => 'Passwords do not match.';

  @override
  String get biometricOfferTitle => 'Sign in with biometrics?';

  @override
  String get biometricOfferDesc =>
      'Next time, sign in with your fingerprint or face, without typing your password.';

  @override
  String get biometricEnabled => 'Biometrics enabled ✅';

  @override
  String get errBiometricActivateFailed =>
      'Could not activate biometrics. Try again from the Menu.';

  @override
  String get biometricToggleTitle => 'Sign in with biometrics';

  @override
  String get biometricToggleSubtitle =>
      'Fingerprint or face instead of password';

  @override
  String get errBiometricToggleFailed =>
      'Could not activate biometrics. Please try again.';

  @override
  String get biometricConfirmPrompt => 'Confirm to activate biometric login';

  @override
  String get biometricLoginPrompt => 'Sign in to PersonalIA';

  @override
  String get menuTitle => 'Menu';

  @override
  String get menuCurrentWorkout => 'My Current Workout';

  @override
  String get menuHistory => 'History';

  @override
  String get menuSearchMachine => 'Search machine';

  @override
  String get menuAskDoubt => 'Ask a question';

  @override
  String get menuUpdateProfile => 'Update My Profile';

  @override
  String get menuTrainingPreferences => 'Training Preferences';

  @override
  String get menuAppearance => 'Appearance';

  @override
  String get menuLanguage => 'Language';

  @override
  String get menuLogout => 'Sign out';

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get errAppearanceSave =>
      'Could not save appearance. Please try again.';

  @override
  String get langSystem => 'System';

  @override
  String get langPortuguese => 'Português';

  @override
  String get langEnglish => 'English';

  @override
  String get langSpanish => 'Español';

  @override
  String get errLanguageSave => 'Could not save language. Please try again.';

  @override
  String get onboardingNameTitle => 'What is your full name?';

  @override
  String get onboardingNameHint => 'First and last name';

  @override
  String get onboardingGenderTitle => 'What is your gender?';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get onboardingBirthDateTitle => 'What is your date of birth?';

  @override
  String get onboardingPickDate => 'Select date';

  @override
  String get onboardingWeightTitle => 'What is your weight? (kg)';

  @override
  String get onboardingWeightHint => 'E.g.: 70.5';

  @override
  String get onboardingHeightTitle => 'What is your height? (cm)';

  @override
  String get onboardingHeightHint => 'E.g.: 175';

  @override
  String get onboardingEmailTitle => 'What is your email?';

  @override
  String get onboardingEmailHint => 'youremail@example.com';

  @override
  String get onboardingConfirmDataTitle => 'Review your details';

  @override
  String get onboardingCpfTitle => 'What is your CPF?';

  @override
  String get onboardingCpfHint => '000.000.000-00';

  @override
  String get summaryName => 'Name';

  @override
  String get summaryCpf => 'CPF';

  @override
  String get summaryTerms => 'Terms of use';

  @override
  String get summaryGender => 'Gender';

  @override
  String get summaryBirthDate => 'Date of birth';

  @override
  String get summaryWeight => 'Weight';

  @override
  String get summaryHeight => 'Height';

  @override
  String get summaryEmail => 'Email';

  @override
  String get summaryAccepted => 'Accepted';

  @override
  String get summaryNotAccepted => 'Not accepted';

  @override
  String unitKg(String weight) {
    return '$weight kg';
  }

  @override
  String unitCm(String height) {
    return '$height cm';
  }

  @override
  String get disclaimerTitle => 'Before you continue';

  @override
  String get disclaimerSubtitle =>
      'Do you declare you are physically fit to train and accept our terms of use?';

  @override
  String get disclaimerCheckbox =>
      'I declare I am physically fit to train and accept the terms of use.';

  @override
  String get disclaimerReadTerms => 'Read the full terms of use';

  @override
  String get onboardingCreatePasswordTitle => 'Create a password';

  @override
  String get onboardingCreatePasswordSubtitle =>
      'This way you can also sign in with email and password, without needing a new code every time.';

  @override
  String get onboardingPasswordHint => 'Password (at least 8 characters)';

  @override
  String get onboardingConfirmPasswordHint => 'Confirm password';

  @override
  String get onboardingMainGoalTitle => 'What is your main goal?';

  @override
  String get goalMassGain => 'Muscle gain';

  @override
  String get goalWeightLoss => 'Weight loss';

  @override
  String get goalStrength => 'Strength';

  @override
  String get goalConditioning => 'Conditioning';

  @override
  String get onboardingHealthTitle => 'Health & limitations';

  @override
  String get onboardingHasDiseases =>
      'Do you have any medical condition or disease?';

  @override
  String get onboardingDiseasesHint => 'E.g.: Controlled hypertension';

  @override
  String get onboardingHasLimitations =>
      'Do you have any physical limitations?';

  @override
  String get onboardingLimitationsHint => 'E.g.: Right shoulder injury';

  @override
  String get onboardingActivityLevelTitle =>
      'What is your current physical activity level?';

  @override
  String get activitySedentary => 'Sedentary';

  @override
  String get activityLight => 'Light (1-3 days/week)';

  @override
  String get activityModerate => 'Moderate (3-5 days/week)';

  @override
  String get activityIntense => 'Intense (6-7 days/week)';

  @override
  String get activityAthlete => 'Athlete or heavy physical work';

  @override
  String get onboardingConfirmAnamnesisTitle => 'Review your anamnesis';

  @override
  String get summaryGoal => 'Goal';

  @override
  String get summaryDiseases => 'Conditions';

  @override
  String get summaryPhysicalLimitations => 'Physical limitations';

  @override
  String get summaryActivityLevel => 'Activity level';

  @override
  String get onboardingDurationTitle => 'Workout duration';

  @override
  String get onboardingDurationSubtitle => 'Between 30 and 180 minutes.';

  @override
  String get onboardingDurationMin => 'Minimum duration (minutes)';

  @override
  String get onboardingDurationMax => 'Maximum duration (minutes)';

  @override
  String get onboardingTrainingDaysTitle =>
      'How many days a week do you want to train?';

  @override
  String get onboardingTrainingDaysSubtitle => 'Between 1 and 7 days.';

  @override
  String suffixDays(int count) {
    return '$count days';
  }

  @override
  String get onboardingGymTimeTitle => 'What is your preferred workout time?';

  @override
  String get onboardingGymTimeSubtitle => 'Optional — you can skip this step.';

  @override
  String get onboardingCardioTitle =>
      'Do you want to include cardio in your workout?';

  @override
  String get onboardingCardioInclude =>
      'Include cardio at the end of the workout';

  @override
  String get onboardingTrainingFocusTitle => 'What is your training focus?';

  @override
  String get focusUpper => 'Upper body';

  @override
  String get focusLower => 'Lower body';

  @override
  String get focusFullBody => 'Full body';

  @override
  String freeTrialTitle(String name) {
    return '🎁 7 free days unlocked, $name!';
  }

  @override
  String get freeTrialSubtitle =>
      'Take the time to get your workout ready and explore the app freely.';

  @override
  String get generateWorkoutButton => 'Generate my workout';

  @override
  String get generatingWorkoutWait => 'This may take a few minutes.';

  @override
  String get generatingWorkoutTimeout => 'This is taking longer than usual.';

  @override
  String get generatingWorkoutTimeoutDesc =>
      'You can go to the home screen — your workout will appear there as soon as it\'s ready.';

  @override
  String get generatingWorkoutGoHome => 'Go to home';

  @override
  String get thinkingStep0 => 'Analyzing your profile...';

  @override
  String get thinkingStep1 => 'Thinking about the best plan...';

  @override
  String get thinkingStep2 => 'Calculating sets and loads...';

  @override
  String get thinkingStep3 => 'Choosing the right exercises...';

  @override
  String get thinkingStep4 => 'Adjusting training volume...';

  @override
  String get thinkingStep5 => 'Aligning with your goal...';

  @override
  String get thinkingStep6 => 'Finalizing the details...';

  @override
  String get errOnboardingCannotSaveProfile =>
      'Could not save your profile. Please try again.';

  @override
  String get errOnboardingCannotSaveTerms =>
      'Could not accept the terms. Please try again.';

  @override
  String get errOnboardingCannotSavePassword =>
      'Could not save your password. Please try again.';

  @override
  String get errOnboardingCannotSaveAnamnesis =>
      'Could not save your anamnesis. Please try again.';

  @override
  String get errOnboardingCannotSavePrefs =>
      'Could not save your preferences. Please try again.';

  @override
  String get errOnboardingAnswerDisease =>
      'Answer whether you have any medical condition or disease.';

  @override
  String get errOnboardingDescribeDisease =>
      'Describe your conditions (or go back and answer No).';

  @override
  String get errOnboardingAnswerLimitation =>
      'Answer whether you have any physical limitations.';

  @override
  String get errOnboardingDescribeLimitation =>
      'Describe your physical limitations (or go back and answer No).';

  @override
  String get homeAppBarTitle => 'PersonalIA';

  @override
  String get subscriptionFreeTrial => 'Free trial active';

  @override
  String get subscriptionActive => 'Subscription active';

  @override
  String get subscriptionInactive => 'No active subscription';

  @override
  String subscriptionValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String subscriptionNextCharge(String date) {
    return 'Next charge on $date';
  }

  @override
  String get subscriptionSignupPrompt =>
      'Choose your plan in your device store.';

  @override
  String get subscriptionButton => 'Subscribe';

  @override
  String get dailyTipTitle => 'Tip of the day';

  @override
  String get errLoadWorkout => 'Could not load your workout.';

  @override
  String get noWorkoutIdleTitle => 'You don\'t have an active workout yet.';

  @override
  String get noWorkoutGeneratingTitle => 'Generating your workout...';

  @override
  String get noWorkoutGeneratingSubtitle =>
      'This may take a few minutes. It will appear here as soon as it\'s ready.';

  @override
  String get noWorkoutFailedTitle =>
      'We couldn\'t generate your workout right now.';

  @override
  String get noWorkoutFailedSubtitle =>
      'Our AI had a problem building the plan. Try again in a moment.';

  @override
  String get noWorkoutTimedOutTitle =>
      'Your workout is taking longer than usual.';

  @override
  String get noWorkoutTimedOutSubtitle =>
      'It will appear here as soon as it\'s ready.';

  @override
  String get btnSendingRequest => 'Sending request...';

  @override
  String get btnGenerating => 'Generating...';

  @override
  String get btnRetry => 'Try again';

  @override
  String get btnCheckAgain => 'Check again';

  @override
  String get errCannotStartGeneration =>
      'Could not start generation. Please try again.';

  @override
  String get workoutDoneToday => 'Workout completed today! ✅';

  @override
  String get workoutInProgress => 'Workout in progress';

  @override
  String get workoutStart => 'Start Workout';

  @override
  String get workoutStatusInProgress => '● In progress';

  @override
  String workoutExerciseCount(int count, int total) {
    return '$count/$total exercises';
  }

  @override
  String get workoutRestDay => 'Today is a rest day. 😴';

  @override
  String get btnTrainAgain => 'Train again';

  @override
  String get btnContinueWorkout => 'Continue Workout';

  @override
  String get btnSwitchWorkout => 'Switch workout';

  @override
  String get chooseWorkoutDayTitle => 'Which workout do you want to do today?';

  @override
  String exercisesCount(int n) {
    return '$n exercises';
  }

  @override
  String get errLoadTodayWorkout => 'Could not load today\'s workout.';

  @override
  String get viewPlanTitle => 'View Plan';

  @override
  String get viewPlanDesc =>
      'See all days of your workout and the exercises for each.';

  @override
  String get viewPlanButton => 'View plan';

  @override
  String get progressTitle => 'Your Progress';

  @override
  String get progressAddMeasures => 'Tap to enter your weight and height.';

  @override
  String get progressWeight => 'Weight';

  @override
  String get progressHeight => 'Height';

  @override
  String get progressLast90Days => 'Last 90 days';

  @override
  String get updateMeasuresTitle => 'Update measurements';

  @override
  String get weightLabel => 'Weight (kg)';

  @override
  String get heightLabel => 'Height (cm)';

  @override
  String get weightHint => 'e.g.: 85.5';

  @override
  String get heightHint => 'e.g.: 175';

  @override
  String get errSaveMeasures =>
      'Could not save measurements. Please try again.';

  @override
  String get errLoadProgress => 'Could not load your progress.';

  @override
  String get subscriptionAlreadyActive =>
      'Your subscription is already active ✅';

  @override
  String get errOpenPaymentPage => 'Could not open payment page.';

  @override
  String get errGeneratePayment =>
      'Could not generate payment. Please try again.';

  @override
  String get subscriptionRequiredTitle => 'Subscription required';

  @override
  String get subscriptionRequiredDesc =>
      'Your free trial or subscription has ended. Subscribe to PersonalIA to generate your workout — after paying, come back here and tap \"Generate my workout\" again.';

  @override
  String get btnNotNow => 'Not now';

  @override
  String get todayWorkoutTitle => 'Today\'s Workout';

  @override
  String get todayNoExercises => 'No exercises found for today.';

  @override
  String showCompleted(int n) {
    return 'Show completed ($n)';
  }

  @override
  String hideCompleted(int n) {
    return 'Hide completed ($n)';
  }

  @override
  String exerciseSwapped(String name) {
    return 'Swapped: $name';
  }

  @override
  String get exerciseCompleted => 'Completed';

  @override
  String get exerciseRunning => 'In progress';

  @override
  String exerciseSetsProgress(int done, int total) {
    return '$done/$total sets';
  }

  @override
  String get statGoal => 'Goal';

  @override
  String get statTime => 'Time';

  @override
  String get statLastTime => 'Last time';

  @override
  String get statSets => 'Sets';

  @override
  String get statReps => 'Reps';

  @override
  String get statRest => 'Rest';

  @override
  String get statLastWeight => 'Last weight';

  @override
  String get statLastObs => 'Last note';

  @override
  String get btnVideos => 'Videos';

  @override
  String get btnSwap => 'Swap';

  @override
  String get btnFinishWorkout => 'Finish workout';

  @override
  String get finishWorkoutTitle => 'Finish workout?';

  @override
  String get finishWorkoutConfirmMsg =>
      'There are still incomplete exercises. Do you want to finish anyway?';

  @override
  String get btnYesFinish => 'Yes, finish';

  @override
  String get exerciseInProgressTitle => 'Exercise in progress';

  @override
  String exerciseInProgressMsg(String current, String next) {
    return '\"$current\" is still in progress.\n\nDo you want to abandon it and start \"$next\"?';
  }

  @override
  String get btnYesSwap => 'Yes, swap';

  @override
  String get makePermanentTitle => 'Make swap permanent?';

  @override
  String makePermanentMsg(String original, String replacement) {
    return 'Do you want to replace \"$original\" with \"$replacement\" in your workout plan?';
  }

  @override
  String get btnThisTimeOnly => 'This time only';

  @override
  String get btnYesChangePlan => 'Yes, change plan';

  @override
  String get errChangePlan => 'Could not change the plan. Please try again.';

  @override
  String get workoutFinishedTitle => 'Workout finished! 🎉';

  @override
  String workoutSummaryLabel(String dayName) {
    return '📊 Summary — $dayName';
  }

  @override
  String get statDuration => '⏱️ Duration';

  @override
  String get statExercisesCompleted => '🏆 Exercises';

  @override
  String get statVolume => '⚖️ Volume';

  @override
  String get moodQuestion => 'How did you feel?';

  @override
  String get moodExhausted => 'Exhausted';

  @override
  String get moodOk => 'So-so';

  @override
  String get moodGood => 'Good / Performance ok';

  @override
  String get moodExcellent => 'Excellent / Surpassed my limits!';

  @override
  String get moodCustomLabel => 'Other emoji or feeling';

  @override
  String get moodCustomHelper => 'E.g.: 🥵 Destroyed!';

  @override
  String get btnGenerateCard => 'Generate workout card';

  @override
  String get btnFinishWithoutCard => 'Finish without card';

  @override
  String get currentWorkoutTitle => 'My Current Workout';

  @override
  String get currentWorkoutNoWorkout => 'No active workout.';

  @override
  String get currentWorkoutPlanLabel => 'Your plan';

  @override
  String currentWorkoutDaysExercises(int days, int exercises) {
    return '$days training days · $exercises exercises';
  }

  @override
  String get errLoadCurrentWorkout => 'Could not load your workout.';

  @override
  String get dayRecovery => 'Recovery day';

  @override
  String exercisesCountLabel(int n) {
    return '$n exercises';
  }

  @override
  String exercisesCountWithCardio(int n) {
    return '$n exercises · with cardio';
  }

  @override
  String get swapExerciseTitle => 'Swap Exercise';

  @override
  String swapExerciseSearching(String name) {
    return 'Looking for alternatives for\n$name...';
  }

  @override
  String get swapExerciseError =>
      'Could not find alternatives.\nPlease try again later.';

  @override
  String get swapExerciseRetry => 'Try again';

  @override
  String get swapNoAlternatives => 'No alternatives found for this exercise.';

  @override
  String swapAltSeries(String n) {
    return '$n sets';
  }

  @override
  String get lastWorkoutTitle => 'History';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsYourReports => 'Your reports';

  @override
  String get reportLoadEvolution => 'Load progression';

  @override
  String get reportLoadEvolutionDesc =>
      'How much your loads increased per exercise';

  @override
  String get reportBody => 'Body measurements';

  @override
  String get reportBodyDesc => 'Weight, BMI and weigh-in history';

  @override
  String get reportVolume => 'Training volume';

  @override
  String get reportVolumeDesc => 'Tonnage lifted in each workout';

  @override
  String get reportFrequency => 'Frequency';

  @override
  String get reportFrequencyDesc => 'Monthly calendar and workouts per week';

  @override
  String get reportPlanPdf => 'Workout plan (PDF)';

  @override
  String get reportPlanPdfDesc => 'All days and exercises in your plan';

  @override
  String get errLoadWeeklySummary => 'Could not load the weekly summary.';

  @override
  String get weeklySummaryTitle => 'Weekly Summary';

  @override
  String get statWorkouts => 'Workouts';

  @override
  String get statTonnage => 'Tonnage';

  @override
  String tonnageEvolutionUp(String pct) {
    return '📈 +$pct% tonnage vs. last week';
  }

  @override
  String tonnageEvolutionDown(String pct) {
    return '📉 $pct% tonnage vs. last week';
  }

  @override
  String get assistantCameraError =>
      'Could not access camera/gallery. Check permissions.';

  @override
  String get assistantTakePhoto => 'Take a photo of the equipment';

  @override
  String get assistantChooseGallery => 'Choose from gallery';

  @override
  String get assistantTitle => 'Ask your questions';

  @override
  String get assistantSearchMachine => 'Search machine';

  @override
  String get assistantPhotoTooltip => 'Send equipment photo';

  @override
  String get assistantSendTooltip => 'Send';

  @override
  String get assistantInputHint => 'Write your question...';

  @override
  String get assistantVideoBtn => 'See exercise videos';

  @override
  String get assistantWelcome =>
      'Hi! 👋 I\'m the PersonalIA assistant. Ask me about training, exercises, nutrition or recovery — or send a photo of a gym machine and I\'ll tell you what exercise to do on it. 📸';

  @override
  String get editProfileTitle => 'Update my profile';

  @override
  String get editTrainingPrefsTitle => 'Training Preferences';

  @override
  String get errLoadProfile => 'Could not load your profile.';

  @override
  String get errLoadPrefs => 'Could not load your preferences.';

  @override
  String get profileFieldName => 'Name';

  @override
  String get profileFieldGender => 'Gender';

  @override
  String get profileFieldBirthDate => 'Date of birth';

  @override
  String get profileFieldWeight => 'Weight (kg)';

  @override
  String get profileFieldHeight => 'Height (cm)';

  @override
  String get profileFieldCpf => 'CPF (optional)';

  @override
  String get profileFieldPhone => 'Phone';

  @override
  String get profileFieldEmail => 'Email';

  @override
  String get profileGenderMale => 'Male';

  @override
  String get profileGenderFemale => 'Female';

  @override
  String get profileSelectDate => 'Select date';

  @override
  String get profilePhoneHelper =>
      'This is your WhatsApp number — it identifies your account.';

  @override
  String get profileEmailHelper =>
      'Email is your login and cannot be changed here.';

  @override
  String get profileSaved => 'Profile updated ✅';

  @override
  String get errSaveProfile => 'Could not save. Please try again.';

  @override
  String get errProfileName => 'Enter your name.';

  @override
  String get errProfileGender => 'Select your gender.';

  @override
  String get errProfileBirthDate => 'Enter your date of birth.';

  @override
  String get errProfileWeight => 'Enter your weight in kg.';

  @override
  String get errProfileHeight => 'Enter your height in cm.';

  @override
  String get errProfileCpf => 'CPF has 11 digits.';

  @override
  String get prefsFieldMinDuration => 'Minimum duration';

  @override
  String get prefsFieldMaxDuration => 'Maximum duration';

  @override
  String get prefsFieldDaysPerWeek => 'Days per week';

  @override
  String get prefsFieldFocus => 'Training focus';

  @override
  String get prefsFieldCardio => 'Cardio';

  @override
  String get prefsFieldGymTime => 'Preferred time';

  @override
  String get prefsSaved => 'Preferences saved ✅';

  @override
  String get errSavePrefs => 'Could not save preferences. Please try again.';

  @override
  String get errOnboardingDurationRange =>
      'Maximum duration must be greater than or equal to minimum.';

  @override
  String get errOnboardingChooseFocus => 'Choose your training focus.';

  @override
  String get errOnboardingGymTime => 'Invalid time. Use HH:MM (e.g.: 18:30).';

  @override
  String get restStatSeries => 'Sets';

  @override
  String get restStatReps => 'Reps';

  @override
  String get restStatRest => 'Rest';

  @override
  String get restStatLastWeight => 'Last weight';

  @override
  String get restStatLastObs => 'Last obs.';

  @override
  String get restBtnVideos => 'Videos';

  @override
  String get restBtnSwap => 'Swap';

  @override
  String get restFinishedTitle => 'Rest finished!';

  @override
  String get restInterExerciseMsg => 'Great work! Ready for the next exercise.';

  @override
  String get restBtnNextExercise => 'Next exercise';

  @override
  String get restSetFinishedMsg => 'Time for the next set!';

  @override
  String get restBtnLetsGo => 'Let\'s go!';

  @override
  String get restTimerDone => 'Done!';

  @override
  String get restBtnReset => 'Restart';

  @override
  String get restBtnStartInterExercise => 'Start inter-exercise rest';

  @override
  String get restBtnConfirmLastSet => 'Confirm last set';

  @override
  String get restBtnStartRest => 'Start rest';

  @override
  String get restExerciseDone => 'Exercise completed!';

  @override
  String get restWeightLabel => 'Weight used (kg)';

  @override
  String get restObservationLabel => 'Observation (optional)';

  @override
  String get restWeightHint => 'Enter weight to finish';

  @override
  String get restBtnFinishExercise => 'Finish exercise';

  @override
  String get restCardioLastTime => 'Last time';

  @override
  String get restCardioRunning => 'Running';

  @override
  String get restCardioTapToStart => 'Tap to start';

  @override
  String get restCardioPaused => 'Paused';

  @override
  String get restCardioDone => 'Done! ✅';

  @override
  String get restCardioGoalReached => 'Goal reached! 🎉';

  @override
  String get restBtnFinishCardio => 'Finish cardio';

  @override
  String get restBtnCardioDone => 'Cardio done!';

  @override
  String get historyEmpty => 'You haven\'t finished any workout yet.';

  @override
  String get errLoadHistory => 'Could not load history.';

  @override
  String get historyToday => 'Today';

  @override
  String get daySummaryExercises => 'exercises';

  @override
  String get daySummarySeries => 'sets';

  @override
  String get daySummaryCardio => 'cardio';

  @override
  String get dayHintTapForVideos => 'Tap an exercise to see execution videos.';

  @override
  String get dayRecoveryMsg => 'Recovery day — no exercises.';

  @override
  String get cardTitle => 'Workout Card';

  @override
  String get cardBtnRemovePhoto => 'Remove photo';

  @override
  String get cardBtnAddPhoto => 'Add photo';

  @override
  String get cardBtnChangePhoto => 'Change photo';

  @override
  String get cardBtnGenerating => 'Generating...';

  @override
  String get cardBtnShare => 'Share';

  @override
  String cardShareText(String dayName) {
    return 'Workout $dayName done! 💪 #PersonaliA';
  }

  @override
  String get cardStatExercises => 'Exercises';

  @override
  String get navHome => 'Home';

  @override
  String get navReports => 'Reports';

  @override
  String get navReferral => 'Refer';

  @override
  String get navMenu => 'Menu';

  @override
  String get navAssistantTooltip => 'Ask questions';

  @override
  String get referralTitle => 'Refer a Friend';

  @override
  String get referralNotEligible =>
      'You need an active subscription to refer friends.';

  @override
  String get referralYourCoupon => 'Your coupon';

  @override
  String get referralShareLink => 'Share link';

  @override
  String get errLoadReferral => 'Could not load.';

  @override
  String get storePlansTitle => 'PersonaliA subscription';

  @override
  String get storeUnavailable =>
      'The store is unavailable. Please try again later.';

  @override
  String get storeVerificationFailed =>
      'We could not verify the purchase. Restore it using the account that purchased the subscription.';

  @override
  String get storeAlreadyActive =>
      'You already have an active subscription. Wait until it expires before switching payment channels.';

  @override
  String get storePurchaseConfirmed =>
      'Subscription confirmed! Your access has been updated.';

  @override
  String get storeRestore => 'Restore purchases';

  @override
  String get storeManage => 'Manage store subscription';

  @override
  String storePricePerMonth(String price) {
    return '$price/month';
  }

  @override
  String storePricePerYear(String price) {
    return '$price/year';
  }

  @override
  String get storeAutoRenewalNotice =>
      'Your subscription renews automatically. Review the billing period and terms in the store before confirming.';

  @override
  String get storeTerms => 'Terms of use';

  @override
  String get storePrivacy => 'Privacy policy';

  @override
  String get restStatusRest => 'Rest';

  @override
  String get restStatusPaused => 'Rest paused';

  @override
  String get restNextSet => 'Next set';

  @override
  String get restBetweenSets => 'Rest between sets';

  @override
  String get restEndRest => 'End rest';

  @override
  String restNextNamed(String name) {
    return 'Next: $name';
  }

  @override
  String restActiveRecord(String name) {
    return 'In progress: $name. You can still edit this exercise below.';
  }

  @override
  String get restPause => 'Pause';

  @override
  String get restResume => 'Resume';

  @override
  String get workoutSavedLocally =>
      'Workout saved on this device. Upload will be retried when connected.';

  @override
  String get cancelWorkoutLabel => 'Cancel workout';

  @override
  String get cancelWorkoutMessage =>
      'Cancel this workout? All progress in this session will be removed, including records already synced.';

  @override
  String get cancelCompletedExerciseLabel => 'Cancel exercise';

  @override
  String get cancelCompletedExerciseMessage =>
      'Remove this completed exercise record? You can perform it again.';

  @override
  String get editExerciseLabel => 'Edit';

  @override
  String get workoutFeedbackLabel => 'Workout feedback (optional)';

  @override
  String get onboardingProfileFormTitle => 'Complete your profile';

  @override
  String get onboardingProfileFormSubtitle =>
      'These details are required to complete your registration and generate your workout.';

  @override
  String get onboardingCpfPrivacy =>
      'We request your CPF to identify the holder in the terms acceptance record. It is not used to design your workout. See the terms for details about how your data is handled.';

  @override
  String get onboardingCpfLabel => 'CPF';

  @override
  String get onboardingProfileFormError =>
      'Check the highlighted fields to continue.';

  @override
  String get loginCreateAccount => 'Create account';

  @override
  String get onboardingBackToLogin => 'Back to login';

  @override
  String get onboardingBodyFormTitle => 'Your workout details';

  @override
  String onboardingProfileProgress(int step) {
    return 'Step $step of 2';
  }
}
