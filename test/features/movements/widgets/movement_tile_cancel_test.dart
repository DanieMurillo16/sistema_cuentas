import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/shared/widgets/swipe_to_delete.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/fake_catalogs_repository.dart';
import '../../../support/pump_at_sizes.dart';

/// Una lista de una fila que, como la app, QUITA la fila cuando el borrado se
/// confirma (el provider la saca de la lista). Sin eso, un `Dismissible`
/// descartado que sigue en el árbol lanza una excepción.
class _Host extends StatefulWidget {
  const _Host({this.answer = true, this.enabled = true, this.onTap, this.gate});

  final bool answer;
  final bool enabled;
  final VoidCallback? onTap;

  /// Si no es `null`, la confirmación espera a que se complete.
  final Completer<bool>? gate;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  var asked = 0;
  var present = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (present)
            MovementTile(
              movement: buildMovement(id: 5),
              position: RowPosition.only,
              hidden: false,
              onTap: widget.onTap,
              onConfirmCancel: widget.enabled
                  ? () async {
                      asked++;
                      final ok =
                          await (widget.gate?.future ??
                              Future.value(widget.answer));
                      if (ok && mounted) {
                        setState(() => present = false);
                      }
                      return ok;
                    }
                  : null,
            ),
          Text('preguntó $asked'),
        ],
      ),
    );
  }
}

Future<_HostState> _pump(WidgetTester tester, _Host host) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        catalogsRepositoryProvider.overrideWithValue(
          FakeCatalogsRepository(onCategories: () async => []),
        ),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: host),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<_HostState>(find.byType(_Host));
}

Finder get _tile => find.byType(MovementTile);
Finder get _dismissible => find.byType(Dismissible);

/// El fondo rojo con el bote de basura (privado de `SwipeToDelete`): el único
/// `ColoredBox` rojo dentro del `Dismissible`.
Finder get _deleteBackground => find.descendant(
  of: _dismissible,
  matching: find.byWidgetPredicate(
    (w) => w is ColoredBox && w.color == AppColors.error,
  ),
);

/// Lo que se desliza es el contenido: el marco de la fila no se mueve.
Finder get _content => find.text('Mercado');

