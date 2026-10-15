import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/features/home/home_screen.dart';
import 'package:sistema_cuentas/features/movements/movements_list_screen.dart';

/// La ruta actual del `GoRouter` de [pumpRouterApp] (para comprobar adónde se navegó).
String currentLocation(WidgetTester tester) =>
    GoRouterState.of(tester.element(find.byType(Scaffold).last)).uri.path;

/// Inicio (con su «+» que abre la hoja de nuevo movimiento) con un `GoRouter` mínimo (sin sesión ni menú) y el
/// overlay de `AppToast`, como en `app.dart`. Para probar pantallas aisladas.
///
/// Devuelve el contenedor para leer o mover providers desde la prueba.
Future<ProviderContainer> pumpRouterApp(
  WidgetTester tester, {
  required List<Override> overrides,
  String initialLocation = AppRoutes.home,
  double width = 390,
  double height = 800,
  double keyboard = 0,
  double textScale = 1,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: initialLocation,
    observers: [FlutterSmartDialog.observer],
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      // La lista de ingresos o de gastos, igual que en `app_router.dart`
      // (ruta inválida → Inicio), para probar el salto desde las tarjetas.
      GoRoute(
        path: AppRoutes.movements,
        redirect: (context, state) =>
            MovementType.tryFromRoute(state.pathParameters['type']) == null
            ? AppRoutes.home
            : null,
        builder: (context, state) => MovementsListScreen(
          type: MovementType.tryFromRoute(state.pathParameters['type'])!,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
        builder: FlutterSmartDialog.init(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    ),
  );
  // Con un cargador infinito no hay «reposo»: se avanza un tiempo fijo.
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Dos pasos: el primero reconstruye con lo que ya llegó y el segundo deja
    // terminar los fundidos entre estados.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}
