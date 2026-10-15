import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/shared/widgets/app_pulse.dart';

Widget _host({bool disableAnimations = false, int beats = 2}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Center(
      child: AppPulse(
        beats: beats,
        child: const SizedBox(key: Key('box'), width: 100, height: 100),
      ),
    ),
  ),
);

/// Ancho ya pintado (con la escala): `getSize` solo da el del layout.
double _width(WidgetTester tester) {
  final box = find.byKey(const Key('box'));
  return tester.getBottomRight(box).dx - tester.getTopLeft(box).dx;
}

void main() {
  testWidgets('crece y vuelve a su tamaño, y se queda quieto al terminar', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    expect(_width(tester), 100);

    // Un latido dura 1100 ms: crece 550 y vuelve otros 550.
    await tester.pump(const Duration(milliseconds: 550));
    expect(_width(tester), greaterThan(100));

    await tester.pumpAndSettle(); // termina: no queda animación pendiente
    expect(_width(tester), 100);
  });

  testWidgets('sin beats late sin parar (hasta que se desmonta)', (
    tester,
  ) async {
    AppPulse.debugLoopForever = true;
    addTearDown(() => AppPulse.debugLoopForever = false);
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: AppPulse(
            scale: 1.1,
            child: SizedBox(key: Key('box'), width: 100, height: 100),
          ),
        ),
      ),
    );

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(tester.hasRunningAnimations, isTrue, reason: 'sigue latiendo');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('con «reducir movimiento» no se anima', (tester) async {
    await tester.pumpWidget(_host(disableAnimations: true));
    await tester.pump(const Duration(milliseconds: 1100));

    expect(_width(tester), 100);
  });
}
