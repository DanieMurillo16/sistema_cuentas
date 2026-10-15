import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/shared/widgets/app_sub_screen_bar.dart';

Future<GoRouter> _pump(WidgetTester tester, {required String start}) async {
  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => context.push('/hija'),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/hija',
        builder: (context, state) => const Scaffold(
          appBar: AppSubScreenBar(title: 'Detalle', fallbackPath: '/'),
          body: Text('Contenido de la hija'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('muestra el título y la flecha «Atrás»', (tester) async {
    await _pump(tester, start: '/hija');
    expect(find.text('Detalle'), findsOneWidget);
    expect(find.byTooltip('Atrás'), findsOneWidget);
  });

  testWidgets('con historial, la flecha vuelve a la pantalla anterior (pop)', (
    tester,
  ) async {
    await _pump(tester, start: '/');
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Contenido de la hija'), findsOneWidget);

    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();

    expect(find.text('Contenido de la hija'), findsNothing);
    expect(find.text('Abrir'), findsOneWidget);
  });

  testWidgets(
    'sin historial (se recargó la página en esa dirección) va a la ruta de respaldo',
    (tester) async {
      final router = await _pump(tester, start: '/hija');
      expect(router.canPop(), isFalse);

      await tester.tap(find.byTooltip('Atrás'));
      await tester.pumpAndSettle();

      expect(find.text('Abrir'), findsOneWidget);
      expect(find.text('Contenido de la hija'), findsNothing);
    },
  );
}
