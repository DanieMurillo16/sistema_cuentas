import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/shared/widgets/swipe_to_delete.dart';

/// Una fila que, como la app, se quita de la lista cuando se confirma.
class _Host extends StatefulWidget {
  const _Host({this.answer = true, this.enabled = true});

  final bool answer;
  final bool enabled;

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
            SwipeToDelete(
              itemKey: 'x-7',
              onConfirm: widget.enabled
                  ? () async {
                      asked++;
                      if (widget.answer && mounted) {
                        setState(() => present = false);
                      }
                      return widget.answer;
                    }
                  : null,
              child: const SizedBox(
                height: 80,
                width: double.infinity,
                child: Text('fila'),
              ),
            ),
        ],
      ),
    );
  }
}

Future<_HostState> _pump(WidgetTester tester, _Host host) async {
  await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: host));
  return tester.state<_HostState>(find.byType(_Host));
}

void main() {
  testWidgets('sin onConfirm devuelve el hijo tal cual (sin Dismissible)', (
    tester,
  ) async {
    await _pump(tester, const _Host(enabled: false));

    expect(find.byType(Dismissible), findsNothing);
    expect(find.text('fila'), findsOneWidget);
  });

  testWidgets('la clave del Dismissible es swipe-<itemKey>, solo hacia la '
      'izquierda', (tester) async {
    await _pump(tester, const _Host());

    final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
    expect(dismissible.key, const ValueKey('swipe-x-7'));
    expect(dismissible.direction, DismissDirection.endToStart);
  });

  testWidgets('al deslizar se ve el fondo rojo con el bote de basura', (
    tester,
  ) async {
    await _pump(tester, const _Host(answer: false));

    await tester.drag(find.text('fila'), const Offset(-150, 0));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == AppColors.error,
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('hacia la derecha no pregunta', (tester) async {
    final host = await _pump(tester, const _Host());

    await tester.drag(find.text('fila'), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(host.asked, 0);
    expect(find.text('fila'), findsOneWidget);
  });

  testWidgets('confirmado y quitado por la lista: sin excepciones', (
    tester,
  ) async {
    final host = await _pump(tester, const _Host());

    await tester.drag(find.text('fila'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(host.asked, 1);
    expect(find.text('fila'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no confirmado: la fila vuelve a su sitio', (tester) async {
    final host = await _pump(tester, const _Host(answer: false));
    final before = tester.getTopLeft(find.text('fila'));

    await tester.drag(find.text('fila'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(host.asked, 1);
    expect(tester.getTopLeft(find.text('fila')), before);
    expect(tester.takeException(), isNull);
  });
}
