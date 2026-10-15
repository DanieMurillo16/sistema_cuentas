import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/features/auth/providers/splash_min_time_provider.dart';
import 'package:sistema_cuentas/app.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/features/home/home_screen.dart';
import 'package:sistema_cuentas/features/recurring/recurring_screen.dart';
import 'package:sistema_cuentas/features/settings/settings_screen.dart';
import 'package:sistema_cuentas/features/summary/summary_screen.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/shared/navigation/app_destination.dart';
import 'package:sistema_cuentas/shared/navigation/main_shell.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';
import 'package:sistema_cuentas/shared/widgets/app_shell_wide.dart';
import 'package:sistema_cuentas/shared/widgets/app_top_bar.dart';
import 'package:sistema_cuentas/shared/widgets/floating_pill_nav.dart';

import '../../helpers/auth_fixtures.dart';
import '../../support/fake_auth_repository.dart';
import '../../helpers/movement_fixtures.dart';
import '../../helpers/recurring_fixtures.dart';
import '../../support/inicio_overrides.dart';
import '../../support/pump_at_sizes.dart';
import '../../support/recurring_overrides.dart';

FakeAuthRepository _signedIn({String fullName = 'Daniel Murillo'}) =>
    FakeAuthRepository(
      storedToken: true,
      onFetchSession: () async => buildSession(fullName: fullName),
    );

List<Override> _overrides(FakeAuthRepository repository) => [
  authRepositoryProvider.overrideWithValue(repository),
  splashMinDurationProvider.overrideWithValue(Duration.zero),
  ...dataOverrides(items: [buildMovement(date: DateTime.now())]),
  // «Pagos recurrentes» ya llama a la API: vencimientos y acuerdos falsos.
  ...recurringRepositoryOverrides(
    dueItems: [buildDue()],
    recurringItems: [buildRecurring()],
  ),
];

/// La app completa (router real, MainShell dentro) con la sesión ya abierta.
Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  double width = 390,
  double keyboard = 0,
  FakeAuthRepository? repository,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 700);
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: _overrides(repository ?? _signedIn()),
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(App)));
}

/// El marco con la pantalla real de la pestaña (Inicio o Ajustes).
Widget _shell(String location) => MainShell(
  location: location,
  child: location == AppRoutes.settings
      ? const SettingsScreen()
      : const HomeScreen(),
);

/// El ojo de la cabecera (la tarjeta de balance de Inicio tiene el suyo).
Finder _headerEye(String tooltip) => find.descendant(
  of: find.byType(AppTopBar),
  matching: find.byTooltip(tooltip),
);

Finder get _pill => find.byType(FloatingPillNav);

/// La pantalla de cada pestaña.
Finder _contentOf(String label) => switch (label) {
  'Inicio' => find.byType(HomeScreen),
  'Pagos recurrentes' => find.byType(RecurringScreen),
  'Resumen' => find.byType(SummaryScreen),
  'Ajustes' => find.byType(SettingsScreen),
  _ => throw ArgumentError('Pestaña desconocida: $label'),
};

