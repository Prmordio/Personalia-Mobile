import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/workout/presentation/widgets/live_activity_hint.dart';
import 'package:personalia_app/features/workout/state/live_activity_permission.dart';
import 'package:personalia_app/l10n/app_localizations.dart';

class FakeGateway implements LiveActivityPermissionGateway {
  FakeGateway(this.current);
  LiveActivityStatus current;
  int settingsOpened = 0;

  @override
  Future<LiveActivityStatus> status() async => current;

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class MemoryStore implements LiveActivityHintStore {
  bool dismissed = false;

  @override
  Future<bool> isDismissed() async => dismissed;

  @override
  Future<void> dismiss() async => dismissed = true;
}

typedef Tracked = ({String name, Map<String, Object?> params});

void main() {
  group('LiveActivityHintController', () {
    late FakeGateway gateway;
    late MemoryStore store;
    late List<Tracked> events;
    late LiveActivityHintController controller;

    setUp(() {
      gateway = FakeGateway(LiveActivityStatus.disabled);
      store = MemoryStore();
      events = [];
      controller = LiveActivityHintController(
        gateway: gateway,
        store: store,
        track: (name, params) => events.add((name: name, params: params)),
      );
    });

    test('mostra o aviso quando a permissão está desligada', () async {
      await controller.refresh();
      expect(controller.state, isTrue);
    });

    test('não mostra quando habilitado ou sem suporte (Android/iOS < 17)', () async {
      for (final status in [
        LiveActivityStatus.enabled,
        LiveActivityStatus.unsupported,
      ]) {
        gateway.current = status;
        await controller.refresh();
        expect(controller.state, isFalse, reason: '$status');
      }
      expect(events, isEmpty);
    });

    test('some sozinho quando o usuário ativa nos Ajustes', () async {
      await controller.refresh();
      gateway.current = LiveActivityStatus.enabled;
      await controller.refresh();
      expect(controller.state, isFalse);
    });

    test('dispensar esconde e persiste, sem voltar no próximo refresh', () async {
      await controller.refresh();
      await controller.dismiss();
      expect(controller.state, isFalse);
      expect(store.dismissed, isTrue);
      await controller.refresh();
      expect(controller.state, isFalse);
    });

    test('telemetria: live_activity_disabled só uma vez por sessão', () async {
      await controller.refresh();
      await controller.refresh();
      expect(
        events.where((e) => e.name == 'live_activity_disabled'),
        hasLength(1),
      );
    });

    test('telemetria das ações do aviso', () async {
      await controller.openSettings();
      await controller.dismiss();
      expect(gateway.settingsOpened, 1);
      expect(
        events
            .where((e) => e.name == 'live_activity_hint_action')
            .map((e) => e.params['action']),
        ['open_settings', 'dismiss'],
      );
    });
  });

  group('LiveActivityHint widget', () {
    Future<(FakeGateway, MemoryStore)> pump(
      WidgetTester tester,
      LiveActivityStatus status,
    ) async {
      final gateway = FakeGateway(status);
      final store = MemoryStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveActivityPermissionGatewayProvider.overrideWithValue(gateway),
            liveActivityHintStoreProvider.overrideWithValue(store),
          ],
          child: const MaterialApp(
            locale: Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: LiveActivityHint()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (gateway, store);
    }

    testWidgets('exibe o aviso e abre os Ajustes', (tester) async {
      final (gateway, _) = await pump(tester, LiveActivityStatus.disabled);
      expect(find.byKey(const ValueKey('live-activity-hint')), findsOneWidget);
      await tester.tap(find.text('Ativar'));
      await tester.pump();
      expect(gateway.settingsOpened, 1);
    });

    testWidgets('não mostrar de novo esconde o aviso', (tester) async {
      final (_, store) = await pump(tester, LiveActivityStatus.disabled);
      await tester.tap(find.text('Não mostrar de novo'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('live-activity-hint')), findsNothing);
      expect(store.dismissed, isTrue);
    });

    testWidgets('rechecagem ao voltar ao app esconde se foi ativado', (tester) async {
      final (gateway, _) = await pump(tester, LiveActivityStatus.disabled);
      gateway.current = LiveActivityStatus.enabled;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('live-activity-hint')), findsNothing);
    });

    testWidgets('nada aparece com permissão ativa', (tester) async {
      await pump(tester, LiveActivityStatus.enabled);
      expect(find.byKey(const ValueKey('live-activity-hint')), findsNothing);
    });
  });
}
