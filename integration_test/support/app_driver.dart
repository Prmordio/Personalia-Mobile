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

  /// Digita como o usuário: toca no campo, espera o foco e o teclado assentarem e só então
  /// manda o texto para a conexão de teclado aberta.
  Future<void> enterText(Finder field, String text) async {
    await waitFor(field);
    await tester.ensureVisible(field.first);
    await tester.pump();
    // Guardado como elemento: com o teclado aberto o campo pode ficar atrás dele e os finders
    // (que pulam o que está fora da tela) deixam de achá-lo.
    final editable = find.descendant(of: field.first, matching: find.byType(EditableText)).evaluate().single;
    final controller = (editable.widget as EditableText).controller;
    final focusNode = (editable.widget as EditableText).focusNode;
    await tester.tap(field.first);
    // No aparelho real a troca de foco entre campos leva alguns frames; digitar antes disso
    // manda o texto para o campo que ainda tem a conexão de teclado (ex.: o anterior).
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!focusNode.hasFocus) {
      if (DateTime.now().isAfter(deadline)) fail('O campo $field não recebeu foco em 5s');
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _waitKeyboardSettled();
    tester.testTextInput.enterText(text);
    await tester.pump();
    expect(controller.text, text, reason: 'o texto caiu em outro campo');
  }

  /// O teclado do aparelho anima a abertura (e o app rola o campo para cima dele) em vários frames.
  Future<void> _waitKeyboardSettled() async {
    var last = -1.0;
    var stable = 0;
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (stable < 3 && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
      final inset = tester.view.viewInsets.bottom;
      stable = inset == last ? stable + 1 : 0;
      last = inset;
    }
  }

  /// Espera [finder] aparecer; se não aparece, rola a lista da tela do topo para baixo (listas
  /// preguiçosas só constroem o que está perto da área visível).
  Future<void> _waitForOrScroll(Finder finder, Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Não apareceu em ${timeout.inSeconds}s: $finder\nNa tela: ${visibleTexts()}');
      }
      final scrollable = onTopRoute(find.byType(Scrollable))
          .evaluate()
          .map((e) => (e as StatefulElement).state as ScrollableState)
          .where((s) => s.position.axis == Axis.vertical && s.position.extentAfter > 0)
          .firstOrNull;
      if (scrollable != null) {
        scrollable.position.jumpTo(scrollable.position.pixels + 300);
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  /// Rola a lista que contém [anchor] até [target] ser construído e ficar visível (listas
  /// preguiçosas não têm na árvore o que está fora da tela).
  Future<void> scrollTo(Finder target, {required Finder anchor}) async {
    await waitFor(anchor);
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.ancestor(of: anchor.first, matching: find.byType(Scrollable)).first,
    );
    await tester.pump();
  }

  /// Toca no texto, rolando até ele se preciso. Se o mesmo texto aparece mais de uma vez (ex.:
  /// título "Criar conta" e o botão "Criar conta"), toca no que está dentro de um botão.
  Future<void> tapText(String text, {Duration timeout = const Duration(seconds: 30)}) async {
    final finder = onTopRoute(find.text(text));
    await _waitForOrScroll(finder, timeout);
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
    await _dismissBiometricOffer(l);
  }

  /// Em aparelho com biometria (celular físico), a home abre o diálogo "Entrar com biometria?"
  /// logo após o login com senha; a barreira dele engoliria os toques seguintes do teste.
  Future<void> _dismissBiometricOffer(AppLocalizations l) async {
    await waitFor(find.text(l.navHome), timeout: const Duration(seconds: 45));
    final offer = find.text(l.biometricOfferTitle);
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (offer.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    if (offer.evaluate().isEmpty) return;
    await tapText(l.agoraNao);
    await waitForGone(offer);
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