void main() {
  group('sin onConfirmCancel', () {
    testWidgets('no hay Dismissible ni acción «Eliminar»', (tester) async {
      await _pump(tester, const _Host(enabled: false));

      expect(_dismissible, findsNothing);
      expect(_deleteBackground, findsNothing);
    });

    testWidgets('arrastrar no mueve la fila', (tester) async {
      await _pump(tester, const _Host(enabled: false));
      final before = tester.getTopLeft(_content);

      await tester.drag(_tile, const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(_content), before);
      expect(_deleteBackground, findsNothing);
    });

    testWidgets('no ofrece la acción semántica «Eliminar»', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const _Host(enabled: false));

      final data = tester.getSemantics(_tile).getSemanticsData();

      expect(data.customSemanticsActionIds ?? const <int>[], isEmpty);
      handle.dispose();
    });
  });

  group('con onConfirmCancel', () {
    testWidgets('la fila va envuelta en un Dismissible solo hacia la '
        'izquierda', (tester) async {
      await _pump(tester, const _Host());

      final dismissible = tester.widget<Dismissible>(_dismissible);
      expect(dismissible.direction, DismissDirection.endToStart);
      expect(dismissible.key, const ValueKey('swipe-movement-5'));
      expect(
        tester.widget<SwipeToDelete>(find.byType(SwipeToDelete)).itemKey,
        'movement-5',
      );
    });

    testWidgets('hacia la derecha no hace nada', (tester) async {
      final host = await _pump(tester, const _Host());
      final before = tester.getTopLeft(_content);

      await tester.drag(_tile, const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(host.asked, 0);
      expect(tester.getTopLeft(_content), before);
    });

    testWidgets('un deslizamiento corto no pregunta y la fila vuelve', (
      tester,
    ) async {
      final host = await _pump(tester, const _Host());
      final before = tester.getTopLeft(_content);

      await tester.drag(_tile, const Offset(-40, 0));
      await tester.pumpAndSettle();

      expect(host.asked, 0);
      expect(tester.getTopLeft(_content), before);
    });

    testWidgets('al deslizar se ve el fondo rojo con el bote de basura', (
      tester,
    ) async {
      final gate = Completer<bool>();
      await _pump(tester, _Host(gate: gate));

      await tester.drag(_tile, const Offset(-200, 0));
      await tester.pump();

      expect(_deleteBackground, findsOneWidget);
      expect(
        find.descendant(
          of: _deleteBackground,
          matching: find.byIcon(Icons.delete_outline_rounded),
        ),
        findsOneWidget,
      );
      gate.complete(false);
      await tester.pumpAndSettle();
    });

    testWidgets('deslizar a fondo pregunta una vez', (tester) async {
      final host = await _pump(tester, const _Host(answer: false));

      await tester.drag(_tile, const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(host.asked, 1);
    });

    testWidgets('si NO se confirma (false), la fila vuelve a su sitio', (
      tester,
    ) async {
      final host = await _pump(tester, const _Host(answer: false));
      final before = tester.getTopLeft(_content);

      await tester.drag(_tile, const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(host.asked, 1);
      expect(_tile, findsOneWidget);
      expect(tester.getTopLeft(_content), before);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mientras se decide, la fila queda deslizada y sigue en '
        'el árbol', (tester) async {
      final gate = Completer<bool>();
      await _pump(tester, _Host(gate: gate));
      final before = tester.getTopLeft(_content);

      await tester.drag(_tile, const Offset(-400, 0));
      await tester.pump(const Duration(milliseconds: 400));

      expect(_tile, findsOneWidget);
      expect(tester.getTopLeft(_content).dx, lessThan(before.dx));
      gate.complete(false);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_content), before);
    });

    testWidgets('si se confirma (true) y la lista la quita: desaparece sin '
        'excepciones («dismissed Dismissible still part of the tree»)', (
      tester,
    ) async {
      final host = await _pump(tester, const _Host());

      await tester.drag(_tile, const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(host.asked, 1);
      expect(_tile, findsNothing);
      expect(_dismissible, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('confirmación tardía: la respuesta llega después y la fila '
        'se quita sin excepciones', (tester) async {
      final gate = Completer<bool>();
      await _pump(tester, _Host(gate: gate));

      await tester.drag(_tile, const Offset(-400, 0));
      await tester.pump(const Duration(milliseconds: 300));
      gate.complete(true);
      await tester.pumpAndSettle();

      expect(_tile, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('deslizar a fondo y volver a deslizar tras un «no» pregunta '
        'otra vez', (tester) async {
      final host = await _pump(tester, const _Host(answer: false));

      await tester.drag(_tile, const Offset(-400, 0));
      await tester.pumpAndSettle();
      await tester.drag(_tile, const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(host.asked, 2);
    });
  });

  group('semántica', () {
    testWidgets('ofrece la acción personalizada «Eliminar» y la ejecuta', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final host = await _pump(tester, const _Host(answer: false));

      final node = tester.getSemantics(_tile);
      final ids = node.getSemanticsData().customSemanticsActionIds!;
      final labels = [
        for (final id in ids) CustomSemanticsAction.getAction(id)!.label,
      ];
      expect(labels, ['Eliminar']);

      tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.customAction,
        ids.single,
      );
      await tester.pumpAndSettle();
      expect(host.asked, 1);
      handle.dispose();
    });

    testWidgets('con onTap expone botón y toque; sin onTap no es botón', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _Host(onTap: () {}));
      var data = tester.getSemantics(_tile).getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      await _pump(tester, const _Host());
      data = tester.getSemantics(_tile).getSemanticsData();
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });
  });

  group('superficie de la fila', () {
    testWidgets('es un Material con el color de superficie (el ripple se ve)', (
      tester,
    ) async {
      await _pump(tester, _Host(onTap: () {}));

      final material = tester.widget<Material>(
        find.descendant(of: _tile, matching: find.byType(Material)).first,
      );
      expect(material.color, AppColors.surface);
    });

    testWidgets('tocar la fila llama a onTap sin preguntar por eliminar', (
      tester,
    ) async {
      var taps = 0;
      final host = await _pump(tester, _Host(onTap: () => taps++));

      await tester.tap(_tile);
      await tester.pump();

      expect(taps, 1);
      expect(host.asked, 0);
    });
  });

  group('sin desbordes', () {
    testWidgets('fila con textos largos y fondo de deslizar, en todos los '
        'tamaños', (tester) async {
      await expectNoOverflow(
        tester,
        // Dentro de un scroll, como en la lista real (sin alto fijo).
        Scaffold(
          body: SingleChildScrollView(
            child: MovementTile(
              movement: buildMovement(
                description: longDescription,
                category: longCatalogName,
                method: longCatalogName,
                valueCents: 99999999999900,
              ),
              position: RowPosition.only,
              hidden: false,
              onConfirmCancel: () async => false,
            ),
          ),
        ),
        overrides: [
          catalogsRepositoryProvider.overrideWithValue(
            FakeCatalogsRepository(onCategories: () async => []),
          ),
        ],
        afterPump: (tester) async {
          // Desde la parte alta: con texto grande la fila es más alta que la vista.
          await tester.dragFrom(
            tester.getTopLeft(_tile) + const Offset(100, 20),
            const Offset(-150, 0),
          );
          await tester.pump();
          expect(_deleteBackground, findsOneWidget);
        },
        freshStateEachTime: true,
      );
    });
  });
}