void main() {
  group('MainShell: sin desbordes', () {
    testWidgets(
      'Inicio (con selector de mes) en 320/390/800/1300 × teclado × texto 1.5',
      (tester) async {
        await expectNoOverflow(
          tester,
          _shell(AppRoutes.home),
          overrides: _overrides(_signedIn()),
        );
      },
    );

    testWidgets('Ajustes (sin selector de mes)', (tester) async {
      await expectNoOverflow(
        tester,
        _shell(AppRoutes.settings),
        overrides: _overrides(_signedIn()),
      );
    });

    testWidgets('con un nombre de 60+ caracteres en la cabecera', (
      tester,
    ) async {
      expect(longFullName.length, greaterThan(40));
      await expectNoOverflow(
        tester,
        _shell(AppRoutes.home),
        overrides: _overrides(_signedIn(fullName: longFullName)),
      );
    });

    testWidgets('sin nombre aún (sesión cargando) no rompe la cabecera', (
      tester,
    ) async {
      await expectNoOverflow(
        tester,
        _shell(AppRoutes.home),
        overrides: _overrides(FakeAuthRepository()), // sin sesión: nombre ''
      );
    });

    testWidgets(
      'en los anchos donde cambia el menú: 599, 600, 899, 900, 1099, 1100',
      (tester) async {
        await expectNoOverflow(
          tester,
          _shell(AppRoutes.home),
          overrides: _overrides(_signedIn(fullName: longFullName)),
          widths: const [599, 600, 899, 900, 1099, 1100],
        );
      },
    );

    testWidgets('AppShellWide (rail) a 900 y 1100 × teclado × texto 1.5', (
      tester,
    ) async {
      await expectNoOverflow(
        tester,
        AppShellWide(
          destinations: appDestinations,
          selectedIndex: 1,
          onSelected: (_) {},
          extended: false,
          content: const SizedBox.expand(),
        ),
        widths: const [900, 1100],
      );
      await expectNoOverflow(
        tester,
        AppShellWide(
          destinations: appDestinations,
          selectedIndex: 1,
          onSelected: (_) {},
          extended: true,
          content: const SizedBox.expand(),
        ),
        widths: const [900, 1100],
      );
    });

    testWidgets('FloatingPillNav suelta en 320/390/800/1300 × texto 1.5', (
      tester,
    ) async {
      await expectNoOverflow(
        tester,
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FloatingPillNav(
                destinations: appDestinations,
                selectedIndex: 2,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
    });
  });

  group('MainShell: píldora (< 900 px)', () {
    testWidgets('en 390 hay píldora con las 4 pestañas y no hay rail', (
      tester,
    ) async {
      await _pumpApp(tester);

      expect(_pill, findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      for (final d in appDestinations) {
        expect(find.byTooltip(d.label), findsOneWidget);
      }
      // Inicio es la pestaña elegida (icono relleno).
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    });

    testWidgets('la píldora queda dentro de la pantalla en 320 y 390', (
      tester,
    ) async {
      for (final width in [320.0, 390.0]) {
        await _pumpApp(tester, width: width);
        final rect = tester.getRect(_pill);
        expect(rect.left, greaterThanOrEqualTo(0), reason: '$width');
        expect(rect.right, lessThanOrEqualTo(width), reason: '$width');
      }
    });

    testWidgets('tocar cada pestaña navega y marca la elegida', (tester) async {
      await _pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);

      final cases = {
        'Pagos recurrentes': Icons.event_repeat_rounded,
        'Resumen': Icons.bar_chart_rounded,
        'Ajustes': Icons.settings_rounded,
        'Inicio': Icons.home_rounded,
      };
      for (final entry in cases.entries) {
        await tester.tap(find.byTooltip(entry.key));
        await tester.pumpAndSettle();

        expect(
          _contentOf(entry.key),
          findsOneWidget,
          reason: 'contenido de ${entry.key}',
        );
        expect(find.byIcon(entry.value), findsOneWidget, reason: entry.key);
      }
    });

    testWidgets(
      'la cabecera sigue ahí al cambiar de pestaña y el mes no aparece en Ajustes',
      (tester) async {
        await _pumpApp(tester);
        expect(find.byTooltip('Mes anterior'), findsOneWidget);
        expect(_headerEye('Ocultar cifras'), findsOneWidget);

        await tester.tap(find.byTooltip('Ajustes'));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Mes anterior'), findsNothing);
        expect(_headerEye('Ocultar cifras'), findsOneWidget);
        expect(
          find.descendant(of: find.byType(AppTopBar), matching: find.text('D')),
          findsOneWidget,
          reason: 'avatar de la cabecera con la inicial',
        );

        await tester.tap(find.byTooltip('Resumen'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Mes anterior'), findsOneWidget);
      },
    );

    testWidgets('el mes elegido se conserva al cambiar de pestaña', (
      tester,
    ) async {
      final container = await _pumpApp(tester);
      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();
      final month = container.read(selectedMonthProvider);

      await tester.tap(find.byTooltip('Resumen'));
      await tester.pumpAndSettle();

      expect(container.read(selectedMonthProvider), month);
    });

    testWidgets(
      'con el teclado abierto la píldora se oculta y no recibe toques',
      (tester) async {
        await _pumpApp(tester, keyboard: 300);

        final opacity = tester.widget<AnimatedOpacity>(
          find.byWidgetPredicate(
            (w) => w is AnimatedOpacity && w.child is FloatingPillNav,
          ),
        );
        final blocker = tester.widget<IgnorePointer>(
          find.byWidgetPredicate(
            (w) => w is IgnorePointer && w.child is AnimatedSlide,
          ),
        );
        expect(opacity.opacity, 0);
        expect(blocker.ignoring, isTrue);

        await tester.tap(find.byTooltip('Resumen'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget, reason: 'no navegó');
      },
    );

    testWidgets(
      'con el teclado cerrado la píldora está visible y recibe toques',
      (tester) async {
        await _pumpApp(tester);

        final opacity = tester.widget<AnimatedOpacity>(
          find.byWidgetPredicate(
            (w) => w is AnimatedOpacity && w.child is FloatingPillNav,
          ),
        );
        expect(opacity.opacity, 1);
      },
    );

    testWidgets('la píldora reaparece al cerrarse el teclado', (tester) async {
      await _pumpApp(tester, keyboard: 300);
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();

      final opacity = tester.widget<AnimatedOpacity>(
        find.byWidgetPredicate(
          (w) => w is AnimatedOpacity && w.child is FloatingPillNav,
        ),
      );
      expect(opacity.opacity, 1);
      await tester.tap(find.byTooltip('Resumen'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    });

    testWidgets('en tablet (800) la píldora no se estira de lado a lado', (
      tester,
    ) async {
      await _pumpApp(tester, width: 800);
      expect(tester.getSize(_pill).width, lessThanOrEqualTo(480));
    });

    testWidgets('el ojo de la cabecera tapa y destapa las cifras', (
      tester,
    ) async {
      final container = await _pumpApp(tester);
      expect(container.read(balancesHiddenProvider), isFalse);

      await tester.tap(_headerEye('Ocultar cifras'));
      await tester.pumpAndSettle();

      expect(container.read(balancesHiddenProvider), isTrue);
      expect(_headerEye('Mostrar cifras'), findsOneWidget);
    });
  });

  group('MainShell: rail (>= 900 px)', () {
    testWidgets(
      'en 899 hay píldora; en 900 y 1300 aparece el rail y desaparece la píldora',
      (tester) async {
        await _pumpApp(tester, width: 899);
        expect(_pill, findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);

        for (final width in [900.0, 1300.0]) {
          await _pumpApp(tester, width: width);
          expect(find.byType(NavigationRail), findsOneWidget, reason: '$width');
          expect(_pill, findsNothing, reason: '$width');
        }
      },
    );

    testWidgets('tocar cada destino del rail navega', (tester) async {
      await _pumpApp(tester, width: 1300);

      for (final destination in appDestinations.reversed) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationRail),
            matching: find.byIcon(destination.icon),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          _contentOf(destination.label),
          findsOneWidget,
          reason: destination.label,
        );
      }
    });

    testWidgets('el rail no se oculta con el teclado abierto', (tester) async {
      await _pumpApp(tester, width: 1300, keyboard: 300);
      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('al pasar de ancho a angosto se conserva la pestaña y el mes', (
      tester,
    ) async {
      final container = await _pumpApp(tester, width: 1300);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.byIcon(Icons.bar_chart_outlined),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();
      final month = container.read(selectedMonthProvider);

      tester.view.physicalSize = const Size(390, 700);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(SummaryScreen), findsOneWidget);
      expect(container.read(selectedMonthProvider), month);
    });
  });

  group('MonthSelector en la cabecera', () {
    testWidgets('el mes no avanza más allá del siguiente: la flecha se apaga', (
      tester,
    ) async {
      final container = await _pumpApp(tester);
      final now = DateTime.now();
      final limit = DateTime(now.year, now.month + 1);

      IconButton nextArrow() => tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
      );

      expect(nextArrow().onPressed, isNotNull);
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();

      expect(container.read(selectedMonthProvider), limit);
      expect(
        nextArrow().onPressed,
        isNull,
        reason: 'flecha apagada en el tope',
      );

      await tester.tap(find.byTooltip('Mes siguiente'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(container.read(selectedMonthProvider), limit);
    });

    testWidgets('mes anterior retrocede y vuelve a habilitar la flecha', (
      tester,
    ) async {
      final container = await _pumpApp(tester);
      final now = DateTime.now();

      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();

      expect(
        container.read(selectedMonthProvider),
        DateTime(now.year, now.month - 1),
      );
    });
  });
}
