import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/catalog_visuals.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_badge.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_color_grid.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_icon_grid.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_choice.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_field.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_sheet.dart';

import '../../support/expect_screen_no_overflow.dart';
import '../../support/pump_at_sizes.dart';
import '../../support/pump_screen_app.dart';

const _fallback = Icons.north_east_rounded;

/// Un formulario mínimo: el campo «Icono y color» y lo que se eligió, escrito
/// en texto para poder comprobarlo.
class _Host extends StatefulWidget {
  const _Host({
    this.initial = const CatalogVisualChoice(),
    this.enabled = true,
    this.subject,
  });

  final CatalogVisualChoice initial;
  final bool enabled;
  final ValueGetter<String>? subject;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late var _choice = widget.initial;
  var _changes = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El teclado no encoge este formulario de prueba: lo que se mide es la hoja.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            CatalogVisualField(
              choice: _choice,
              fallbackIcon: _fallback,
              enabled: widget.enabled,
              subject: widget.subject,
              onChanged: (value) => setState(() {
                _choice = value;
                _changes++;
              }),
            ),
            Text(
              'icono=${_choice.icon} color=${_choice.color} cambios=$_changes',
              key: const ValueKey('resultado'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  CatalogVisualChoice initial = const CatalogVisualChoice(),
  bool enabled = true,
  ValueGetter<String>? subject,
  double width = 390,
  double height = 800,
  double keyboard = 0,
  double textScale = 1,
}) => pumpScreenApp(
  tester,
  screen: _Host(initial: initial, enabled: enabled, subject: subject),
  overrides: const [],
  width: width,
  height: height,
  keyboard: keyboard,
  textScale: textScale,
);

Finder get _field => find.byType(CatalogVisualField);
Finder get _sheet => find.byType(CatalogVisualSheet);
Finder get _search =>
    find.descendant(of: _sheet, matching: find.byType(TextField));
Finder _iconCell(String key) => find.byKey(ValueKey('catalog-icon-$key'));
Finder _colorCell(String hex) => find.byKey(ValueKey('catalog-color-$hex'));
Finder get _apply => find.widgetWithText(FilledButton, 'Aplicar');
Finder get _clear => find.widgetWithText(OutlinedButton, 'Quitar');

String _result(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('resultado'))).data!;

Future<void> _open(WidgetTester tester) async {
  await tester.tap(_field);
  await tester.pumpAndSettle();
}

Future<void> _showColors(WidgetTester tester) async {
  await tester.tap(find.descendant(of: _sheet, matching: find.text('Color')));
  await tester.pumpAndSettle();
}

Future<void> _showIcons(WidgetTester tester) async {
  await tester.tap(find.descendant(of: _sheet, matching: find.text('Icono')));
  await tester.pumpAndSettle();
}

CatalogBadge _previewIn(WidgetTester tester, Finder scope) =>
    tester.widget<CatalogBadge>(
      find.descendant(of: scope, matching: find.byType(CatalogBadge)).first,
    );

