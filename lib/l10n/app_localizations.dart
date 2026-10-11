import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'PersonalIA'**
  String get appTitle;

  /// No description provided for @continuar.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get continuar;

  /// No description provided for @confirmar.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get confirmar;

  /// No description provided for @pular.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get pular;

  /// No description provided for @cancelar.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancelar;

  /// No description provided for @salvar.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get salvar;

  /// No description provided for @sim.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get sim;

  /// No description provided for @nao.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get nao;

  /// No description provided for @entrar.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get entrar;

  /// No description provided for @ativar.
  ///
  /// In pt, this message translates to:
  /// **'Ativar'**
  String get ativar;

  /// No description provided for @agoraNao.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get agoraNao;

  /// No description provided for @voltar.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get voltar;

  /// No description provided for @genericError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir. Tente novamente.'**
  String get genericError;

  /// No description provided for @welcomeBiometricButton.
  ///
  /// In pt, this message translates to:
  /// **'Entrar com biometria'**
  String get welcomeBiometricButton;

  /// No description provided for @welcomeEmailButton.
  ///
  /// In pt, this message translates to:
  /// **'Entrar com email e senha'**
  String get welcomeEmailButton;

  /// No description provided for @welcomeWhatsAppButton.
  ///
  /// In pt, this message translates to:
  /// **'Já uso o PersonalIA no WhatsApp'**
  String get welcomeWhatsAppButton;

  /// No description provided for @welcomeNewUserButton.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não uso o PersonalIA — criar perfil'**
  String get welcomeNewUserButton;

  /// No description provided for @errAuthBiometricExpired.
  ///
  /// In pt, this message translates to:
  /// **'Sua biometria expirou ou foi desativada. Entre com email e senha.'**
  String get errAuthBiometricExpired;

  /// No description provided for @errAuthBiometricFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível entrar agora. Tente novamente.'**
  String get errAuthBiometricFailed;

  /// No description provided for @loginCreateProfileTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar perfil'**
  String get loginCreateProfileTitle;

  /// No description provided for @loginSyncTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar conta'**
  String get loginSyncTitle;

  /// No description provided for @loginCreateProfileDesc.
  ///
  /// In pt, this message translates to:
  /// **'Digite seu telefone com DDI e DDD pra criar seu perfil e receber um código de acesso.'**
  String get loginCreateProfileDesc;

  /// No description provided for @loginSyncDesc.
  ///
  /// In pt, this message translates to:
  /// **'Digite o telefone da sua conta PersonalIA no WhatsApp pra receber um código de acesso.'**
  String get loginSyncDesc;

  /// No description provided for @loginHowToReceive.
  ///
  /// In pt, this message translates to:
  /// **'Como você quer receber o código?'**
  String get loginHowToReceive;

  /// No description provided for @loginReceiveVia.
  ///
  /// In pt, this message translates to:
  /// **'Receber por {channel}'**
  String loginReceiveVia(String channel);

  /// No description provided for @loginEnterCode.
  ///
  /// In pt, this message translates to:
  /// **'Digite o código'**
  String get loginEnterCode;

  /// No description provided for @loginCodeSentVia.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um código de 6 dígitos por {channel}.'**
  String loginCodeSentVia(String channel);

  /// No description provided for @loginResendCode.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar código'**
  String get loginResendCode;

  /// No description provided for @loginUseOtherPhone.
  ///
  /// In pt, this message translates to:
  /// **'Usar outro número'**
  String get loginUseOtherPhone;

  /// No description provided for @errAuthCannotVerifyPhone.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível verificar esse número.'**
  String get errAuthCannotVerifyPhone;

  /// No description provided for @errAuthCannotSendCode.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível enviar o código. Tente novamente.'**
  String get errAuthCannotSendCode;

  /// No description provided for @infoAuthCodeResent.
  ///
  /// In pt, this message translates to:
  /// **'Código reenviado.'**
  String get infoAuthCodeResent;

  /// No description provided for @errAuthCannotResendCode.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível reenviar o código. Tente novamente.'**
  String get errAuthCannotResendCode;

  /// No description provided for @errAuthInvalidCode.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido ou expirado.'**
  String get errAuthInvalidCode;

  /// No description provided for @errAuthLoginFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível entrar. Tente novamente.'**
  String get errAuthLoginFailed;

  /// No description provided for @passwordLoginTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entrar com email'**
  String get passwordLoginTitle;

  /// No description provided for @passwordHint.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get passwordHint;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci minha senha'**
  String get forgotPasswordLink;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Redefinir senha'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordEnterCodeDesc.
  ///
  /// In pt, this message translates to:
  /// **'Digite o código que chegou no seu email e escolha uma nova senha.'**
  String get forgotPasswordEnterCodeDesc;

  /// No description provided for @forgotPasswordEnterEmailDesc.
  ///
  /// In pt, this message translates to:
  /// **'Informe o email da sua conta. Vamos enviar um código para você criar uma nova senha.'**
  String get forgotPasswordEnterEmailDesc;

  /// No description provided for @forgotPasswordCodeHint.
  ///
  /// In pt, this message translates to:
  /// **'Código de 6 dígitos'**
  String get forgotPasswordCodeHint;

  /// No description provided for @forgotPasswordNewPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Nova senha (mínimo 8 caracteres)'**
  String get forgotPasswordNewPasswordHint;

  /// No description provided for @forgotPasswordSendCode.
  ///
  /// In pt, this message translates to:
  /// **'Enviar código'**
  String get forgotPasswordSendCode;

  /// No description provided for @forgotPasswordSavePassword.
  ///
  /// In pt, this message translates to:
  /// **'Salvar nova senha'**
  String get forgotPasswordSavePassword;

  /// No description provided for @forgotPasswordNoCode.
  ///
  /// In pt, this message translates to:
  /// **'Não recebi o código / trocar email'**
  String get forgotPasswordNoCode;

  /// No description provided for @forgotPasswordCodeSentFor.
  ///
  /// In pt, this message translates to:
  /// **'Se houver uma conta com {email}, enviamos um código de 6 dígitos. Confira também o spam.'**
  String forgotPasswordCodeSentFor(String email);

  /// No description provided for @appAccessTitle.
  ///
  /// In pt, this message translates to:
  /// **'Acessar o app'**
  String get appAccessTitle;

  /// No description provided for @appAccessEmailCodeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Código do email'**
  String get appAccessEmailCodeTitle;

  /// No description provided for @appAccessPhoneCodeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Código do WhatsApp'**
  String get appAccessPhoneCodeTitle;

  /// No description provided for @appAccessConfirmEmailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirme seu email'**
  String get appAccessConfirmEmailTitle;

  /// No description provided for @appAccessPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie sua senha'**
  String get appAccessPasswordTitle;

  /// No description provided for @appAccessSendCodeAction.
  ///
  /// In pt, this message translates to:
  /// **'Enviar código'**
  String get appAccessSendCodeAction;

  /// No description provided for @appAccessSavePassword.
  ///
  /// In pt, this message translates to:
  /// **'Salvar senha e entrar'**
  String get appAccessSavePassword;

  /// No description provided for @appAccessConfirmCode.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar código'**
  String get appAccessConfirmCode;

  /// No description provided for @appAccessStartDesc.
  ///
  /// In pt, this message translates to:
  /// **'Informe o telefone que você usa no WhatsApp com o PersonalIA e o seu email.'**
  String get appAccessStartDesc;

  /// No description provided for @appAccessPhoneHint.
  ///
  /// In pt, this message translates to:
  /// **'Telefone com DDD'**
  String get appAccessPhoneHint;

  /// No description provided for @appAccessPhoneCodeDesc.
  ///
  /// In pt, this message translates to:
  /// **'Se você falou com o PersonalIA no WhatsApp nas últimas 24h, o código já deve ter chegado lá. Se não chegou, toque em \"Abrir WhatsApp\" e envie a mensagem pronta — respondemos com o código.'**
  String get appAccessPhoneCodeDesc;

  /// No description provided for @appAccessOpenWhatsApp.
  ///
  /// In pt, this message translates to:
  /// **'Abrir WhatsApp'**
  String get appAccessOpenWhatsApp;

  /// No description provided for @appAccessConfirmEmailDesc.
  ///
  /// In pt, this message translates to:
  /// **'Número confirmado ✅ Confira seu email (corrija se precisar) — vamos enviar um código para ele.'**
  String get appAccessConfirmEmailDesc;

  /// No description provided for @appAccessPasswordDesc.
  ///
  /// In pt, this message translates to:
  /// **'Tudo confirmado ✅ Agora é só criar a senha para entrar com email e senha.'**
  String get appAccessPasswordDesc;

  /// No description provided for @appAccessRepeatPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Repita a senha'**
  String get appAccessRepeatPasswordHint;

  /// No description provided for @appAccessCodeHint.
  ///
  /// In pt, this message translates to:
  /// **'Código de 6 dígitos'**
  String get appAccessCodeHint;

  /// No description provided for @appAccessFixEmail.
  ///
  /// In pt, this message translates to:
  /// **'Email errado? Corrigir'**
  String get appAccessFixEmail;

  /// No description provided for @appAccessNoEmail.
  ///
  /// In pt, this message translates to:
  /// **'Não recebi o email / email errado'**
  String get appAccessNoEmail;

  /// No description provided for @appAccessRestart.
  ///
  /// In pt, this message translates to:
  /// **'Recomeçar'**
  String get appAccessRestart;

  /// No description provided for @appAccessInfoCodeRequested.
  ///
  /// In pt, this message translates to:
  /// **'Se houver cadastro com esses dados, enviamos um código para o email e/ou WhatsApp cadastrados.'**
  String get appAccessInfoCodeRequested;

  /// No description provided for @appAccessInfoEmailConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Email confirmado ✅ Agora confirme seu número pelo WhatsApp.'**
  String get appAccessInfoEmailConfirmed;

  /// No description provided for @appAccessInfoPhoneConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Número confirmado ✅ Digite o código que enviamos para {email}.'**
  String appAccessInfoPhoneConfirmed(String email);

  /// No description provided for @appAccessInfoCodeSentTo.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um código para {email}.'**
  String appAccessInfoCodeSentTo(String email);

  /// No description provided for @errAppAccessPhone.
  ///
  /// In pt, this message translates to:
  /// **'Informe o telefone com DDD.'**
  String get errAppAccessPhone;

  /// No description provided for @errAppAccessEmail.
  ///
  /// In pt, this message translates to:
  /// **'Informe um email válido.'**
  String get errAppAccessEmail;

  /// No description provided for @errAuthCodeLength.
  ///
  /// In pt, this message translates to:
  /// **'O código tem 6 dígitos.'**
  String get errAuthCodeLength;

  /// No description provided for @errAuthPasswordTooShort.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter pelo menos 8 caracteres.'**
  String get errAuthPasswordTooShort;

  /// No description provided for @errAuthPasswordMismatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não conferem.'**
  String get errAuthPasswordMismatch;

  /// No description provided for @errPasswordMismatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem.'**
  String get errPasswordMismatch;

  /// No description provided for @biometricOfferTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entrar com biometria?'**
  String get biometricOfferTitle;

  /// No description provided for @biometricOfferDesc.
  ///
  /// In pt, this message translates to:
  /// **'Da próxima vez, entre com sua digital ou rosto, sem digitar a senha.'**
  String get biometricOfferDesc;

  /// No description provided for @biometricEnabled.
  ///
  /// In pt, this message translates to:
  /// **'Biometria ativada ✅'**
  String get biometricEnabled;

  /// No description provided for @errBiometricActivateFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ativar a biometria. Tente de novo pelo Menu.'**
  String get errBiometricActivateFailed;

  /// No description provided for @biometricToggleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entrar com biometria'**
  String get biometricToggleTitle;

  /// No description provided for @biometricToggleSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Digital ou rosto em vez da senha'**
  String get biometricToggleSubtitle;

  /// No description provided for @errBiometricToggleFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ativar a biometria. Tente novamente.'**
  String get errBiometricToggleFailed;

  /// No description provided for @biometricConfirmPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Confirme para ativar o login por biometria'**
  String get biometricConfirmPrompt;

  /// No description provided for @biometricLoginPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Entre no PersonalIA'**
  String get biometricLoginPrompt;

  /// No description provided for @menuTitle.
  ///
  /// In pt, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// No description provided for @menuCurrentWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Meu Treino Atual'**
  String get menuCurrentWorkout;

  /// No description provided for @menuHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get menuHistory;

  /// No description provided for @menuSearchMachine.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar máquina'**
  String get menuSearchMachine;

  /// No description provided for @menuAskDoubt.
  ///
  /// In pt, this message translates to:
  /// **'Tirar dúvidas'**
  String get menuAskDoubt;

  /// No description provided for @menuUpdateProfile.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar Meu Perfil'**
  String get menuUpdateProfile;

  /// No description provided for @menuTrainingPreferences.
  ///
  /// In pt, this message translates to:
  /// **'Preferências de Treino'**
  String get menuTrainingPreferences;

  /// No description provided for @menuAppearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get menuAppearance;

  /// No description provided for @menuLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get menuLanguage;

  /// No description provided for @menuLogout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get menuLogout;

  /// No description provided for @appearanceSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get appearanceSystem;

  /// No description provided for @appearanceLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get appearanceDark;

  /// No description provided for @errAppearanceSave.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar a aparência. Tente novamente.'**
  String get errAppearanceSave;

  /// No description provided for @langSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get langSystem;

  /// No description provided for @langPortuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get langPortuguese;

  /// No description provided for @langEnglish.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langSpanish.
  ///
  /// In pt, this message translates to:
  /// **'Español'**
  String get langSpanish;

  /// No description provided for @errLanguageSave.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar o idioma. Tente novamente.'**
  String get errLanguageSave;

  /// No description provided for @onboardingNameTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual é o seu nome completo?'**
  String get onboardingNameTitle;

  /// No description provided for @onboardingNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome e sobrenome'**
  String get onboardingNameHint;

  /// No description provided for @onboardingGenderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual o seu gênero?'**
  String get onboardingGenderTitle;

  /// No description provided for @genderMale.
  ///
  /// In pt, this message translates to:
  /// **'Masculino'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In pt, this message translates to:
  /// **'Feminino'**
  String get genderFemale;

  /// No description provided for @onboardingBirthDateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual a sua data de nascimento?'**
  String get onboardingBirthDateTitle;

  /// No description provided for @onboardingPickDate.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar data'**
  String get onboardingPickDate;

  /// No description provided for @onboardingWeightTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual o seu peso? (kg)'**
  String get onboardingWeightTitle;

  /// No description provided for @onboardingWeightHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 70.5'**
  String get onboardingWeightHint;

  /// No description provided for @onboardingHeightTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual a sua altura? (cm)'**
  String get onboardingHeightTitle;

  /// No description provided for @onboardingHeightHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 175'**
  String get onboardingHeightHint;

  /// No description provided for @onboardingEmailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual o seu email?'**
  String get onboardingEmailTitle;

  /// No description provided for @onboardingEmailHint.
  ///
  /// In pt, this message translates to:
  /// **'seuemail@exemplo.com'**
  String get onboardingEmailHint;

  /// No description provided for @onboardingConfirmDataTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confira seus dados'**
  String get onboardingConfirmDataTitle;

  /// No description provided for @onboardingCpfTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual o seu CPF?'**
  String get onboardingCpfTitle;

  /// No description provided for @onboardingCpfHint.
  ///
  /// In pt, this message translates to:
  /// **'000.000.000-00'**
  String get onboardingCpfHint;

  /// No description provided for @summaryName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get summaryName;

  /// No description provided for @summaryCpf.
  ///
  /// In pt, this message translates to:
  /// **'CPF'**
  String get summaryCpf;

  /// No description provided for @summaryTerms.
  ///
  /// In pt, this message translates to:
  /// **'Termos de uso'**
  String get summaryTerms;

  /// No description provided for @summaryGender.
  ///
  /// In pt, this message translates to:
  /// **'Gênero'**
  String get summaryGender;

  /// No description provided for @summaryBirthDate.
  ///
  /// In pt, this message translates to:
  /// **'Data de nascimento'**
  String get summaryBirthDate;

  /// No description provided for @summaryWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso'**
  String get summaryWeight;

  /// No description provided for @summaryHeight.
  ///
  /// In pt, this message translates to:
  /// **'Altura'**
  String get summaryHeight;

  /// No description provided for @summaryEmail.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get summaryEmail;

  /// No description provided for @summaryAccepted.
  ///
  /// In pt, this message translates to:
  /// **'Aceito'**
  String get summaryAccepted;

  /// No description provided for @summaryNotAccepted.
  ///
  /// In pt, this message translates to:
  /// **'Não aceito'**
  String get summaryNotAccepted;

  /// No description provided for @unitKg.
  ///
  /// In pt, this message translates to:
  /// **'{weight} kg'**
  String unitKg(String weight);

  /// No description provided for @unitCm.
  ///
  /// In pt, this message translates to:
  /// **'{height} cm'**
  String unitCm(String height);

  /// No description provided for @disclaimerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Antes de continuar'**
  String get disclaimerTitle;

  /// No description provided for @disclaimerSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Você declara estar apto fisicamente para treinar e aceita nossos termos de uso?'**
  String get disclaimerSubtitle;

  /// No description provided for @disclaimerCheckbox.
  ///
  /// In pt, this message translates to:
  /// **'Declaro estar apto fisicamente para treinar e aceito os termos de uso.'**
  String get disclaimerCheckbox;

  /// No description provided for @disclaimerReadTerms.
  ///
  /// In pt, this message translates to:
  /// **'Ler os termos de uso completos'**
  String get disclaimerReadTerms;

  /// No description provided for @onboardingCreatePasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie uma senha'**
  String get onboardingCreatePasswordTitle;

  /// No description provided for @onboardingCreatePasswordSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Assim você também pode entrar com email e senha, sem precisar de um novo código toda vez.'**
  String get onboardingCreatePasswordSubtitle;

  /// No description provided for @onboardingPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Senha (mínimo 8 caracteres)'**
  String get onboardingPasswordHint;

  /// No description provided for @onboardingConfirmPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar senha'**
  String get onboardingConfirmPasswordHint;

  /// No description provided for @onboardingMainGoalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual é o seu objetivo principal?'**
  String get onboardingMainGoalTitle;

  /// No description provided for @goalMassGain.
  ///
  /// In pt, this message translates to:
  /// **'Ganho de massa'**
  String get goalMassGain;

  /// No description provided for @goalWeightLoss.
  ///
  /// In pt, this message translates to:
  /// **'Perda de peso'**
  String get goalWeightLoss;

  /// No description provided for @goalStrength.
  ///
  /// In pt, this message translates to:
  /// **'Força'**
  String get goalStrength;

  /// No description provided for @goalConditioning.
  ///
  /// In pt, this message translates to:
  /// **'Condicionamento'**
  String get goalConditioning;

  /// No description provided for @onboardingHealthTitle.
  ///
  /// In pt, this message translates to:
  /// **'Saúde e limitações'**
  String get onboardingHealthTitle;

  /// No description provided for @onboardingHasDiseases.
  ///
  /// In pt, this message translates to:
  /// **'Você possui alguma doença ou condição médica?'**
  String get onboardingHasDiseases;

  /// No description provided for @onboardingDiseasesHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Hipertensão controlada'**
  String get onboardingDiseasesHint;

  /// No description provided for @onboardingHasLimitations.
  ///
  /// In pt, this message translates to:
  /// **'Você possui alguma limitação física?'**
  String get onboardingHasLimitations;

  /// No description provided for @onboardingLimitationsHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Lesão no ombro direito'**
  String get onboardingLimitationsHint;

  /// No description provided for @onboardingActivityLevelTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual o seu nível de atividade física atual?'**
  String get onboardingActivityLevelTitle;

  /// No description provided for @activitySedentary.
  ///
  /// In pt, this message translates to:
  /// **'Sedentário'**
  String get activitySedentary;

  /// No description provided for @activityLight.
  ///
  /// In pt, this message translates to:
  /// **'Leve (1-3 dias/semana)'**
  String get activityLight;

  /// No description provided for @activityModerate.
  ///
  /// In pt, this message translates to:
  /// **'Moderado (3-5 dias/semana)'**
  String get activityModerate;

  /// No description provided for @activityIntense.
  ///
  /// In pt, this message translates to:
  /// **'Intenso (6-7 dias/semana)'**
  String get activityIntense;

  /// No description provided for @activityAthlete.
  ///
  /// In pt, this message translates to:
  /// **'Atleta ou trabalho físico pesado'**
  String get activityAthlete;

  /// No description provided for @onboardingConfirmAnamnesisTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confira sua anamnese'**
  String get onboardingConfirmAnamnesisTitle;

  /// No description provided for @summaryGoal.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo'**
  String get summaryGoal;

  /// No description provided for @summaryDiseases.
  ///
  /// In pt, this message translates to:
  /// **'Doenças'**
  String get summaryDiseases;

  /// No description provided for @summaryPhysicalLimitations.
  ///
  /// In pt, this message translates to:
  /// **'Limitações físicas'**
  String get summaryPhysicalLimitations;

  /// No description provided for @summaryActivityLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível de atividade'**
  String get summaryActivityLevel;

  /// No description provided for @onboardingDurationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Duração do treino'**
  String get onboardingDurationTitle;

  /// No description provided for @onboardingDurationSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Entre 30 e 180 minutos.'**
  String get onboardingDurationSubtitle;

  /// No description provided for @onboardingDurationMin.
  ///
  /// In pt, this message translates to:
  /// **'Duração mínima (minutos)'**
  String get onboardingDurationMin;

  /// No description provided for @onboardingDurationMax.
  ///
  /// In pt, this message translates to:
  /// **'Duração máxima (minutos)'**
  String get onboardingDurationMax;

  /// No description provided for @onboardingTrainingDaysTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quantos dias por semana você quer treinar?'**
  String get onboardingTrainingDaysTitle;

  /// No description provided for @onboardingTrainingDaysSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Entre 1 e 7 dias.'**
  String get onboardingTrainingDaysSubtitle;

  /// No description provided for @suffixDays.
  ///
  /// In pt, this message translates to:
  /// **'{count} dias'**
  String suffixDays(int count);

  /// No description provided for @onboardingGymTimeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual o seu horário preferido de treino?'**
  String get onboardingGymTimeTitle;

  /// No description provided for @onboardingGymTimeSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Opcional — você pode pular esta etapa.'**
  String get onboardingGymTimeSubtitle;

  /// No description provided for @onboardingCardioTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você quer incluir cardio no seu treino?'**
  String get onboardingCardioTitle;

  /// No description provided for @onboardingCardioInclude.
  ///
  /// In pt, this message translates to:
  /// **'Incluir cardio no fim do treino'**
  String get onboardingCardioInclude;

  /// No description provided for @onboardingTrainingFocusTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual o foco do seu treino?'**
  String get onboardingTrainingFocusTitle;

  /// No description provided for @focusUpper.
  ///
  /// In pt, this message translates to:
  /// **'Membros superiores'**
  String get focusUpper;

  /// No description provided for @focusLower.
  ///
  /// In pt, this message translates to:
  /// **'Membros inferiores'**
  String get focusLower;

  /// No description provided for @focusFullBody.
  ///
  /// In pt, this message translates to:
  /// **'Corpo todo'**
  String get focusFullBody;

  /// No description provided for @freeTrialTitle.
  ///
  /// In pt, this message translates to:
  /// **'🎁 7 dias grátis liberados, {name}!'**
  String freeTrialTitle(String name);

  /// No description provided for @freeTrialSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Aproveite pra deixar seu treino pronto e explorar o app à vontade.'**
  String get freeTrialSubtitle;

  /// No description provided for @generateWorkoutButton.
  ///
  /// In pt, this message translates to:
  /// **'Gerar meu treino'**
  String get generateWorkoutButton;

  /// No description provided for @generatingWorkoutWait.
  ///
  /// In pt, this message translates to:
  /// **'Isso pode levar alguns minutos.'**
  String get generatingWorkoutWait;

  /// No description provided for @generatingWorkoutTimeout.
  ///
  /// In pt, this message translates to:
  /// **'Isso está demorando mais que o normal.'**
  String get generatingWorkoutTimeout;

  /// No description provided for @generatingWorkoutTimeoutDesc.
  ///
  /// In pt, this message translates to:
  /// **'Você pode continuar pelo início — seu treino aparece por lá assim que ficar pronto.'**
  String get generatingWorkoutTimeoutDesc;

  /// No description provided for @generatingWorkoutGoHome.
  ///
  /// In pt, this message translates to:
  /// **'Ir para o início'**
  String get generatingWorkoutGoHome;

  /// No description provided for @thinkingStep0.
  ///
  /// In pt, this message translates to:
  /// **'Analisando seu perfil...'**
  String get thinkingStep0;

  /// No description provided for @thinkingStep1.
  ///
  /// In pt, this message translates to:
  /// **'Pensando no melhor plano...'**
  String get thinkingStep1;

  /// No description provided for @thinkingStep2.
  ///
  /// In pt, this message translates to:
  /// **'Calculando séries e cargas...'**
  String get thinkingStep2;

  /// No description provided for @thinkingStep3.
  ///
  /// In pt, this message translates to:
  /// **'Escolhendo os exercícios certos...'**
  String get thinkingStep3;

  /// No description provided for @thinkingStep4.
  ///
  /// In pt, this message translates to:
  /// **'Ajustando o volume de treino...'**
  String get thinkingStep4;

  /// No description provided for @thinkingStep5.
  ///
  /// In pt, this message translates to:
  /// **'Alinhando com o seu objetivo...'**
  String get thinkingStep5;

  /// No description provided for @thinkingStep6.
  ///
  /// In pt, this message translates to:
  /// **'Finalizando os detalhes...'**
  String get thinkingStep6;

  /// No description provided for @errOnboardingCannotSaveProfile.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar seu perfil. Tente novamente.'**
  String get errOnboardingCannotSaveProfile;

  /// No description provided for @errOnboardingCannotSaveTerms.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível aceitar os termos. Tente novamente.'**
  String get errOnboardingCannotSaveTerms;

  /// No description provided for @errOnboardingCannotSavePassword.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar sua senha. Tente novamente.'**
  String get errOnboardingCannotSavePassword;

  /// No description provided for @errOnboardingCannotSaveAnamnesis.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar sua anamnese. Tente novamente.'**
  String get errOnboardingCannotSaveAnamnesis;

  /// No description provided for @errOnboardingCannotSavePrefs.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar suas preferências. Tente novamente.'**
  String get errOnboardingCannotSavePrefs;

  /// No description provided for @errOnboardingAnswerDisease.
  ///
  /// In pt, this message translates to:
  /// **'Responda se você possui alguma doença ou condição médica.'**
  String get errOnboardingAnswerDisease;

  /// No description provided for @errOnboardingDescribeDisease.
  ///
  /// In pt, this message translates to:
  /// **'Descreva suas doenças ou condições (ou volte e responda Não).'**
  String get errOnboardingDescribeDisease;

  /// No description provided for @errOnboardingAnswerLimitation.
  ///
  /// In pt, this message translates to:
  /// **'Responda se você possui alguma limitação física.'**
  String get errOnboardingAnswerLimitation;

  /// No description provided for @errOnboardingDescribeLimitation.
  ///
  /// In pt, this message translates to:
  /// **'Descreva suas limitações físicas (ou volte e responda Não).'**
  String get errOnboardingDescribeLimitation;

  /// No description provided for @homeAppBarTitle.
  ///
  /// In pt, this message translates to:
  /// **'PersonalIA'**
  String get homeAppBarTitle;

  /// No description provided for @subscriptionFreeTrial.
  ///
  /// In pt, this message translates to:
  /// **'Período grátis ativo'**
  String get subscriptionFreeTrial;

  /// No description provided for @subscriptionActive.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura ativa'**
  String get subscriptionActive;

  /// No description provided for @subscriptionInactive.
  ///
  /// In pt, this message translates to:
  /// **'Sem assinatura ativa'**
  String get subscriptionInactive;

  /// No description provided for @subscriptionValidUntil.
  ///
  /// In pt, this message translates to:
  /// **'Válido até {date}'**
  String subscriptionValidUntil(String date);

  /// No description provided for @subscriptionNextCharge.
  ///
  /// In pt, this message translates to:
  /// **'Próxima cobrança em {date}'**
  String subscriptionNextCharge(String date);

  /// No description provided for @subscriptionSignupPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Assine para continuar gerando treinos.'**
  String get subscriptionSignupPrompt;

  /// No description provided for @subscriptionButton.
  ///
  /// In pt, this message translates to:
  /// **'Assinar'**
  String get subscriptionButton;

  /// No description provided for @dailyTipTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dica do dia'**
  String get dailyTipTitle;

  /// No description provided for @errLoadWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seu treino.'**
  String get errLoadWorkout;

  /// No description provided for @noWorkoutIdleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem um treino ativo.'**
  String get noWorkoutIdleTitle;

  /// No description provided for @noWorkoutGeneratingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gerando seu treino...'**
  String get noWorkoutGeneratingTitle;

  /// No description provided for @noWorkoutGeneratingSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Isso pode levar alguns minutos. Ele aparece aqui assim que ficar pronto.'**
  String get noWorkoutGeneratingSubtitle;

  /// No description provided for @noWorkoutFailedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não conseguimos gerar seu treino agora.'**
  String get noWorkoutFailedTitle;

  /// No description provided for @noWorkoutFailedSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Nossa IA teve um problema ao montar o plano. Tente de novo em instantes.'**
  String get noWorkoutFailedSubtitle;

  /// No description provided for @noWorkoutTimedOutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu treino está demorando mais que o normal.'**
  String get noWorkoutTimedOutTitle;

  /// No description provided for @noWorkoutTimedOutSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ele aparece aqui assim que ficar pronto.'**
  String get noWorkoutTimedOutSubtitle;

  /// No description provided for @btnSendingRequest.
  ///
  /// In pt, this message translates to:
  /// **'Enviando pedido...'**
  String get btnSendingRequest;

  /// No description provided for @btnGenerating.
  ///
  /// In pt, this message translates to:
  /// **'Gerando...'**
  String get btnGenerating;

  /// No description provided for @btnRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get btnRetry;

  /// No description provided for @btnCheckAgain.
  ///
  /// In pt, this message translates to:
  /// **'Verificar novamente'**
  String get btnCheckAgain;

  /// No description provided for @errCannotStartGeneration.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível iniciar a geração. Tente novamente.'**
  String get errCannotStartGeneration;

  /// No description provided for @workoutDoneToday.
  ///
  /// In pt, this message translates to:
  /// **'Treino concluído hoje! ✅'**
  String get workoutDoneToday;

  /// No description provided for @workoutInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Treino em andamento'**
  String get workoutInProgress;

  /// No description provided for @workoutStart.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar Treino'**
  String get workoutStart;

  /// No description provided for @workoutStatusInProgress.
  ///
  /// In pt, this message translates to:
  /// **'● Em andamento'**
  String get workoutStatusInProgress;

  /// No description provided for @workoutExerciseCount.
  ///
  /// In pt, this message translates to:
  /// **'{count}/{total} exercícios'**
  String workoutExerciseCount(int count, int total);

  /// No description provided for @workoutRestDay.
  ///
  /// In pt, this message translates to:
  /// **'Hoje é dia de descanso. 😴'**
  String get workoutRestDay;

  /// No description provided for @btnTrainAgain.
  ///
  /// In pt, this message translates to:
  /// **'Treinar novamente'**
  String get btnTrainAgain;

  /// No description provided for @btnContinueWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Continuar Treino'**
  String get btnContinueWorkout;

  /// No description provided for @btnSwitchWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Trocar treino'**
  String get btnSwitchWorkout;

  /// No description provided for @chooseWorkoutDayTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual treino você quer fazer hoje?'**
  String get chooseWorkoutDayTitle;

  /// No description provided for @exercisesCount.
  ///
  /// In pt, this message translates to:
  /// **'{n} exercícios'**
  String exercisesCount(int n);

  /// No description provided for @errLoadTodayWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o treino de hoje.'**
  String get errLoadTodayWorkout;

  /// No description provided for @viewPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Visualizar Plano'**
  String get viewPlanTitle;

  /// No description provided for @viewPlanDesc.
  ///
  /// In pt, this message translates to:
  /// **'Veja todos os dias do seu treino e os exercícios de cada um.'**
  String get viewPlanDesc;

  /// No description provided for @viewPlanButton.
  ///
  /// In pt, this message translates to:
  /// **'Visualizar plano'**
  String get viewPlanButton;

  /// No description provided for @progressTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua Evolução'**
  String get progressTitle;

  /// No description provided for @progressAddMeasures.
  ///
  /// In pt, this message translates to:
  /// **'Toque para inserir seu peso e altura.'**
  String get progressAddMeasures;

  /// No description provided for @progressWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso'**
  String get progressWeight;

  /// No description provided for @progressHeight.
  ///
  /// In pt, this message translates to:
  /// **'Altura'**
  String get progressHeight;

  /// No description provided for @progressLast90Days.
  ///
  /// In pt, this message translates to:
  /// **'Últimos 90 dias'**
  String get progressLast90Days;

  /// No description provided for @updateMeasuresTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar medidas'**
  String get updateMeasuresTitle;

  /// No description provided for @weightLabel.
  ///
  /// In pt, this message translates to:
  /// **'Peso (kg)'**
  String get weightLabel;

  /// No description provided for @heightLabel.
  ///
  /// In pt, this message translates to:
  /// **'Altura (cm)'**
  String get heightLabel;

  /// No description provided for @weightHint.
  ///
  /// In pt, this message translates to:
  /// **'ex: 85.5'**
  String get weightHint;

  /// No description provided for @heightHint.
  ///
  /// In pt, this message translates to:
  /// **'ex: 175'**
  String get heightHint;

  /// No description provided for @errSaveMeasures.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar as medidas. Tente novamente.'**
  String get errSaveMeasures;

  /// No description provided for @errLoadProgress.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar sua evolução.'**
  String get errLoadProgress;

  /// No description provided for @subscriptionAlreadyActive.
  ///
  /// In pt, this message translates to:
  /// **'Sua assinatura já está ativa ✅'**
  String get subscriptionAlreadyActive;

  /// No description provided for @errOpenPaymentPage.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir a página de pagamento.'**
  String get errOpenPaymentPage;

  /// No description provided for @errGeneratePayment.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível gerar o pagamento. Tente novamente.'**
  String get errGeneratePayment;

  /// No description provided for @subscriptionRequiredTitle.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura necessária'**
  String get subscriptionRequiredTitle;

  /// No description provided for @subscriptionRequiredDesc.
  ///
  /// In pt, this message translates to:
  /// **'Seu período grátis ou sua assinatura terminou. Assine o PersonalIA para gerar seu treino — depois de pagar, volte aqui e toque em \"Gerar meu treino\" de novo.'**
  String get subscriptionRequiredDesc;

  /// No description provided for @btnNotNow.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get btnNotNow;

  /// No description provided for @todayWorkoutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Treino de Hoje'**
  String get todayWorkoutTitle;

  /// No description provided for @todayNoExercises.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum exercício encontrado para hoje.'**
  String get todayNoExercises;

  /// No description provided for @showCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar concluídos ({n})'**
  String showCompleted(int n);

  /// No description provided for @hideCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar concluídos ({n})'**
  String hideCompleted(int n);

  /// No description provided for @exerciseSwapped.
  ///
  /// In pt, this message translates to:
  /// **'Trocado: {name}'**
  String exerciseSwapped(String name);

  /// No description provided for @exerciseCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get exerciseCompleted;

  /// No description provided for @exerciseRunning.
  ///
  /// In pt, this message translates to:
  /// **'Em execução'**
  String get exerciseRunning;

  /// No description provided for @exerciseSetsProgress.
  ///
  /// In pt, this message translates to:
  /// **'{done}/{total} séries'**
  String exerciseSetsProgress(int done, int total);

  /// No description provided for @statGoal.
  ///
  /// In pt, this message translates to:
  /// **'Meta'**
  String get statGoal;

  /// No description provided for @statTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo'**
  String get statTime;

  /// No description provided for @statLastTime.
  ///
  /// In pt, this message translates to:
  /// **'Último tempo'**
  String get statLastTime;

  /// No description provided for @statSets.
  ///
  /// In pt, this message translates to:
  /// **'Séries'**
  String get statSets;

  /// No description provided for @statReps.
  ///
  /// In pt, this message translates to:
  /// **'Repetições'**
  String get statReps;

  /// No description provided for @statRest.
  ///
  /// In pt, this message translates to:
  /// **'Descanso'**
  String get statRest;

  /// No description provided for @statLastWeight.
  ///
  /// In pt, this message translates to:
  /// **'Último peso'**
  String get statLastWeight;

  /// No description provided for @statLastObs.
  ///
  /// In pt, this message translates to:
  /// **'Última obs.'**
  String get statLastObs;

  /// No description provided for @btnVideos.
  ///
  /// In pt, this message translates to:
  /// **'Vídeos'**
  String get btnVideos;

  /// No description provided for @btnSwap.
  ///
  /// In pt, this message translates to:
  /// **'Trocar'**
  String get btnSwap;

  /// No description provided for @btnFinishWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar treino'**
  String get btnFinishWorkout;

  /// No description provided for @finishWorkoutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar treino?'**
  String get finishWorkoutTitle;

  /// No description provided for @finishWorkoutConfirmMsg.
  ///
  /// In pt, this message translates to:
  /// **'Ainda há exercícios não concluídos. Deseja finalizar assim mesmo?'**
  String get finishWorkoutConfirmMsg;

  /// No description provided for @btnYesFinish.
  ///
  /// In pt, this message translates to:
  /// **'Sim, finalizar'**
  String get btnYesFinish;

  /// No description provided for @exerciseInProgressTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exercício em andamento'**
  String get exerciseInProgressTitle;

  /// No description provided for @exerciseInProgressMsg.
  ///
  /// In pt, this message translates to:
  /// **'\"{current}\" ainda está em andamento.\n\nDeseja abandoná-lo e iniciar \"{next}\"?'**
  String exerciseInProgressMsg(String current, String next);

  /// No description provided for @btnYesSwap.
  ///
  /// In pt, this message translates to:
  /// **'Sim, trocar'**
  String get btnYesSwap;

  /// No description provided for @makePermanentTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tornar troca permanente?'**
  String get makePermanentTitle;

  /// No description provided for @makePermanentMsg.
  ///
  /// In pt, this message translates to:
  /// **'Deseja substituir \"{original}\" por \"{replacement}\" no seu plano de treino?'**
  String makePermanentMsg(String original, String replacement);

  /// No description provided for @btnThisTimeOnly.
  ///
  /// In pt, this message translates to:
  /// **'Só desta vez'**
  String get btnThisTimeOnly;

  /// No description provided for @btnYesChangePlan.
  ///
  /// In pt, this message translates to:
  /// **'Sim, alterar plano'**
  String get btnYesChangePlan;

  /// No description provided for @errChangePlan.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível alterar o plano. Tente novamente.'**
  String get errChangePlan;

  /// No description provided for @workoutFinishedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Treino finalizado! 🎉'**
  String get workoutFinishedTitle;

  /// No description provided for @workoutSummaryLabel.
  ///
  /// In pt, this message translates to:
  /// **'📊 Resumo — {dayName}'**
  String workoutSummaryLabel(String dayName);

  /// No description provided for @statDuration.
  ///
  /// In pt, this message translates to:
  /// **'⏱️ Duração'**
  String get statDuration;

  /// No description provided for @statExercisesCompleted.
  ///
  /// In pt, this message translates to:
  /// **'🏆 Exercícios'**
  String get statExercisesCompleted;

  /// No description provided for @statVolume.
  ///
  /// In pt, this message translates to:
  /// **'⚖️ Volume'**
  String get statVolume;

  /// No description provided for @moodQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Como você se sentiu?'**
  String get moodQuestion;

  /// No description provided for @moodExhausted.
  ///
  /// In pt, this message translates to:
  /// **'Exausto'**
  String get moodExhausted;

  /// No description provided for @moodOk.
  ///
  /// In pt, this message translates to:
  /// **'Mais ou menos'**
  String get moodOk;

  /// No description provided for @moodGood.
  ///
  /// In pt, this message translates to:
  /// **'Bom / Rendimento ok'**
  String get moodGood;

  /// No description provided for @moodExcellent.
  ///
  /// In pt, this message translates to:
  /// **'Excelente / Superei limites!'**
  String get moodExcellent;

  /// No description provided for @moodCustomLabel.
  ///
  /// In pt, this message translates to:
  /// **'Outro emoji ou sentimento'**
  String get moodCustomLabel;

  /// No description provided for @moodCustomHelper.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 🥵 Destruído!'**
  String get moodCustomHelper;

  /// No description provided for @btnGenerateCard.
  ///
  /// In pt, this message translates to:
  /// **'Gerar card do treino'**
  String get btnGenerateCard;

  /// No description provided for @btnFinishWithoutCard.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar sem card'**
  String get btnFinishWithoutCard;

  /// No description provided for @currentWorkoutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meu Treino Atual'**
  String get currentWorkoutTitle;

  /// No description provided for @currentWorkoutNoWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum treino ativo.'**
  String get currentWorkoutNoWorkout;

  /// No description provided for @currentWorkoutPlanLabel.
  ///
  /// In pt, this message translates to:
  /// **'Seu plano'**
  String get currentWorkoutPlanLabel;

  /// No description provided for @currentWorkoutDaysExercises.
  ///
  /// In pt, this message translates to:
  /// **'{days} dias de treino · {exercises} exercícios'**
  String currentWorkoutDaysExercises(int days, int exercises);

  /// No description provided for @errLoadCurrentWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seu treino.'**
  String get errLoadCurrentWorkout;

  /// No description provided for @dayRecovery.
  ///
  /// In pt, this message translates to:
  /// **'Dia de recuperação'**
  String get dayRecovery;

  /// No description provided for @exercisesCountLabel.
  ///
  /// In pt, this message translates to:
  /// **'{n} exercícios'**
  String exercisesCountLabel(int n);

  /// No description provided for @exercisesCountWithCardio.
  ///
  /// In pt, this message translates to:
  /// **'{n} exercícios · com cardio'**
  String exercisesCountWithCardio(int n);

  /// No description provided for @swapExerciseTitle.
  ///
  /// In pt, this message translates to:
  /// **'Trocar Exercício'**
  String get swapExerciseTitle;

  /// No description provided for @swapExerciseSearching.
  ///
  /// In pt, this message translates to:
  /// **'Buscando alternativas para\n{name}...'**
  String swapExerciseSearching(String name);

  /// No description provided for @swapExerciseError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível buscar alternativas.\nTente novamente mais tarde.'**
  String get swapExerciseError;

  /// No description provided for @swapExerciseRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get swapExerciseRetry;

  /// No description provided for @swapNoAlternatives.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma alternativa encontrada para este exercício.'**
  String get swapNoAlternatives;

  /// No description provided for @swapAltSeries.
  ///
  /// In pt, this message translates to:
  /// **'{n} séries'**
  String swapAltSeries(String n);

  /// No description provided for @lastWorkoutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get lastWorkoutTitle;

  /// No description provided for @reportsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get reportsTitle;

  /// No description provided for @reportsYourReports.
  ///
  /// In pt, this message translates to:
  /// **'Seus relatórios'**
  String get reportsYourReports;

  /// No description provided for @reportLoadEvolution.
  ///
  /// In pt, this message translates to:
  /// **'Evolução de cargas'**
  String get reportLoadEvolution;

  /// No description provided for @reportLoadEvolutionDesc.
  ///
  /// In pt, this message translates to:
  /// **'Quanto suas cargas subiram em cada exercício'**
  String get reportLoadEvolutionDesc;

  /// No description provided for @reportBody.
  ///
  /// In pt, this message translates to:
  /// **'Medidas corporais'**
  String get reportBody;

  /// No description provided for @reportBodyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Peso, IMC e histórico de pesagens'**
  String get reportBodyDesc;

  /// No description provided for @reportVolume.
  ///
  /// In pt, this message translates to:
  /// **'Volume de treino'**
  String get reportVolume;

  /// No description provided for @reportVolumeDesc.
  ///
  /// In pt, this message translates to:
  /// **'Tonelagem levantada em cada treino'**
  String get reportVolumeDesc;

  /// No description provided for @reportFrequency.
  ///
  /// In pt, this message translates to:
  /// **'Frequência'**
  String get reportFrequency;

  /// No description provided for @reportFrequencyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Calendário do mês e treinos por semana'**
  String get reportFrequencyDesc;

  /// No description provided for @reportPlanPdf.
  ///
  /// In pt, this message translates to:
  /// **'Plano de treino (PDF)'**
  String get reportPlanPdf;

  /// No description provided for @reportPlanPdfDesc.
  ///
  /// In pt, this message translates to:
  /// **'Todos os dias e exercícios do seu plano'**
  String get reportPlanPdfDesc;

  /// No description provided for @errLoadWeeklySummary.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o resumo da semana.'**
  String get errLoadWeeklySummary;

  /// No description provided for @weeklySummaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo da semana'**
  String get weeklySummaryTitle;

  /// No description provided for @statWorkouts.
  ///
  /// In pt, this message translates to:
  /// **'Treinos'**
  String get statWorkouts;

  /// No description provided for @statTonnage.
  ///
  /// In pt, this message translates to:
  /// **'Tonelagem'**
  String get statTonnage;

  /// No description provided for @tonnageEvolutionUp.
  ///
  /// In pt, this message translates to:
  /// **'📈 +{pct}% de tonelagem vs. semana passada'**
  String tonnageEvolutionUp(String pct);

  /// No description provided for @tonnageEvolutionDown.
  ///
  /// In pt, this message translates to:
  /// **'📉 {pct}% de tonelagem vs. semana passada'**
  String tonnageEvolutionDown(String pct);

  /// No description provided for @assistantCameraError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível acessar a câmera/galeria. Verifique as permissões.'**
  String get assistantCameraError;

  /// No description provided for @assistantTakePhoto.
  ///
  /// In pt, this message translates to:
  /// **'Tirar foto do aparelho'**
  String get assistantTakePhoto;

  /// No description provided for @assistantChooseGallery.
  ///
  /// In pt, this message translates to:
  /// **'Escolher da galeria'**
  String get assistantChooseGallery;

  /// No description provided for @assistantTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tire suas dúvidas'**
  String get assistantTitle;

  /// No description provided for @assistantSearchMachine.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar máquina'**
  String get assistantSearchMachine;

  /// No description provided for @assistantPhotoTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Enviar foto de aparelho'**
  String get assistantPhotoTooltip;

  /// No description provided for @assistantSendTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get assistantSendTooltip;

  /// No description provided for @assistantInputHint.
  ///
  /// In pt, this message translates to:
  /// **'Escreva sua dúvida...'**
  String get assistantInputHint;

  /// No description provided for @assistantVideoBtn.
  ///
  /// In pt, this message translates to:
  /// **'Ver vídeos de execução'**
  String get assistantVideoBtn;

  /// No description provided for @assistantWelcome.
  ///
  /// In pt, this message translates to:
  /// **'Oi! 👋 Sou o assistente do PersonalIA. Pergunte sobre treino, exercícios, alimentação ou recuperação — ou mande a foto de um aparelho da academia que eu te digo qual exercício fazer nele. 📸'**
  String get assistantWelcome;

  /// No description provided for @editProfileTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar meu perfil'**
  String get editProfileTitle;

  /// No description provided for @editTrainingPrefsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Preferências de Treino'**
  String get editTrainingPrefsTitle;

  /// No description provided for @errLoadProfile.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seu perfil.'**
  String get errLoadProfile;

  /// No description provided for @errLoadPrefs.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar suas preferências.'**
  String get errLoadPrefs;

  /// No description provided for @profileFieldName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get profileFieldName;

  /// No description provided for @profileFieldGender.
  ///
  /// In pt, this message translates to:
  /// **'Gênero'**
  String get profileFieldGender;

  /// No description provided for @profileFieldBirthDate.
  ///
  /// In pt, this message translates to:
  /// **'Data de nascimento'**
  String get profileFieldBirthDate;

  /// No description provided for @profileFieldWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso (kg)'**
  String get profileFieldWeight;

  /// No description provided for @profileFieldHeight.
  ///
  /// In pt, this message translates to:
  /// **'Altura (cm)'**
  String get profileFieldHeight;

  /// No description provided for @profileFieldCpf.
  ///
  /// In pt, this message translates to:
  /// **'CPF (opcional)'**
  String get profileFieldCpf;

  /// No description provided for @profileFieldPhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get profileFieldPhone;

  /// No description provided for @profileFieldEmail.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get profileFieldEmail;

  /// No description provided for @profileGenderMale.
  ///
  /// In pt, this message translates to:
  /// **'Masculino'**
  String get profileGenderMale;

  /// No description provided for @profileGenderFemale.
  ///
  /// In pt, this message translates to:
  /// **'Feminino'**
  String get profileGenderFemale;

  /// No description provided for @profileSelectDate.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar data'**
  String get profileSelectDate;

  /// No description provided for @profilePhoneHelper.
  ///
  /// In pt, this message translates to:
  /// **'É o seu número do WhatsApp — identifica sua conta.'**
  String get profilePhoneHelper;

  /// No description provided for @profileEmailHelper.
  ///
  /// In pt, this message translates to:
  /// **'O email é o seu login e não pode ser alterado aqui.'**
  String get profileEmailHelper;

  /// No description provided for @profileSaved.
  ///
  /// In pt, this message translates to:
  /// **'Perfil atualizado ✅'**
  String get profileSaved;

  /// No description provided for @errSaveProfile.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar. Tente novamente.'**
  String get errSaveProfile;

  /// No description provided for @errProfileName.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu nome.'**
  String get errProfileName;

  /// No description provided for @errProfileGender.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o gênero.'**
  String get errProfileGender;

  /// No description provided for @errProfileBirthDate.
  ///
  /// In pt, this message translates to:
  /// **'Informe sua data de nascimento.'**
  String get errProfileBirthDate;

  /// No description provided for @errProfileWeight.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu peso em kg.'**
  String get errProfileWeight;

  /// No description provided for @errProfileHeight.
  ///
  /// In pt, this message translates to:
  /// **'Informe sua altura em cm.'**
  String get errProfileHeight;

  /// No description provided for @errProfileCpf.
  ///
  /// In pt, this message translates to:
  /// **'O CPF tem 11 dígitos.'**
  String get errProfileCpf;

  /// No description provided for @prefsFieldMinDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração mínima'**
  String get prefsFieldMinDuration;

  /// No description provided for @prefsFieldMaxDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração máxima'**
  String get prefsFieldMaxDuration;

  /// No description provided for @prefsFieldDaysPerWeek.
  ///
  /// In pt, this message translates to:
  /// **'Dias por semana'**
  String get prefsFieldDaysPerWeek;

  /// No description provided for @prefsFieldFocus.
  ///
  /// In pt, this message translates to:
  /// **'Foco do treino'**
  String get prefsFieldFocus;

  /// No description provided for @prefsFieldCardio.
  ///
  /// In pt, this message translates to:
  /// **'Cardio'**
  String get prefsFieldCardio;

  /// No description provided for @prefsFieldGymTime.
  ///
  /// In pt, this message translates to:
  /// **'Horário preferido'**
  String get prefsFieldGymTime;

  /// No description provided for @prefsSaved.
  ///
  /// In pt, this message translates to:
  /// **'Preferências salvas ✅'**
  String get prefsSaved;

  /// No description provided for @errSavePrefs.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar as preferências. Tente novamente.'**
  String get errSavePrefs;

  /// No description provided for @errOnboardingDurationRange.
  ///
  /// In pt, this message translates to:
  /// **'A duração máxima deve ser maior ou igual à mínima.'**
  String get errOnboardingDurationRange;

  /// No description provided for @errOnboardingChooseFocus.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o foco do treino.'**
  String get errOnboardingChooseFocus;

  /// No description provided for @errOnboardingGymTime.
  ///
  /// In pt, this message translates to:
  /// **'Horário inválido. Use HH:MM (ex.: 18:30).'**
  String get errOnboardingGymTime;

  /// No description provided for @restStatSeries.
  ///
  /// In pt, this message translates to:
  /// **'Séries'**
  String get restStatSeries;

  /// No description provided for @restStatReps.
  ///
  /// In pt, this message translates to:
  /// **'Repetições'**
  String get restStatReps;

  /// No description provided for @restStatRest.
  ///
  /// In pt, this message translates to:
  /// **'Descanso'**
  String get restStatRest;

  /// No description provided for @restStatLastWeight.
  ///
  /// In pt, this message translates to:
  /// **'Último peso'**
  String get restStatLastWeight;

  /// No description provided for @restStatLastObs.
  ///
  /// In pt, this message translates to:
  /// **'Última obs.'**
  String get restStatLastObs;

  /// No description provided for @restBtnVideos.
  ///
  /// In pt, this message translates to:
  /// **'Vídeos'**
  String get restBtnVideos;

  /// No description provided for @restBtnSwap.
  ///
  /// In pt, this message translates to:
  /// **'Trocar'**
  String get restBtnSwap;

  /// No description provided for @restFinishedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Descanso finalizado!'**
  String get restFinishedTitle;

  /// No description provided for @restInterExerciseMsg.
  ///
  /// In pt, this message translates to:
  /// **'Ótimo trabalho! Pronto para o próximo exercício.'**
  String get restInterExerciseMsg;

  /// No description provided for @restBtnNextExercise.
  ///
  /// In pt, this message translates to:
  /// **'Próximo exercício'**
  String get restBtnNextExercise;

  /// No description provided for @restSetFinishedMsg.
  ///
  /// In pt, this message translates to:
  /// **'Hora da próxima série!'**
  String get restSetFinishedMsg;

  /// No description provided for @restBtnLetsGo.
  ///
  /// In pt, this message translates to:
  /// **'Vamos lá!'**
  String get restBtnLetsGo;

  /// No description provided for @restTimerDone.
  ///
  /// In pt, this message translates to:
  /// **'Pronto!'**
  String get restTimerDone;

  /// No description provided for @restBtnReset.
  ///
  /// In pt, this message translates to:
  /// **'Reiniciar'**
  String get restBtnReset;

  /// No description provided for @restBtnStartInterExercise.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar descanso entre exercícios'**
  String get restBtnStartInterExercise;

  /// No description provided for @restBtnConfirmLastSet.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar última série'**
  String get restBtnConfirmLastSet;

  /// No description provided for @restBtnStartRest.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar descanso'**
  String get restBtnStartRest;

  /// No description provided for @restExerciseDone.
  ///
  /// In pt, this message translates to:
  /// **'Exercício concluído!'**
  String get restExerciseDone;

  /// No description provided for @restWeightLabel.
  ///
  /// In pt, this message translates to:
  /// **'Peso utilizado (kg)'**
  String get restWeightLabel;

  /// No description provided for @restObservationLabel.
  ///
  /// In pt, this message translates to:
  /// **'Observação (opcional)'**
  String get restObservationLabel;

  /// No description provided for @restWeightHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite o peso para finalizar'**
  String get restWeightHint;

  /// No description provided for @restBtnFinishExercise.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar exercício'**
  String get restBtnFinishExercise;

  /// No description provided for @restCardioLastTime.
  ///
  /// In pt, this message translates to:
  /// **'Último tempo'**
  String get restCardioLastTime;

  /// No description provided for @restCardioRunning.
  ///
  /// In pt, this message translates to:
  /// **'Em execução'**
  String get restCardioRunning;

  /// No description provided for @restCardioTapToStart.
  ///
  /// In pt, this message translates to:
  /// **'Toque para iniciar'**
  String get restCardioTapToStart;

  /// No description provided for @restCardioPaused.
  ///
  /// In pt, this message translates to:
  /// **'Pausado'**
  String get restCardioPaused;

  /// No description provided for @restCardioDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluído! ✅'**
  String get restCardioDone;

  /// No description provided for @restCardioGoalReached.
  ///
  /// In pt, this message translates to:
  /// **'Meta atingida! 🎉'**
  String get restCardioGoalReached;

  /// No description provided for @restBtnFinishCardio.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar cardio'**
  String get restBtnFinishCardio;

  /// No description provided for @restBtnCardioDone.
  ///
  /// In pt, this message translates to:
  /// **'Cardio concluído!'**
  String get restBtnCardioDone;

  /// No description provided for @historyEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não finalizou nenhum treino.'**
  String get historyEmpty;

  /// No description provided for @errLoadHistory.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o histórico.'**
  String get errLoadHistory;

  /// No description provided for @historyToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get historyToday;

  /// No description provided for @daySummaryExercises.
  ///
  /// In pt, this message translates to:
  /// **'exercícios'**
  String get daySummaryExercises;

  /// No description provided for @daySummarySeries.
  ///
  /// In pt, this message translates to:
  /// **'séries'**
  String get daySummarySeries;

  /// No description provided for @daySummaryCardio.
  ///
  /// In pt, this message translates to:
  /// **'cardio'**
  String get daySummaryCardio;

  /// No description provided for @dayHintTapForVideos.
  ///
  /// In pt, this message translates to:
  /// **'Toque em um exercício para ver vídeos de execução.'**
  String get dayHintTapForVideos;

  /// No description provided for @dayRecoveryMsg.
  ///
  /// In pt, this message translates to:
  /// **'Dia de recuperação — sem exercícios.'**
  String get dayRecoveryMsg;

  /// No description provided for @cardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Card do treino'**
  String get cardTitle;

  /// No description provided for @cardBtnRemovePhoto.
  ///
  /// In pt, this message translates to:
  /// **'Remover foto'**
  String get cardBtnRemovePhoto;

  /// No description provided for @cardBtnAddPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar foto'**
  String get cardBtnAddPhoto;

  /// No description provided for @cardBtnChangePhoto.
  ///
  /// In pt, this message translates to:
  /// **'Trocar foto'**
  String get cardBtnChangePhoto;

  /// No description provided for @cardBtnGenerating.
  ///
  /// In pt, this message translates to:
  /// **'Gerando...'**
  String get cardBtnGenerating;

  /// No description provided for @cardBtnShare.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get cardBtnShare;

  /// No description provided for @cardShareText.
  ///
  /// In pt, this message translates to:
  /// **'Treino {dayName} concluído! 💪 #PersonaliA'**
  String cardShareText(String dayName);

  /// No description provided for @cardStatExercises.
  ///
  /// In pt, this message translates to:
  /// **'Exercícios'**
  String get cardStatExercises;

  /// No description provided for @navHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navHome;

  /// No description provided for @navReports.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get navReports;

  /// No description provided for @navReferral.
  ///
  /// In pt, this message translates to:
  /// **'Indicar'**
  String get navReferral;

  /// No description provided for @navMenu.
  ///
  /// In pt, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @navAssistantTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Tirar dúvidas'**
  String get navAssistantTooltip;

  /// No description provided for @referralTitle.
  ///
  /// In pt, this message translates to:
  /// **'Indicar Amigo'**
  String get referralTitle;

  /// No description provided for @referralNotEligible.
  ///
  /// In pt, this message translates to:
  /// **'Você precisa de uma assinatura ativa pra indicar amigos.'**
  String get referralNotEligible;

  /// No description provided for @referralYourCoupon.
  ///
  /// In pt, this message translates to:
  /// **'Seu cupom'**
  String get referralYourCoupon;

  /// No description provided for @referralShareLink.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar link'**
  String get referralShareLink;

  /// No description provided for @errLoadReferral.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar.'**
  String get errLoadReferral;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
