import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/network/token_storage.dart';
import 'package:personalia_app/l10n/app_localizations.dart';
import 'package:personalia_app/main.dart' as app;

/// Ações comuns dos testes integrados sobre o app real (main.dart, backend local).
///
/// `pumpAndSettle` não serve aqui: o app tem animações e timers contínuos (spinners, cronômetro
/// do descanso), então ele nunca "assenta". Tudo espera por um finder com prazo.
class AppDriver {
  AppDriver(this.tester);
  final WidgetTester tester;

  /// Abre o app deslogado (sem token salvo) e espera a tela de login.
  Future<void> launchLoggedOut() async {
    await TokenStorage().clear();
    app.main();
    await waitFor(find.byType(TextField), timeout: const Duration(seconds: 60));
  }

  /// Textos do app no idioma em que ele está rodando (o do emulador).
  AppLocalizations get l10n => AppLocalizations.of(tester.element(find.byType(Scaffold).first));

  Future<void> waitFor(Finder finder, {Duration timeout = const Duration(seconds: 30)}) async {
    final deadline = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Não apareceu em ${timeout.inSeconds}s: $finder\nNa tela: ${visibleTexts()}');
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> waitForGone(Finder finder, {Duration timeout = const Duration(seconds: 30)}) async {
    final deadline = DateTime.now().add(timeout);
    while (finder.evaluate().isNotEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Não sumiu em ${timeout.inSeconds}s: $finder');
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  /// Textos na tela agora — vai na mensagem de falha para saber onde o fluxo parou.
  List<String> visibleTexts() => find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText() ?? '')
      .where((t) => t.trim().isNotEmpty)
      .toList();

  /// Deixa o app rodar por [duration] (timers reais, chamadas de rede).
  Future<void> idle(Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Finder fieldWithHint(String hint) => onTopRoute(find.byWidgetPredicate(
        (w) => w is TextField && (w.decoration?.hintText == hint || w.decoration?.labelText == hint),
        description: 'TextField "$hint"',
      ));

  /// Só o que está na rota do topo: a tela de baixo (ex.: o login, sob o cadastro) continua na
  /// árvore com campos e botões iguais, e `.first` pegaria o dela.
  Finder onTopRoute(Finder finder) => _OnTopRoute(finder);

  Future<void> enterText(Finder field, String text) async {
    await waitFor(field);
    await tester.ensureVisible(field.first);
    await tester.enterText(field.first, text);
    await tester.pump();
  }

  /// Toca no texto, rolando até ele se preciso. Se o mesmo texto aparece mais de uma vez (ex.:
  /// título "Criar conta" e o botão "Criar conta"), toca no que está dentro de um botão.
  Future<void> tapText(String text, {Duration timeout = const Duration(seconds: 30)}) async {
    final finder = onTopRoute(find.text(text));
    await waitFor(finder, timeout: timeout);
    final elements = finder.evaluate().toList();
    final index = elements.indexWhere(_isInsideTappable);
    final target = finder.at(index < 0 ? 0 : index);
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await tester.pump(const Duration(milliseconds: 300));
  }

  static bool _isInsideTappable(Element element) {
    var tappable = false;
    element.visitAncestorElements((ancestor) {
      final w = ancestor.widget;
      tappable = w is ButtonStyleButton || w is InkWell || w is IconButton || w is ListTile;
      return !tappable && w is! Scaffold;
    });
    return tappable;
  }

  /// Texto de erro/mensagem visível na tela (ex.: mensagem que veio do backend).
  Future<void> expectText(String text, {Duration timeout = const Duration(seconds: 30)}) async {
    await waitFor(find.textContaining(text), timeout: timeout);
  }

  Future<void> loginWithPassword(String email, String password) async {
    final l = l10n;
    await enterText(fieldWithHint(l.onboardingEmailHint), email);
    await enterText(fieldWithHint(l.passwordHint), password);
    await tapText(l.entrar);
  }
}

class _OnTopRoute extends ChainedFinder {
  _OnTopRoute(super.parent);

  @override
  String get description => '${parent.describeMatch(Plurality.many)} na rota do topo';

  @override
  Iterable<Element> filter(Iterable<Element> parentCandidates) =>
      parentCandidates.where((e) => ModalRoute.of(e)?.isCurrent ?? true);
}
