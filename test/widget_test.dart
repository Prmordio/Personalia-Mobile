import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personalia_app/main.dart' as app;

void main() {
  testWidgets('App renders before native services finish', (
    WidgetTester tester,
  ) async {
    await app.main();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