void main() {
  group('CatalogVisualField', () {
    testWidgets(
      'sin elegir: icono de respaldo, acento y «Toca para elegirlos»',
      (tester) async {
        await _pump(tester);

        expect(find.text('Icono y color'), findsOneWidget);
        expect(find.text('Toca para elegirlos'), findsOneWidget);
        final badge = _previewIn(tester, _field);
        expect(badge.icon, _fallback);
        expect(badge.color, AppColors.accent);
      },
    );

    testWidgets('con una elección: la muestra y dice «Toca para cambiarlos»', (
      tester,
    ) async {
      await _pump(
        tester,
        initial: const CatalogVisualChoice(icon: 'casa', color: '#FB923C'),
      );

      final badge = _previewIn(tester, _field);
      expect(badge.icon, Icons.home_rounded);
      expect(badge.color.toARGB32(), 0xFFFB923C);
      expect(find.text('Toca para cambiarlos'), findsOneWidget);
    });

    testWidgets('valores desconocidos o inválidos: respaldo, sin fallar', (
      tester,
    ) async {
      await _pump(
        tester,
        initial: const CatalogVisualChoice(icon: 'del_futuro', color: 'azul'),
      );

      final badge = _previewIn(tester, _field);
      expect(badge.icon, _fallback);
      expect(badge.color, AppColors.accent);
      expect(tester.takeException(), isNull);
    });

    testWidgets('semántica: botón con valor «Sin elegir» / «Elegido»', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      var node = tester.getSemantics(_field);
      expect(node.label, 'Icono y color');
      expect(node.value, 'Sin elegir');
      expect(node.flagsCollection.isButton, isTrue);

      await _pump(tester, initial: const CatalogVisualChoice(color: '#34D399'));
      node = tester.getSemantics(_field);
      expect(node.value, 'Elegido');
      handle.dispose();
    });

    testWidgets('deshabilitado: tocarlo no abre el selector', (tester) async {
      await _pump(tester, enabled: false);

      await tester.tap(_field);
      await tester.pumpAndSettle();

      expect(_sheet, findsNothing);
    });
  });

  group('selector: abrir y elegir', () {
    testWidgets('abre con título, conmutador, vista previa y acciones', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester);

      expect(_sheet, findsOneWidget);
      expect(
        find.descendant(of: _sheet, matching: find.text('Icono y color')),
        findsOneWidget,
      );
      expect(find.text('Icono'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(_apply, findsOneWidget);
      expect(_clear, findsOneWidget);
      expect(find.byType(CatalogIconGrid), findsOneWidget);
      expect(find.byType(CatalogColorGrid), findsNothing);
    });

    testWidgets('elegir icono y color y «Aplicar» devuelve la elección', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester);

      await tester.tap(_iconCell('gasolina'));
      await tester.pumpAndSettle();
      await _showColors(tester);
      await tester.tap(_colorCell('#FB923C'));
      await tester.pumpAndSettle();
      await tester.tap(_apply);
      await tester.pumpAndSettle();

      expect(_sheet, findsNothing, reason: 'se cierra al aplicar');
      expect(_result(tester), 'icono=gasolina color=#FB923C cambios=1');
      final badge = _previewIn(tester, _field);
      expect(badge.icon, Icons.local_gas_station_rounded);
      expect(badge.color.toARGB32(), 0xFFFB923C);
      expect(find.text('Toca para cambiarlos'), findsOneWidget);
    });

    testWidgets('solo icono: el color queda en null', (tester) async {
      await _pump(tester);
      await _open(tester);

      await tester.tap(_iconCell('casa'));
      await tester.pumpAndSettle();
      await tester.tap(_apply);
      await tester.pumpAndSettle();

      expect(_result(tester), 'icono=casa color=null cambios=1');
    });

    testWidgets('solo color: el icono queda en null', (tester) async {
      await _pump(tester);
      await _open(tester);

      await _showColors(tester);
      await tester.tap(_colorCell('#60A5FA'));
      await tester.pumpAndSettle();
      await tester.tap(_apply);
      await tester.pumpAndSettle();

      expect(_result(tester), 'icono=null color=#60A5FA cambios=1');
    });

    testWidgets('aplicar sin elegir nada devuelve una elección vacía', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester);

      await tester.tap(_apply);
      await tester.pumpAndSettle();

      expect(_result(tester), 'icono=null color=null cambios=1');
    });

    testWidgets('la vista previa del selector sigue lo que se toca', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester);
      expect(_previewIn(tester, _sheet).icon, _fallback);

      await tester.tap(_iconCell('cafe'));
      await tester.pumpAndSettle();
      expect(_previewIn(tester, _sheet).icon, Icons.local_cafe_rounded);

      await _showColors(tester);
      await tester.tap(_colorCell('#C084FC'));
      await tester.pumpAndSettle();
      expect(_previewIn(tester, _sheet).color.toARGB32(), 0xFFC084FC);
      expect(_previewIn(tester, _sheet).size, DesignTokens.visualPreviewSize);
    });

    testWidgets('al cambiar de pestaña no se pierde lo elegido', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester);

      await tester.tap(_iconCell('tienda'));
      await tester.pumpAndSettle();
      await _showColors(tester);
      await tester.tap(_colorCell('#2DD4BF'));
      await tester.pumpAndSettle();
      await _showIcons(tester);
      await tester.tap(_apply);
      await tester.pumpAndSettle();

      expect(_result(tester), 'icono=tienda color=#2DD4BF cambios=1');
    });

    testWidgets('abre con la elección actual ya aplicada en la vista previa', (
      tester,
    ) async {
      await _pump(
        tester,
        initial: const CatalogVisualChoice(icon: 'casa', color: '#FB923C'),
      );
      await _open(tester);

      final badge = _previewIn(tester, _sheet);
      expect(badge.icon, Icons.home_rounded);
      expect(badge.color.toARGB32(), 0xFFFB923C);
      // «Aplicar» sin tocar nada conserva lo que había.
      await tester.tap(_apply);
      await tester.pumpAndSettle();
      expect(_result(tester), 'icono=casa color=#FB923C cambios=1');
    });

    testWidgets('el color elegido lleva un visto y es único', (tester) async {
      await _pump(tester, initial: const CatalogVisualChoice(color: '#34D399'));
      await _open(tester);
      await _showColors(tester);

      expect(
        find.descendant(
          of: _colorCell('#34D399'),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(_colorCell('#F87171'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _colorCell('#F87171'),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  group('selector: búsqueda de iconos', () {
    testWidgets('«gasolina» deja solo los iconos que coinciden', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester);
      final before = tester.widgetList(find.byType(InkWell)).length;

      await tester.enterText(_search, 'gasolina');
      await tester.pumpAndSettle();

      expect(_iconCell('gasolina'), findsOneWidget);
      expect(_iconCell('comida'), findsNothing);
      expect(tester.widgetList(find.byType(InkWell)).length, lessThan(before));
    });

    testWidgets(
      'busca también por términos (combustible) y sin importar mayúsculas',
      (tester) async {
        await _pump(tester);
        await _open(tester);

        await tester.enterText(_search, ' COMBUSTIBLE ');
        await tester.pumpAndSettle();

        expect(_iconCell('gasolina'), findsOneWidget);
      },
    );

    testWidgets('se elige un icono encontrado y llega a «Aplicar»', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester);

      await tester.enterText(_search, 'gasolina');
      await tester.pumpAndSettle();
      await tester.tap(_iconCell('gasolina'));
      await tester.pumpAndSettle();
      await tester.tap(_apply);
      await tester.pumpAndSettle();

      expect(_result(tester), 'icono=gasolina color=null cambios=1');
    });

    testWidgets('sin resultados: mensaje y ninguna rejilla', (tester) async {
      await _pump(tester);
      await _open(tester);

      await tester.enterText(_search, 'zzzzqx');
      await tester.pumpAndSettle();

      expect(find.text('No hay un icono con ese nombre.'), findsOneWidget);
      expect(find.byType(CatalogIconGrid), findsNothing);
      // Se puede seguir: aplicar sigue disponible.
      expect(_apply, findsOneWidget);
    });

    testWidgets('al borrar la búsqueda vuelven todos los iconos', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester);
      await tester.enterText(_search, 'zzzzqx');
      await tester.pumpAndSettle();

      await tester.enterText(_search, '');
      await tester.pumpAndSettle();

      expect(find.text('No hay un icono con ese nombre.'), findsNothing);
      expect(_iconCell('comida'), findsOneWidget);
    });

    testWidgets(
      'volver a «Icono» tras buscar: el campo y la lista dicen lo mismo',
      (tester) async {
        await _pump(tester);
        await _open(tester);
        await tester.enterText(_search, 'gasolina');
        await tester.pumpAndSettle();

        await _showColors(tester);
        await _showIcons(tester);

        final typed = tester.widget<TextField>(_search).controller?.text ?? '';
        final filtered = _iconCell('comida').evaluate().isEmpty;
        expect(
          filtered,
          typed.isNotEmpty,
          reason:
              'la lista está ${filtered ? 'filtrada' : 'completa'} pero el '
              'campo de búsqueda dice «$typed»',
        );
      },
    );
  });

  group('selector: Quitar y cerrar sin aplicar', () {
    testWidgets(
      '«Quitar» devuelve una elección vacía y el campo vuelve al respaldo',
      (tester) async {
        await _pump(
          tester,
          initial: const CatalogVisualChoice(icon: 'casa', color: '#FB923C'),
        );
        await _open(tester);

        await tester.tap(_clear);
        await tester.pumpAndSettle();

        expect(_sheet, findsNothing);
        expect(_result(tester), 'icono=null color=null cambios=1');
        final badge = _previewIn(tester, _field);
        expect(badge.icon, _fallback);
        expect(badge.color, AppColors.accent);
        expect(find.text('Toca para elegirlos'), findsOneWidget);
      },
    );

    testWidgets('«Quitar» ignora lo que se tocó antes en la misma hoja', (
      tester,
    ) async {
      await _pump(tester, initial: const CatalogVisualChoice(icon: 'casa'));
      await _open(tester);
      await tester.tap(_iconCell('tienda'));
      await tester.pumpAndSettle();

      await tester.tap(_clear);
      await tester.pumpAndSettle();

      expect(_result(tester), 'icono=null color=null cambios=1');
    });

    testWidgets('cerrar tocando fuera no cambia nada ni avisa', (tester) async {
      await _pump(
        tester,
        initial: const CatalogVisualChoice(icon: 'casa', color: '#FB923C'),
      );
      await _open(tester);
      await tester.tap(_iconCell('tienda'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(_sheet, findsNothing);
      expect(_result(tester), 'icono=casa color=#FB923C cambios=0');
    });

    testWidgets('cerrar con «Atrás» del sistema tampoco cambia nada', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester);
      await tester.tap(_iconCell('tienda'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_sheet, findsNothing);
      expect(_result(tester), 'icono=null color=null cambios=0');
    });

    testWidgets(
      'al reabrir tras cerrar sin aplicar, lo tocado no quedó guardado',
      (tester) async {
        await _pump(tester);
        await _open(tester);
        await tester.tap(_iconCell('tienda'));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        await _open(tester);

        expect(_previewIn(tester, _sheet).icon, _fallback);
      },
    );
  });

  group('selector: accesibilidad y medidas', () {
    testWidgets('30 colores con etiqueta «Color N de 30»', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await _open(tester);
      await _showColors(tester);

      for (final (i, hex) in CatalogVisuals.palette.indexed) {
        expect(
          tester.getSemantics(_colorCell(hex)).label,
          'Color ${i + 1} de 30',
        );
      }
      handle.dispose();
    });

    testWidgets('cada color tiene un toque de al menos 48 px', (tester) async {
      await _pump(tester);
      await _open(tester);
      await _showColors(tester);

      for (final hex in CatalogVisuals.palette) {
        final size = tester.getSize(_colorCell(hex));
        expect(
          size.width,
          greaterThanOrEqualTo(kMinInteractiveDimension),
          reason: hex,
        );
        expect(
          size.height,
          greaterThanOrEqualTo(kMinInteractiveDimension),
          reason: hex,
        );
      }
    });

    testWidgets('los iconos tienen nombre para el lector de pantalla', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await _open(tester);

      expect(tester.getSemantics(_iconCell('gasolina')).label, 'Gasolina');
      expect(find.byTooltip('Gasolina'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('en 1300 px la hoja no pasa de dialogMaxWidth', (tester) async {
      await _pump(tester, width: 1300);
      await _open(tester);

      expect(
        tester.getSize(_sheet).width,
        lessThanOrEqualTo(DesignTokens.dialogMaxWidth),
      );
    });

    testWidgets(
      'con el teclado abierto solo queda el conmutador y las acciones',
      (tester) async {
        await _pump(tester, keyboard: 300);
        await _open(tester);

        expect(
          find.descendant(of: _sheet, matching: find.text('Icono y color')),
          findsNothing,
        );
        expect(
          find.byType(CatalogBadge),
          findsOneWidget,
          reason: 'solo la del campo; la vista previa se oculta',
        );
        expect(find.text('Icono'), findsOneWidget);
        expect(find.text('Color'), findsOneWidget);
        expect(_apply, findsOneWidget);
      },
    );
  });

  group('selector: nombre de lo que se cambia', () {
    // El nombre sale en color de acento bajo «Icono y color».
    Finder nameIn(String text) =>
        find.descendant(of: _sheet, matching: find.text(text));

    testWidgets('con nombre: sale bajo el título, en acento y con inicial '
        'mayúscula', (tester) async {
      await _pump(tester, subject: () => 'mercado del mes');
      await _open(tester);

      final name = nameIn('Mercado del mes');
      expect(name, findsOneWidget);
      final title = find.descendant(
        of: _sheet,
        matching: find.text('Icono y color'),
      );
      expect(
        tester.getTopLeft(name).dy,
        greaterThan(tester.getBottomLeft(title).dy - 1),
      );
      expect(tester.widget<Text>(name).style?.color, AppColors.accent);
    });

    testWidgets('el nombre se lee al abrir: lo recién tecleado se ve', (
      tester,
    ) async {
      var typed = 'Arriendo';
      await _pump(tester, subject: () => typed);

      await _open(tester);
      expect(nameIn('Arriendo'), findsOneWidget);
      await tester.tap(_apply);
      await tester.pumpAndSettle();

      typed = 'Gimnasio';
      await _open(tester);
      expect(nameIn('Gimnasio'), findsOneWidget);
      expect(nameIn('Arriendo'), findsNothing);
    });

    testWidgets('espacios alrededor: se recortan', (tester) async {
      await _pump(tester, subject: () => '   Salud   ');
      await _open(tester);

      expect(nameIn('Salud'), findsOneWidget);
    });

    testWidgets('sin getter, o con nombre vacío: no hay línea de nombre', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester);
      final withoutGetter = find
          .descendant(of: _sheet, matching: find.byType(Text))
          .evaluate()
          .length;
      await tester.tap(_apply);
      await tester.pumpAndSettle();

      await _pump(tester, subject: () => '   ');
      await _open(tester);
      final withBlank = find
          .descendant(of: _sheet, matching: find.byType(Text))
          .evaluate()
          .length;

      expect(withBlank, withoutGetter);
      expect(find.text('Icono y color'), findsWidgets);
    });

    testWidgets('nombre de 60+ caracteres: máximo 2 líneas con elipsis', (
      tester,
    ) async {
      final long = 'Servicios públicos domiciliarios del hogar ' * 2;
      await _pump(tester, width: 320, textScale: 1.5, subject: () => long);
      await _open(tester);

      final text = tester.widget<Text>(
        find.descendant(
          of: _sheet,
          matching: find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').startsWith('Servicios'),
          ),
        ),
      );
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    testWidgets('modo compacto (teclado abierto): el nombre no se ve', (
      tester,
    ) async {
      await _pump(tester, height: 568, keyboard: 300, subject: () => 'Salud');
      await _open(tester);

      expect(nameIn('Salud'), findsNothing);
      expect(find.text('Color'), findsOneWidget);
    });

    testWidgets('sin desbordes con un nombre de 60+ caracteres', (
      tester,
    ) async {
      final long = 'Servicios públicos domiciliarios del hogar y otros gastos';
      await expectScreenNoOverflow(
        tester,
        screen: _Host(
          initial: const CatalogVisualChoice(icon: 'casa', color: '#FB923C'),
          subject: () => '$long $long',
        ),
        overrides: () => const [],
        prepare: _open,
      );
    });
  });

  group('selector: con teclado abierto lo tocable queda sobre el teclado', () {
    testWidgets('568 de alto, teclado 300: conmutador y botones visibles', (
      tester,
    ) async {
      await _pump(tester, height: 568, keyboard: 300);
      await _open(tester);

      for (final finder in [_apply, _clear, find.text('Color')]) {
        expect(
          tester.getRect(finder).bottom,
          lessThanOrEqualTo(568 - 300),
          reason: 'debe quedar por encima del teclado',
        );
        expect(tester.getRect(finder).top, greaterThanOrEqualTo(0));
      }
    });
  });

  group('selector: sin desbordes abierto con showCatalogVisualSheet', () {
    // La hoja se abre como en la app (desde el campo, con showModalBottomSheet)
    // para que vea el teclado. Estados: pestaña Icono, pestaña Color y búsqueda
    // sin resultados.
    final states = <String, Future<void> Function(WidgetTester)>{
      'pestaña Icono': _open,
      'pestaña Color': (tester) async {
        await _open(tester);
        await _showColors(tester);
      },
      'búsqueda sin resultados': (tester) async {
        await _open(tester);
        // Con muy poco alto (teclado + texto grande) el buscador se oculta a
        // propósito: no hay nada que escribir y solo se comprueba el cuadro.
        if (_search.evaluate().isEmpty) return;
        await tester.enterText(_search, 'zzzzqx');
        await tester.pumpAndSettle();
      },
    };

    void register(
      String name, {
      required double height,
      List<double> keyboards = testKeyboards,
      List<double> scales = testTextScales,
      String? skip,
    }) {
      for (final entry in states.entries) {
        testWidgets(
          '${entry.key} · $name${skip == null ? '' : ' [OMITIDA: $skip]'}',
          (tester) async {
            if (skip != null) {
              markTestSkipped(skip);
              return;
            }
            await expectScreenNoOverflow(
              tester,
              screen: const _Host(
                initial: CatalogVisualChoice(icon: 'casa', color: '#FB923C'),
              ),
              overrides: () => const [],
              height: height,
              keyboards: keyboards,
              scales: scales,
              prepare: entry.value,
            );
          },
        );
      }
    }

    // 700 de alto: toda la matriz.
    register(
      '700 px de alto (320/390/800/1300 × teclado × texto 1.5)',
      height: 700,
    );

    // 568 (iPhone SE): lo que cabe y, aparte, la matriz completa con su defecto.
    register(
      '568 px de alto, teclado cerrado, texto 1.0 y 1.5',
      height: 568,
      keyboards: const [0],
    );
    register(
      '568 px de alto, teclado 300, texto 1.0',
      height: 568,
      keyboards: const [300],
      scales: const [1.0],
    );
    register('568 px de alto, matriz completa', height: 568);

    // 360 (teléfono horizontal): toda la matriz pasa.
    register(
      '360 px de alto (320/390/800/1300 × teclado × texto 1.5)',
      height: 360,
    );

    testWidgets('el campo del formulario suelto no desborda', (tester) async {
      await expectNoOverflow(tester, const _Host());
    });
  });
}
