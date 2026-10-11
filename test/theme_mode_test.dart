import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/theme/app_theme.dart';
import 'package:personalia_app/core/theme/theme_mode_controller.dart';
import 'package:personalia_app/main.dart';

class _Store implements ThemePreferenceStore {
  _Store([this.value]);
  String? value;
  bool failWrites = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    if (failWrites) throw StateError('Unavailable');
    this.value = value;
  }
}

void main() {
  test(
    'defaults to system, restores dark and persists another selection',
    () async {
      final store = _Store('dark');
      final controller = ThemeModeController(store);
      expect(controller.state, ThemeMode.system);
      await controller.load();
      expect(controller.state, ThemeMode.dark);
      await controller.select(ThemeMode.light);
      expect(store.value, 'light');
      final restored = ThemeModeController(store);
      await restored.load();
      expect(restored.state, ThemeMode.light);
      controller.dispose();
      restored.dispose();
    },
  );

  test(
    'invalid preferences fall back and failed writes preserve current theme',
    () async {
      final store = _Store('invalid');
      final controller = ThemeModeController(store);
      await controller.load();
      expect(controller.state, ThemeMode.system);
      store.failWrites = true;
      await expectLater(controller.select(ThemeMode.dark), throwsStateError);
      expect(controller.state, ThemeMode.system);
      controller.dispose();
    },
  );

  testWidgets(
    'app changes to dark and then light without recreating its root',
    (tester) async {
      final controller = ThemeModeController(_Store());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [themeModeProvider.overrideWith((ref) => controller)],
          child: const PersonaliaApp(),
        ),
      );
      await controller.select(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      await controller.select(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('dark surfaces and readable text have sufficient contrast', () {
    final scheme = AppTheme.dark().colorScheme;
    final contrast =
        (scheme.onSurface.computeLuminance() + 0.05) /
        (scheme.surface.computeLuminance() + 0.05);
    expect(contrast, greaterThanOrEqualTo(4.5));
  });
}
