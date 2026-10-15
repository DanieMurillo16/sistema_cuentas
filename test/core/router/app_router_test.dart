import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/app.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/services/session_expiration.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/features/auth/login_screen.dart';
import 'package:sistema_cuentas/features/auth/providers/splash_min_time_provider.dart';
import 'package:sistema_cuentas/features/auth/splash_screen.dart';
import 'package:sistema_cuentas/core/router/app_router.dart';
import 'package:sistema_cuentas/features/home/home_screen.dart';
import 'package:sistema_cuentas/features/movements/movements_list_screen.dart';
import 'package:sistema_cuentas/features/settings/settings_screen.dart';
import 'package:sistema_cuentas/features/users/users_screen.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../../helpers/auth_fixtures.dart';
import '../../support/fake_auth_repository.dart';
import '../../helpers/movement_fixtures.dart';
import '../../support/inicio_overrides.dart';

Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  FakeAuthRepository repository, {
  Duration minSplash = Duration.zero,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        splashMinDurationProvider.overrideWithValue(minSplash),
        ...dataOverrides(items: [buildMovement(date: DateTime.now())]),
      ],
      child: const App(),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(App)));
}

void main() {
  group('tiempo mínimo del splash', () {
    const minimum = Duration(seconds: 2);

    FakeAuthRepository signedIn() => FakeAuthRepository(
      storedToken: true,
      onFetchSession: () async => buildSession(),
    );

    testWidgets('con la sesión lista al instante, el splash se ve lo mínimo '
        'y luego entra a Inicio', (tester) async {
      await _pumpApp(tester, signedIn(), minSplash: minimum, settle: false);

      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('al salir, el splash se funde con la vista que sigue (sin '
        'deslizar)', (tester) async {
      await _pumpApp(tester, signedIn(), minSplash: minimum, settle: false);
      await tester.pump(minimum);
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(SplashScreen), findsOneWidget, reason: 'aún se va');
      expect(find.byType(HomeScreen), findsOneWidget, reason: 'ya viene');
      final fade = find
          .ancestor(
            of: find.byType(HomeScreen),
            matching: find.byType(FadeTransition),
          )
          .first;
      final opacity = tester.widget<FadeTransition>(fade).opacity.value;
      expect(opacity, inExclusiveRange(0, 1), reason: 'entra fundiéndose');
      expect(
        find.ancestor(
          of: find.byType(HomeScreen),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
        reason: 'sin deslizamiento',
      );

      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('con «reducir movimiento» el cambio es inmediato', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 800);
      addTearDown(tester.view.reset);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            authRepositoryProvider.overrideWithValue(signedIn()),
            splashMinDurationProvider.overrideWithValue(Duration.zero),
            ...dataOverrides(items: [buildMovement(date: DateTime.now())]),
          ],
          child: const App(),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('sin sesión guardada: igual espera lo mínimo antes del login', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        FakeAuthRepository(),
        minSplash: minimum,
        settle: false,
      );

      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('si la carga tarda más que lo mínimo, espera a la sesión', (
      tester,
    ) async {
      final session = Completer<Session>();
      await _pumpApp(
        tester,
        FakeAuthRepository(
          storedToken: true,
          onFetchSession: () => session.future,
        ),
        minSplash: minimum,
        settle: false,
      );

      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(SplashScreen), findsOneWidget);

      session.complete(buildSession());
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('un error de red se muestra enseguida, sin esperar el mínimo', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        FakeAuthRepository(
          storedToken: true,
          onFetchSession: () async =>
              throw const NetworkException('Sin conexión.'),
        ),
        minSplash: minimum,
        settle: false,
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Sin conexión.'), findsOneWidget);
      await tester.pump(minimum);
    });
  });

  testWidgets('sin token guardado: va al login', (tester) async {
    await _pumpApp(tester, FakeAuthRepository());
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('con token válido: entra a Inicio sin pasar por el login', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      FakeAuthRepository(
        storedToken: true,
        onFetchSession: () async => buildSession(),
      ),
    );
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('token vencido (401): va al login', (tester) async {
    await _pumpApp(
      tester,
      FakeAuthRepository(
        storedToken: true,
        onFetchSession: () async =>
            throw const ApiException('Sesión no válida.', statusCode: 401),
      ),
    );
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets(
    'error de red al arrancar: se queda en el splash con reintento (no va al login)',
    (tester) async {
      await _pumpApp(
        tester,
        FakeAuthRepository(
          storedToken: true,
          onFetchSession: () async =>
              throw const NetworkException('Sin conexión.'),
        ),
      );
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Sin conexión.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    },
  );

  testWidgets('iniciar sesión desde el login lleva a Inicio', (tester) async {
    final repository = FakeAuthRepository(
      onLogin: (_, _) async => buildSession(),
    );
    await _pumpApp(tester, repository);
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'daniel');
    await tester.enterText(find.byType(TextFormField).at(1), 'secreta');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(repository.loginCalls, 1);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('cerrar sesión lleva al login', (tester) async {
    final container = await _pumpApp(
      tester,
      FakeAuthRepository(
        storedToken: true,
        onFetchSession: () async => buildSession(),
      ),
    );
    expect(find.byType(HomeScreen), findsOneWidget);

    await container.read(sessionProvider.notifier).signOut();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets(
    'un 401 en cualquier petición (sessionExpiration) lleva al login',
    (tester) async {
      final container = await _pumpApp(
        tester,
        FakeAuthRepository(
          storedToken: true,
          onFetchSession: () async => buildSession(),
        ),
      );
      expect(find.byType(HomeScreen), findsOneWidget);

      container.read(sessionExpirationProvider.notifier).notify();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    },
  );

  group('lista de ingresos y gastos (/movements/:type)', () {
    Future<ProviderContainer> signedIn(WidgetTester tester) => _pumpApp(
      tester,
      FakeAuthRepository(
        storedToken: true,
        onFetchSession: () async => buildSession(),
      ),
    );

    testWidgets('/movements/income abre la lista de ingresos', (tester) async {
      final container = await signedIn(tester);

      container.read(appRouterProvider).go('/movements/income');
      await tester.pumpAndSettle();

      expect(find.byType(MovementsListScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Ingresos'), findsOneWidget);
    });

    testWidgets('/movements/expense abre la lista de gastos', (tester) async {
      final container = await signedIn(tester);

      container.read(appRouterProvider).go('/movements/expense');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Gastos'), findsOneWidget);
    });

    testWidgets('/movements/otra (tipo inválido) redirige a Inicio', (
      tester,
    ) async {
      final container = await signedIn(tester);

      container.read(appRouterProvider).go('/movements/otra');
      await tester.pumpAndSettle();

      expect(find.byType(MovementsListScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('sin sesión, /movements/income lleva al login', (tester) async {
      final container = await _pumpApp(tester, FakeAuthRepository());
      expect(find.byType(LoginScreen), findsOneWidget);

      container.read(appRouterProvider).go('/movements/income');
      await tester.pumpAndSettle();

      expect(find.byType(MovementsListScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('Usuarios (/settings-users) solo para el administrador', () {
    Future<ProviderContainer> signedIn(
      WidgetTester tester,
      Set<String> permissions,
    ) => _pumpApp(
      tester,
      FakeAuthRepository(
        storedToken: true,
        onFetchSession: () async => buildSession(permissions: permissions),
      ),
    );

    testWidgets('sin el permiso, el enlace directo vuelve a Ajustes', (
      tester,
    ) async {
      final container = await signedIn(tester, const {'movimientos.registrar'});

      container.read(appRouterProvider).go('/settings-users');
      await tester.pumpAndSettle();

      expect(find.byType(UsersScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('con usuarios.gestionar abre la pantalla de usuarios', (
      tester,
    ) async {
      final container = await signedIn(tester, const {'usuarios.gestionar'});

      container.read(appRouterProvider).go('/settings-users');
      await tester.pumpAndSettle();

      expect(find.byType(UsersScreen), findsOneWidget);
    });
  });
}
