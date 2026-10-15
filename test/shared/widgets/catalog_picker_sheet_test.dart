import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_footer.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_header.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_option.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_row.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_sheet.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/pump_at_sizes.dart';

CatalogPickerOption<String> _option(String label) => CatalogPickerOption(
  value: label,
  label: label,
  icon: Icons.category_outlined,
  color: AppColors.accent,
);

List<CatalogPickerOption<String>> _names(Iterable<String> labels) => [
  for (final label in labels) _option(label),
];

/// Cuarenta opciones, con nombres largos de 40+ caracteres entre ellas.
List<CatalogPickerOption<String>> _many() => _names([
  for (var i = 1; i <= 38; i++) 'Categoría $i',
  longCatalogName,
  'Desarrollo de software',
]);

final _sheet = find.byWidgetPredicate((w) => w is CatalogPickerSheet);
Finder get _search => find.byType(TextField);
Finder _row(String label) => find.byKey(ValueKey('option-$label'));
Finder _chip(String label) => find.byKey(ValueKey('frequent-$label'));

/// Abre el selector con `showModalBottomSheet`, como en la app, en cuanto se
/// pinta la pantalla. Lo que devuelve el selector queda en [onClosed].
class _PickerHost extends StatefulWidget {
  const _PickerHost({
    required this.options,
    this.frequent = const [],
    this.selected,
    this.onCreate,
    this.onClosed,
  });

  final List<CatalogPickerOption<String>> options;
  final List<CatalogPickerOption<String>> frequent;
  final String? selected;
  final Future<String?> Function()? onCreate;
  final ValueChanged<String?>? onClosed;

  @override
  State<_PickerHost> createState() => _PickerHostState();
}

class _PickerHostState extends State<_PickerHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showCatalogPicker<String>(
        context,
        title: 'Categoría',
        createLabel: 'Nueva categoría',
        options: widget.options,
        frequent: widget.frequent,
        selected: widget.selected,
        onCreate: widget.onCreate,
      ).then((value) => widget.onClosed?.call(value));
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.expand());
}

Future<void> _open(
  WidgetTester tester,
  _PickerHost host, {
  double width = 390,
  double height = 700,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: host));
  await tester.pumpAndSettle();
}

