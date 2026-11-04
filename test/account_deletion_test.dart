import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/locale/locale_controller.dart';
import 'package:personalia_app/core/network/token_storage.dart';
import 'package:personalia_app/core/security/biometric_credential_storage.dart';
import 'package:personalia_app/core/theme/theme_mode_controller.dart';
import 'package:personalia_app/features/account/state/account_deletion_service.dart';
import 'package:personalia_app/features/auth/data/auth_api.dart';
import 'package:personalia_app/features/auth/state/biometric_login_service.dart';
import 'package:personalia_app/features/menu/presentation/menu_screen.dart';
import 'package:personalia_app/l10n/app_localizations.dart';

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi() : super(Dio());

  int deleteCalls = 0;
  bool fail = false;

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(path: '/app/account'),
        response: Response(requestOptions: RequestOptions(path: '/app/account'), statusCode: 500),
      );
    }
  }
}

class _MemoryCredentialStorage extends BiometricCredentialStorage {
  BiometricCredential? value = const BiometricCredential(credentialId: 'c', token: 't');

  @override
  Future<BiometricCredential?> read() async => value;

  @override
  Future<void> clear() async => value = null;
}

class _MemoryTokenStorage extends TokenStorage {
  String? token = 'jwt';

  @override
  Future<String?> read() async => token;

  @override
  Future<void> clear() async => token = null;
}

class _MemoryPrefs implements ThemePreferenceStore, LocalePreferenceStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String value) async {}
}

class _NoBiometrics extends Fake implements BiometricLoginService {
  @override
  Future<bool> isEnabled() async => false;

  @override
  Future<bool> canEnable() async => false;
}

void main() {
  late _FakeAuthApi api;
  late _MemoryCredentialStorage credentials;
  late _MemoryTokenStorage tokens;
  late ValueNotifier<int> refresh;
  late AccountDeletionService service;

  setUp(() {
    api = _FakeAuthApi();
    credentials = _MemoryCredentialStorage();
    tokens = _MemoryTokenStorage();
    refresh = ValueNotifier(0);
    service = AccountDeletionService(api, credentials, tokens, refresh);
  });

  group('AccountDeletionService', () {
    test('should_delete_on_backend_then_clear_session_and_signal_logout', () async {
      await service.deleteAccount();

      expect(api.deleteCalls, 1);
      expect(tokens.token, isNull);
      expect(credentials.value, isNull);
      expect(refresh.value, 1);
    });

    test('should_keep_session_when_backend_fails', () async {
      api.fail = true;

      await expectLater(service.deleteAccount(), throwsA(isA<DioException>()));

      expect(tokens.token, 'jwt');
      expect(credentials.value, isNotNull);
      expect(refresh.value, 0);
    });
  });

  group('Menu delete account', () {
    Future<void> pumpMenu(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountDeletionServiceProvider.overrideWithValue(service),
            biometricLoginServiceProvider.overrideWithValue(_NoBiometrics()),
            themeModeProvider.overrideWith((ref) => ThemeModeController(_MemoryPrefs())),
            localeProvider.overrideWith((ref) => LocaleController(_MemoryPrefs())),
          ],
          child: const MaterialApp(
            locale: Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MenuScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('cancel in the confirmation modal does not delete', (tester) async {
      await pumpMenu(tester);

      await tester.tap(find.byKey(const Key('menu-delete-account')));
      await tester.pumpAndSettle();
      expect(find.text('Excluir sua conta?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, 0);
      expect(tokens.token, 'jwt');
    });

    testWidgets('confirming in the modal deletes the account and signs out', (tester) async {
      await pumpMenu(tester);

      await tester.tap(find.byKey(const Key('menu-delete-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete-account-confirm')));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, 1);
      expect(tokens.token, isNull);
      expect(refresh.value, 1);
      expect(find.text('Sua conta foi excluída.'), findsOneWidget);
    });

    testWidgets('backend failure shows an error and keeps the user signed in', (tester) async {
      api.fail = true;
      await pumpMenu(tester);

      await tester.tap(find.byKey(const Key('menu-delete-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete-account-confirm')));
      await tester.pumpAndSettle();

      expect(tokens.token, 'jwt');
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Não foi possível excluir sua conta. Tente novamente.'), findsOneWidget);
    });
  });
}
