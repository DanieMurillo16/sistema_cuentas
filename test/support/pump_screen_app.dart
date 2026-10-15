import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';

/// Texto de la pantalla a la que se vuelve con «Atrás».
const previousScreenText = 'Pantalla anterior';

/// Monta una pantalla suelta con un `GoRouter` mínimo y el overlay de
/// `AppToast`, como en `app.dart`. Primero hay una pantalla «anterior» y la
/// [screen] se empuja encima (así «Atrás» tiene a dónde volver).
///
/// [stubs] son rutas a las que la pantalla puede navegar: cada una muestra
/// `Destino <ruta>`. Con [spanish] los calendarios y botones del sistema van en
/// español, como en `app.dart`. Con [theme] (por ejemplo `AppTheme.light`) se
/// prueba otro tema; el oscuro es el de partida. Devuelve el contenedor para leer providers.
Future<ProviderContainer> pumpScreenApp(
  WidgetTester tester, {
  required Widget screen,
  required List<Override> overrides,
  List<String> stubs = const [],
  double width = 390,
  double height = 800,
  double keyboard = 0,
  double textScale = 1,
  bool settle = true,
  bool spanish = false,
  ThemeData? theme,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);

  const screenPath = '/pantalla';
  final router = GoRouter(
    initialLocation: '/',
    observers: [FlutterSmartDialog.observer],
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Text(previousScreenText)),
      ),
      GoRoute(path: screenPath, builder: (context, state) => screen),
      for (final path in stubs)
        GoRoute(
          path: path,
          builder: (context, state) => Scaffold(body: Text('Destino $path')),
        ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides,
      child: MaterialApp.router(
        theme: theme ?? AppTheme.dark,
        routerConfig: router,
        // Como en app.dart: calendarios y botones del sistema en español.
        locale: spanish ? const Locale('es') : null,
        supportedLocales: spanish
            ? const [Locale('es')]
            : const [Locale('en', 'US')],
        localizationsDelegates: spanish
            ? const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ]
            : null,
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
  await tester.pumpAndSettle();
  router.push(screenPath);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

/// Deja pasar y retira los avisos (`AppToast`) para no dejar temporizadores.
Future<void> showToast(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100)); // llega el estado
  await tester.pump(const Duration(milliseconds: 500)); // entra el aviso
}

Future<void> dismissToasts(WidgetTester tester) async {
  // Los avisos se encolan de uno en uno (≈3 s cada uno): se deja correr el
  // reloj hasta vaciar la cola para no dejar temporizadores pendientes.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(seconds: 4));
  }
  await tester.pumpAndSettle();
}
