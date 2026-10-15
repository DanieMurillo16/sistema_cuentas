import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/shared/widgets/dot_separated_text.dart';

import '../../support/pump_at_sizes.dart';

Future<void> _pump(
  WidgetTester tester,
  List<String> parts, {
  double width = 300,
  double textScale = 1,
  TextStyle? style,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: DotSeparatedText(parts: parts, style: style),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('cada dato lleva « ·» pegado, menos el último', () {
    testWidgets('dos datos: «Suscripciones ·» y «24 oct.»', (tester) async {
      await _pump(tester, ['Suscripciones', '24 oct.']);

      expect(find.text('Suscripciones ·'), findsOneWidget);
      expect(find.text('24 oct.'), findsOneWidget);
      expect(find.text('Suscripciones · 24 oct.'), findsNothing);
    });

    testWidgets('tres datos: los dos primeros con punto', (tester) async {
      await _pump(tester, ['Arriendo', 'Día 7 · Cada mes', 'próximo 7 nov.']);

      expect(find.text('Arriendo ·'), findsOneWidget);
      expect(find.text('Día 7 · Cada mes ·'), findsOneWidget);
      expect(find.text('próximo 7 nov.'), findsOneWidget);
    });

    testWidgets('un solo dato: sin punto', (tester) async {
      await _pump(tester, ['Mercado']);

      expect(find.text('Mercado'), findsOneWidget);
      expect(find.textContaining('·'), findsNothing);
    });

    testWidgets('sin datos: no pinta nada y no falla', (tester) async {
      await _pump(tester, const []);

      expect(find.byType(Text), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un Text por dato', (tester) async {
      await _pump(tester, ['a', 'b', 'c', 'd']);

      expect(find.byType(Text), findsNWidgets(4));
    });
  });

  group('distribución', () {
    testWidgets('si caben, van en una sola línea y en orden', (tester) async {
      await _pump(tester, ['Suscripciones', '24 oct.'], width: 300);

      final first = tester.getTopLeft(find.text('Suscripciones ·'));
      final second = tester.getTopLeft(find.text('24 oct.'));
      expect(second.dy, first.dy, reason: 'misma línea');
      expect(second.dx, greaterThan(first.dx));
      expect(
        second.dx,
        greaterThan(tester.getTopRight(find.text('Suscripciones ·')).dx - 1),
      );
    });

    testWidgets('en 150 px la fecha pasa ENTERA a la línea de abajo', (
      tester,
    ) async {
      await _pump(tester, ['Suscripciones mensuales', '24 oct.'], width: 150);

      final what = tester.getRect(find.text('Suscripciones mensuales ·'));
      final date = tester.getRect(find.text('24 oct.'));
      expect(
        date.top,
        greaterThanOrEqualTo(what.bottom - 0.5),
        reason: 'debajo, no al lado',
      );
      // Entera: una sola línea (misma altura que una fecha suelta).
      final alone = await _heightOfLine(tester, '24 oct.');
      expect(date.height, closeTo(alone, 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('la fecha nunca se parte: aunque el ancho sea apenas el de la '
        'fecha, también con texto 1.5', (tester) async {
      for (final scale in [1.0, 1.5]) {
        await _pump(tester, ['24 oct.'], textScale: scale);
        final alone = tester.getSize(find.text('24 oct.'));
        // Ancho = el de la fecha + un poco: la anterior no cabe a su lado.
        await _pump(
          tester,
          ['Suscripciones', '24 oct.'],
          width: alone.width + 2,
          textScale: scale,
        );

        final date = tester.getRect(find.text('24 oct.'));
        expect(date.height, closeTo(alone.height, 0.5), reason: 'texto $scale');
        expect(date.width, closeTo(alone.width, 0.5), reason: 'texto $scale');
        expect(
          date.top,
          greaterThan(tester.getTopLeft(find.text('Suscripciones ·')).dy),
          reason: 'bajó entera',
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('tres datos en ancho justo: los que no caben bajan enteros', (
      tester,
    ) async {
      await _pump(tester, [
        'Arriendo de Oscar',
        'Día 7 · Cada mes',
        'próximo 7 nov.',
      ], width: 150);

      final tops = [
        tester.getTopLeft(find.text('Arriendo de Oscar ·')).dy,
        tester.getTopLeft(find.text('Día 7 · Cada mes ·')).dy,
        tester.getTopLeft(find.text('próximo 7 nov.')).dy,
      ];
      expect(tops[1], greaterThanOrEqualTo(tops[0]));
      expect(tops[2], greaterThanOrEqualTo(tops[1]));
      expect(tops.toSet().length, greaterThan(1), reason: 'hay varias líneas');
      for (final text in ['Día 7 · Cada mes ·', 'próximo 7 nov.']) {
        expect(
          tester.getSize(find.text(text)).width,
          lessThanOrEqualTo(150),
          reason: text,
        );
      }
    });

    testWidgets('usa el estilo recibido', (tester) async {
      await _pump(tester, [
        'a',
        'b',
      ], style: const TextStyle(fontSize: 20, color: Colors.red));

      for (final text in ['a ·', 'b']) {
        final style = tester.widget<Text>(find.text(text)).style!;
        expect(style.fontSize, 20);
        expect(style.color, Colors.red);
      }
    });

    testWidgets('sin estilo usa bodySmall del tema', (tester) async {
      await _pump(tester, ['a', 'b']);

      final expected = AppTheme.dark.textTheme.bodySmall!;
      expect(
        tester.widget<Text>(find.text('a ·')).style!.fontSize,
        expected.fontSize,
      );
    });
  });

  group('dato larguísimo (40+ caracteres)', () {
    const long =
        'Servicios públicos domiciliarios y otros conceptos varios del hogar';

    testWidgets('cabe envuelto en su propio dato, sin desbordar', (
      tester,
    ) async {
      await _pump(tester, [long, '24 oct.'], width: 150);

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.text('$long ·')).width,
        lessThanOrEqualTo(150),
      );
      expect(find.text('24 oct.'), findsOneWidget);
    });

    testWidgets('sin desbordes en 320/390/800/1300 × teclado × texto 1.5', (
      tester,
    ) async {
      await expectNoOverflow(
        tester,
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: DotSeparatedText(
              parts: [
                'Servicios públicos domiciliarios y otros conceptos varios del hogar',
                'Día 31 · Cada 12 meses',
                'próximo 31 dic.',
              ],
            ),
          ),
        ),
      );
    });
  });

  group('semántica', () {
    testWidgets('el lector dice los datos seguidos, separados por comas', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, ['Suscripciones', '24 oct.']);

      expect(find.bySemanticsLabel('Suscripciones, 24 oct.'), findsOneWidget);
      // Ni el «·» ni cada dato por separado.
      expect(find.bySemanticsLabel(RegExp('·')), findsNothing);
      expect(find.bySemanticsLabel('24 oct.'), findsNothing);
      handle.dispose();
    });

    testWidgets('tres datos: una sola etiqueta', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, ['Arriendo', 'Día 7 · Cada mes', 'próximo 7 nov.']);

      expect(
        find.bySemanticsLabel('Arriendo, Día 7 · Cada mes, próximo 7 nov.'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}

/// Alto de una línea de [text] con el mismo estilo.
Future<double> _heightOfLine(WidgetTester tester, String text) async {
  await _pump(tester, [text]);
  return tester.getSize(find.text(text)).height;
}
