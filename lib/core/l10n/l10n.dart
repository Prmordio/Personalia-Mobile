import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Resolves a controller message key to a localized string.
  /// Keys with ':' carry a parameter (e.g. 'forgotPasswordCodeSent:user@x.com').
  /// Unrecognized keys (e.g. backend error messages) are returned as-is.
  String? resolveMessage(String? key) {
    if (key == null) return null;
    final l = l10n;

    // Parametrized keys: 'baseKey:param'
    final colon = key.indexOf(':');
    if (colon != -1) {
      final base = key.substring(0, colon);
      final param = key.substring(colon + 1);
      return switch (base) {
        'forgotPasswordCodeSent' => l.forgotPasswordCodeSentFor(param),
        'appAccessInfoPhoneConfirmed' => l.appAccessInfoPhoneConfirmed(param),
        'appAccessInfoCodeSentTo' => l.appAccessInfoCodeSentTo(param),
        _ => key,
      };
    }

    return switch (key) {
      // Auth
      'errAuthCannotVerifyPhone' => l.errAuthCannotVerifyPhone,
      'errAuthCannotSendCode' => l.errAuthCannotSendCode,
      'infoAuthCodeResent' => l.infoAuthCodeResent,
      'errAuthCannotResendCode' => l.errAuthCannotResendCode,
      'errAuthInvalidCode' => l.errAuthInvalidCode,
      'errAuthLoginFailed' => l.errAuthLoginFailed,
      'errAuthBiometricExpired' => l.errAuthBiometricExpired,
      'errAuthBiometricFailed' => l.errAuthBiometricFailed,
      'errAuthCodeLength' => l.errAuthCodeLength,
      'errAuthPasswordTooShort' => l.errAuthPasswordTooShort,
      'errAuthPasswordMismatch' => l.errAuthPasswordMismatch,
      'errPasswordMismatch' => l.errPasswordMismatch,
      // App access
      'errAppAccessPhone' => l.errAppAccessPhone,
      'errAppAccessEmail' => l.errAppAccessEmail,
      'appAccessInfoCodeRequested' => l.appAccessInfoCodeRequested,
      'appAccessInfoEmailConfirmed' => l.appAccessInfoEmailConfirmed,
      // Biometric
      'errBiometricActivateFailed' => l.errBiometricActivateFailed,
      'biometricEnabled' => l.biometricEnabled,
      'errBiometricToggleFailed' => l.errBiometricToggleFailed,
      // Appearance / language
      'errAppearanceSave' => l.errAppearanceSave,
      'errLanguageSave' => l.errLanguageSave,
      // Onboarding
      'errOnboardingCannotSaveProfile' => l.errOnboardingCannotSaveProfile,
      'errOnboardingCannotSaveTerms' => l.errOnboardingCannotSaveTerms,
      'errOnboardingCannotSavePassword' => l.errOnboardingCannotSavePassword,
      'errOnboardingCannotSaveAnamnesis' => l.errOnboardingCannotSaveAnamnesis,
      'errOnboardingCannotSavePrefs' => l.errOnboardingCannotSavePrefs,
      'errOnboardingAnswerDisease' => l.errOnboardingAnswerDisease,
      'errOnboardingDescribeDisease' => l.errOnboardingDescribeDisease,
      'errOnboardingAnswerLimitation' => l.errOnboardingAnswerLimitation,
      'errOnboardingDescribeLimitation' => l.errOnboardingDescribeLimitation,
      // Home / workout
      'errLoadWorkout' => l.errLoadWorkout,
      'errCannotStartGeneration' => l.errCannotStartGeneration,
      'errLoadTodayWorkout' => l.errLoadTodayWorkout,
      'errChangePlan' => l.errChangePlan,
      'errLoadCurrentWorkout' => l.errLoadCurrentWorkout,
      'errSaveMeasures' => l.errSaveMeasures,
      'errLoadProgress' => l.errLoadProgress,
      // Reports
      'errLoadWeeklySummary' => l.errLoadWeeklySummary,
      // Profile
      'errLoadProfile' => l.errLoadProfile,
      // Generic
      'genericError' => l.genericError,
      // Backend messages pass through as-is
      _ => key,
    };
  }
}
