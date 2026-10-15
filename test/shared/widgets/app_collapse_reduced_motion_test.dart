import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/shared/widgets/app_collapse.dart';

Future<void> _toggleTwice(WidgetTester tester, {required bool noMotion}) async {
  var visible = false;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: noMotion),
        child: child!,
      ),
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: Column(
            children: [
              TextButton(
                onPressed: () => setState(() => visible = !visible),
                child: const Text('alternar'),
              ),
              AppCollapse(
                visible: visible,
                child: const SizedBox(height: 100, child: Text('contenido')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('alternar'));
  await tester.pumpAndSettle();
  expect(find.text('contenido'), findsOneWidget);
  await tester.tap(find.text('alternar'));
  await tester.pumpAndSettle();
  expect(find.text('contenido'), findsNothing);
}

void main() {
  testWidgets('con animaciones: abre y cierra sin excepciones', (tester) async {
    await _toggleTwice(tester, noMotion: false);
    expect(tester.takeException(), isNull);
  });

  // Antes lanzaba «RenderAnimatedSize was mutated in its own performLayout»
  // (duración cero en AnimatedSize); ya está corregido.
  testWidgets('con «reducir movimiento»: abre y cierra sin excepciones', (
    tester,
  ) async {
    await _toggleTwice(tester, noMotion: true);
    expect(tester.takeException(), isNull);
  });
}