void main() {
  group('buscador y frecuentes', () {
    final options = _names(['Alimentación', 'Transporte', 'Salud']);
    final frequent = _names(['Transporte']);

    testWidgets('sin buscar: «Frecuentes» y «Todas»; al buscar se ocultan', (
      tester,
    ) async {
      await _open(tester, _PickerHost(options: options, frequent: frequent));

      expect(find.text('FRECUENTES'), findsOneWidget);
      expect(_chip('Transporte'), findsOneWidget);
      expect(find.text('TODAS'), findsOneWidget);
      expect(_row('Alimentación'), findsOneWidget);

      // Sin tildes ni mayúsculas, como lo escribe la persona.
      await tester.enterText(_search, 'alimentacion');
      await tester.pumpAndSettle();
      expect(find.text('FRECUENTES'), findsNothing);
      expect(_chip('Transporte'), findsNothing);
      expect(find.text('RESULTADOS'), findsOneWidget);
      expect(_row('Alimentación'), findsOneWidget);
      expect(_row('Salud'), findsNothing);

      await tester.enterText(_search, '');
      await tester.pumpAndSettle();
      expect(find.text('FRECUENTES'), findsOneWidget);
    });

    testWidgets('sin coincidencias: «Sin resultados»', (tester) async {
      await _open(tester, _PickerHost(options: options, frequent: frequent));

      await tester.enterText(_search, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('Sin resultados'), findsOneWidget);
      expect(find.byType(CatalogPickerRow), findsNothing);
    });

    testWidgets('sin frecuentes no hay sección ni título', (tester) async {
      await _open(tester, _PickerHost(options: options));

      expect(find.text('FRECUENTES'), findsNothing);
      expect(find.text('TODAS'), findsOneWidget);
    });

    testWidgets('la opción elegida lleva marca', (tester) async {
      await _open(tester, _PickerHost(options: options, selected: 'Salud'));

      expect(
        find.descendant(
          of: _row('Salud'),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _row('Transporte'),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsNothing,
      );
    });
  });

  group('lo que devuelve', () {
    final options = _names(['Alimentación', 'Transporte']);

    testWidgets('tocar una fila devuelve su valor y cierra la hoja', (
      tester,
    ) async {
      String? result;
      var closed = false;
      await _open(
        tester,
        _PickerHost(
          options: options,
          onClosed: (value) {
            result = value;
            closed = true;
          },
        ),
      );

      await tester.tap(_row('Transporte'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, 'Transporte');
      expect(_sheet, findsNothing);
    });

    testWidgets('tocar una frecuente devuelve su valor', (tester) async {
      String? result;
      await _open(
        tester,
        _PickerHost(
          options: options,
          frequent: _names(['Alimentación']),
          onClosed: (value) => result = value,
        ),
      );

      await tester.tap(_chip('Alimentación'));
      await tester.pumpAndSettle();

      expect(result, 'Alimentación');
    });

    testWidgets('cerrar sin elegir devuelve null', (tester) async {
      String? result = 'sin tocar';
      await _open(
        tester,
        _PickerHost(options: options, onClosed: (value) => result = value),
      );

      await tester.tapAt(const Offset(195, 20)); // el velo, fuera de la hoja
      await tester.pumpAndSettle();

      expect(_sheet, findsNothing);
      expect(result, isNull);
    });
  });

  group('«Nueva …» (onCreate)', () {
    final options = _names(['Alimentación']);
    Finder create() => find.text('Nueva categoría');

    testWidgets('si devuelve lo creado, la hoja se cierra con ello', (
      tester,
    ) async {
      String? result;
      var calls = 0;
      await _open(
        tester,
        _PickerHost(
          options: options,
          onCreate: () async {
            calls++;
            return 'Mascotas';
          },
          onClosed: (value) => result = value,
        ),
      );

      await tester.tap(create());
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(result, 'Mascotas');
      expect(_sheet, findsNothing);
    });

    testWidgets('si devuelve null (se canceló), la hoja sigue abierta', (
      tester,
    ) async {
      var closed = false;
      await _open(
        tester,
        _PickerHost(
          options: options,
          onCreate: () async => null,
          onClosed: (_) => closed = true,
        ),
      );

      await tester.tap(create());
      await tester.pumpAndSettle();

      expect(closed, isFalse);
      expect(_sheet, findsOneWidget);
      expect(create(), findsOneWidget);
    });

    testWidgets('sin onCreate no hay botón', (tester) async {
      await _open(tester, _PickerHost(options: options));

      expect(create(), findsNothing);
      expect(
        tester
            .widget<CatalogPickerFooter>(find.byType(CatalogPickerFooter))
            .onCreate,
        isNull,
      );
    });
  });

  group('alto de la hoja', () {
    /// Alto que ocupa el contenido de la hoja (sin el hueco del teclado).
    double contentHeight(WidgetTester tester, double keyboard) =>
        tester.getSize(_sheet).height - keyboard;

    testWidgets('con muchas opciones nunca pasa del 85 % de la pantalla', (
      tester,
    ) async {
      tester.view.viewInsets = const FakeViewPadding();
      addTearDown(tester.view.resetViewInsets);
      for (final (width, keyboard, scale) in [
        (320.0, 0.0, 1.5),
        (390.0, 0.0, 1.0),
        (390.0, 300.0, 1.0),
        (1300.0, 0.0, 1.0),
      ]) {
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _open(
          tester,
          _PickerHost(options: _many(), frequent: _names(['Categoría 1'])),
          width: width,
        );
        final reason = '$width px · teclado $keyboard · texto $scale';
        expect(tester.takeException(), isNull, reason: reason);
        expect(
          contentHeight(tester, keyboard),
          lessThanOrEqualTo(700 * DesignTokens.sheetMaxHeightFactor + 0.5),
          reason: reason,
        );
        expect(
          contentHeight(tester, keyboard),
          lessThanOrEqualTo(700 - keyboard + 0.5),
          reason: '$reason: no pasa del espacio que deja el teclado',
        );
        // Con tantas opciones la hoja llega justo a su tope (la prueba no es
        // vacía): el menor entre el 85 % y lo que deja libre el teclado, del
        // alto que ofrece la ruta (la pantalla menos 48 px que Material deja
        // libres arriba).
        const available = 700 - 48.0;
        expect(
          contentHeight(tester, keyboard),
          closeTo(
            math.min(
              available * DesignTokens.sheetMaxHeightFactor,
              available - keyboard,
            ),
            1,
          ),
          reason: reason,
        );
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets(
      'con 2 opciones mide lo suyo: sin hueco entre la lista y el pie',
      (tester) async {
        await _open(
          tester,
          _PickerHost(
            options: _names(['Alimentación', 'Transporte']),
            onCreate: () async => null,
          ),
        );

        // Mucho menos que el máximo (595 px de 700)…
        expect(contentHeight(tester, 0), lessThan(500));
        // …y el botón «Nueva» queda pegado a la última fila, no al fondo.
        final lastRow = tester.getRect(_row('Transporte'));
        final button = tester.getRect(find.byType(OutlinedButton));
        expect(
          button.top - lastRow.bottom,
          lessThanOrEqualTo(DesignTokens.spaceMd),
          reason: 'hueco entre la última opción y el pie',
        );
        expect(
          tester.getTopLeft(find.byType(CatalogPickerHeader)).dy,
          greaterThan(700 - contentHeight(tester, 0) - 1),
        );
      },
    );
  });

  group('matriz de desbordes (abierto con showModalBottomSheet)', () {
    final cases = <(String, _PickerHost, Future<void> Function(WidgetTester)?)>[
      (
        '40 opciones con nombres largos, frecuentes y «Nueva»',
        _PickerHost(
          options: _many(),
          frequent: _names([longCatalogName, 'Desarrollo de software']),
          selected: longCatalogName,
          onCreate: () async => null,
        ),
        null,
      ),
      (
        '2 opciones',
        _PickerHost(options: _names(['Alimentación', 'Transporte'])),
        null,
      ),
      ('sin opciones', const _PickerHost(options: []), null),
      (
        'buscando con resultados y sin ellos',
        _PickerHost(options: _many(), frequent: _names(['Categoría 1'])),
        (tester) async {
          await tester.enterText(_search, 'categoría 1');
          await tester.pumpAndSettle();
          expect(find.text('RESULTADOS'), findsOneWidget);
          await tester.enterText(_search, 'zzz');
          await tester.pumpAndSettle();
          expect(find.text('Sin resultados'), findsOneWidget);
        },
      ),
    ];

    for (final (name, host, afterPump) in cases) {
      testWidgets('$name: 320/390/800/1300 × teclado 0/300 × texto 1.0/1.5', (
        tester,
      ) async {
        await expectNoOverflow(
          tester,
          host,
          freshStateEachTime: true,
          afterPump: (tester) async {
            expect(_sheet, findsOneWidget);
            if (afterPump != null) await afterPump(tester);
          },
        );
      });
    }
  });
}
