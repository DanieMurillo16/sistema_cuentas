import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/features/recurring/recurring_detail_screen.dart';
import 'package:sistema_cuentas/features/recurring/recurring_form_screen.dart';
import 'package:sistema_cuentas/features/recurring/recurring_screen.dart';

/// Pagos recurrentes con un `GoRouter` mínimo (sin sesión ni menú) y el overlay
/// de `AppToast`, como en `app.dart`: la pestaña, el formulario y el detalle,
/// más una pantalla marcada «Inicio» para ver adónde se va.
///
/// Devuelve el contenedor para leer o mover providers desde la prueba.
Future<ProviderContainer> pumpRecurringApp(
  WidgetTester tester, {
  required List<Override> overrides,
  String initialLocation = AppRoutes.recurring,
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
        builder: (context, state) =>
            const Scaffold(body: Text('Pantalla Inicio')),
      ),
      GoRoute(
        path: AppRoutes.recurring,
        builder: (context, state) => const RecurringScreen(),
      ),
      GoRoute(
        path: AppRoutes.recurringNew,
        builder: (context, state) => const RecurringFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.recurringDetail,
        builder: (context, state) =>
            RecurringDetailScreen(id: int.parse(state.pathParameters['id']!)),
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
        // Como en app.dart: calendarios y botones del sistema en español.
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}
