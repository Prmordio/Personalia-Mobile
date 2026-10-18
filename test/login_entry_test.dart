import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/network/token_storage.dart';
import 'package:personalia_app/core/providers.dart';
import 'package:personalia_app/core/router/app_router.dart';
import 'package:personalia_app/features/auth/state/biometric_login_service.dart';
import 'package:personalia_app/features/auth/state/password_login_controller.dart';
import 'package:personalia_app/features/auth/data/auth_api.dart';
import 'package:personalia_app/features/onboarding/data/onboarding_api.dart';
import 'package:personalia_app/l10n/app_localizations.dart';

class _Storage extends TokenStorage {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> save(String value) async {
    token = value;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}

class _Biometrics extends Fake implements BiometricLoginService {
  bool enabled = false;
  Completer<bool>? pending;
  int calls = 0;
  @override
  Future<bool> isEnabled() => pending?.future ?? Future.value(enabled);
  @override
  Future<BiometricLoginResult> login() async {
    calls++;
    return BiometricLoginResult.cancelled;
  }
}

class _IncompleteProfile extends OnboardingApi {
  _IncompleteProfile() : super(Dio());
  @override
  Future<OnboardingStatus> getStatus() async => OnboardingStatus(
    profile: OnboardingProfile(email: 'test@example.com'),
    disclaimerAccepted: false,
    anamnesis: null,
    trainingPreferences: null,
    nextStep: 'PROFILE',
    completed: false,
  );
}

void main() {
  testWidgets(
    'an incomplete saved session can return from registration to email login',
    (tester) async {
      final storage = _Storage()..token = 'existing-session';
      final refresh = ValueNotifier<int>(0);
      final api = _IncompleteProfile();
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          authRefreshProvider.overrideWithValue(refresh),
          onboardingApiProvider.overrideWithValue(api),
          biometricLoginServiceProvider.overrideWithValue(_Biometrics()),
          passwordLoginControllerProvider.overrideWith(
            (ref) => PasswordLoginController(AuthApi(Dio()), storage, refresh),
          ),
        ],
      );
      final router = buildRouter(
        tokenStorage: storage,
        refresh: refresh,
        onboardingApi: api,
      );
      final l = lookupAppLocalizations(const Locale('en'));
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/onboarding');
        expect(find.text(l.onboardingProfileFormTitle), findsOneWidget);
        await tester.tap(find.text(l.onboardingBackToLogin));
        await tester.pumpAndSettle();
        expect(storage.token, isNull);
        expect(router.routeInformationProvider.value.uri.path, '/login');
        expect(find.text(l.passwordLoginTitle), findsOneWidget);
        expect(find.text(l.loginCreateAccount), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        container.dispose();
        refresh.dispose();
      }
    },
  );

  for (final language in ['pt', 'en', 'es']) {
    testWidgets(
      'anonymous entry opens email login directly with account creation ($language)',
      (tester) async {
        final storage = _Storage();
        final refresh = ValueNotifier<int>(0);
        final biometrics = _Biometrics();
        final container = ProviderContainer(
          overrides: [
            tokenStorageProvider.overrideWithValue(storage),
            biometricLoginServiceProvider.overrideWithValue(biometrics),
            passwordLoginControllerProvider.overrideWith(
              (ref) =>
                  PasswordLoginController(AuthApi(Dio()), storage, refresh),
            ),
          ],
        );
        final router = buildRouter(
          tokenStorage: storage,
          refresh: refresh,
          onboardingApi: OnboardingApi(Dio()),
        );
        final l = lookupAppLocalizations(Locale(language));
        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                routerConfig: router,
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, '/login');
          expect(find.text(l.passwordLoginTitle), findsOneWidget);
          expect(find.text(l.loginCreateAccount), findsOneWidget);
          expect(find.text(l.welcomeWhatsAppButton), findsNothing);
          expect(find.byType(TextField), findsNWidgets(2));
          await tester.tap(find.text(l.loginCreateAccount));
          await tester.pumpAndSettle();
          expect(find.text(l.loginCreateProfileTitle), findsOneWidget);
          expect(find.text(l.loginSyncTitle), findsNothing);
          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
          await tester.tap(find.text(l.forgotPasswordLink));
          await tester.pumpAndSettle();
          expect(find.text(l.forgotPasswordTitle), findsOneWidget);
          expect(find.text(l.appAccessTitle), findsNothing);
          for (final oldPath in ['/login/password', '/login/access']) {
            router.go(oldPath);
            await tester.pumpAndSettle();
            expect(router.routeInformationProvider.value.uri.path, '/login');
            expect(find.text(l.passwordLoginTitle), findsOneWidget);
          }
          router.go('/login/phone');
          await tester.pumpAndSettle();
          expect(
            router.routeInformationProvider.value.uri.path,
            '/login/register',
          );
          expect(find.text(l.loginCreateProfileTitle), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          router.dispose();
          container.dispose();
          refresh.dispose();
        }
      },
    );
  }

  testWidgets('a late biometric check does not interrupt account creation', (
    tester,
  ) async {
    final storage = _Storage();
    final refresh = ValueNotifier<int>(0);
    final biometrics = _Biometrics()..pending = Completer<bool>();
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        biometricLoginServiceProvider.overrideWithValue(biometrics),
        passwordLoginControllerProvider.overrideWith(
          (ref) => PasswordLoginController(AuthApi(Dio()), storage, refresh),
        ),
      ],
    );
    final router = buildRouter(
      tokenStorage: storage,
      refresh: refresh,
      onboardingApi: OnboardingApi(Dio()),
    );
    final l = lookupAppLocalizations(const Locale('en'));
    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.loginCreateAccount));
      await tester.pumpAndSettle();
      biometrics.pending!.complete(true);
      await tester.pumpAndSettle();
      expect(biometrics.calls, 0);
      expect(find.text(l.loginCreateProfileTitle), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      container.dispose();
      refresh.dispose();
    }
  });

  testWidgets('saved biometrics still prompt on the direct login screen', (
    tester,
  ) async {
    final storage = _Storage();
    final refresh = ValueNotifier<int>(0);
    final biometrics = _Biometrics()..enabled = true;
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        biometricLoginServiceProvider.overrideWithValue(biometrics),
        passwordLoginControllerProvider.overrideWith(
          (ref) => PasswordLoginController(AuthApi(Dio()), storage, refresh),
        ),
      ],
    );
    final router = buildRouter(
      tokenStorage: storage,
      refresh: refresh,
      onboardingApi: OnboardingApi(Dio()),
    );
    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(biometrics.calls, 1);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(router.routeInformationProvider.value.uri.path, '/login');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      container.dispose();
      refresh.dispose();
    }
  });
}
