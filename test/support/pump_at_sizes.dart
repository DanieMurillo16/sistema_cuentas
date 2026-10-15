import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';

/// Anchos que toda vista debe resistir: teléfono pequeño, teléfono, tablet y
/// escritorio (ver ~/.claude/flutter-base/responsive.md).
const testWidths = [320.0, 390.0, 800.0, 1300.0];

/// Alturas de teclado: cerrado y abierto.
const testKeyboards = [0.0, 300.0];

/// Escalas de texto: normal y ampliado.
const testTextScales = [1.0, 1.5];

/// Monta [view] en cada combinación de ancho × teclado × escala de texto y
/// falla si Flutter lanza cualquier excepción. Un `RenderFlex overflowed` ES una
/// excepción real, así que esto detecta desbordes de verdad.
///
/// [overrides] sustituye repositorios y providers por falsos. [retry] fija el
/// reintento de Riverpod (`(_, _) => null` para no reintentar los errores).
/// [afterPump] corre tras montar la vista en cada combinación (p. ej. para
/// tocar un despegable) y antes de comprobar que no hubo excepciones.
/// [freshStateEachTime] desmonta la vista entre combinaciones, para que el
/// estado efímero (despegables abiertos) no pase de una a otra.
Future<void> expectNoOverflow(
  WidgetTester tester,
  Widget view, {
  List<Override> overrides = const [],
  double height = 700,
  List<double> widths = testWidths,
  List<double> keyboards = testKeyboards,
  List<double> scales = testTextScales,
  bool settle = true,
  Future<void> Function(WidgetTester tester)? afterPump,
  bool freshStateEachTime = false,
  ThemeData? theme,
  Duration? Function(int retryCount, Object error)? retry,
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  for (final width in widths) {
    tester.view.physicalSize = Size(width, height);
    for (final keyboard in keyboards) {
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      for (final scale in scales) {
        if (freshStateEachTime) await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            retry: retry,
            child: MaterialApp(
              theme: theme ?? AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: view,
            ),
          ),
        );
        // Con un cargador infinito (`CircularProgressIndicator`) no hay
        // "reposo": `settle: false` avanza un tiempo fijo.
        if (settle) {
          await tester.pumpAndSettle();
        } else {
          await tester.pump(const Duration(milliseconds: 300));
        }
        if (afterPump != null) await afterPump(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: '$width px · teclado $keyboard · texto $scale',
        );
      }
    }
  }
}
