import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/features/auth/providers/splash_min_time_provider.dart';
import 'package:sistema_cuentas/app.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/shared/navigation/app_destination.dart';
import 'package:sistema_cuentas/shared/navigation/main_shell.dart';
import 'package:sistema_cuentas/shared/widgets/app_top_bar.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/movement_fixtures.dart';
import '../../helpers/recurring_fixtures.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/inicio_overrides.dart';
import '../../support/pump_at_sizes.dart';
import '../../support/recurring_overrides.dart';
import '../../support/session_overrides.dart';

const _person = 'Daniel Murillo';

List<Override> _appOverrides({String fullName = _person}) => [
  splashMinDurationProvider.overrideWithValue(Duration.zero),
  authRepositoryProvider.overrideWithValue(
    FakeAuthRepository(
      storedToken: true,
      onFetchSession: () async => buildSession(fullName: fullName),
    ),
  ),
  ...dataOverrides(items: [buildMovement(date: DateTime.now())]),
  ...recurringRepositoryOverrides(
    dueItems: [buildDue()],
    recurringItems: [buildRecurring()],
  ),
];

Finder get _bar => find.byType(AppTopBar);

/// Los textos que pinta la cabecera (el nombre de la vista, el mes, el avatar).
Finder _inBar(String text) =>
    find.descendant(of: _bar, matching: find.text(text));

/// El marco real con el contenido vacío: solo interesa la cabecera.
Widget _shellAt(String location) =>
    MainShell(location: location, child: const SizedBox.expand());

Future<void> _pumpShell(
  WidgetTester tester,
  String location, {
  double width = 390,
  double textScale = 1,
  String fullName = _person,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 700);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: _appOverrides(fullName: fullName),
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: _shellAt(location),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AppTopBar: el título es el de la vista', () {
    final cases = {
      AppRoutes.home: 'Inicio',
      AppRoutes.recurring: 'Pagos recurrentes',
      AppRoutes.summary: 'Resumen',
      AppRoutes.settings: 'Ajustes',
    };

    for (final entry in cases.entries) {
      testWidgets('MainShell en ${entry.key} muestra «${entry.value}»', (
        tester,
      ) async {
        await _pumpShell(tester, entry.key);

        expect(_inBar(entry.value), findsOneWidget);
        // Las demás pestañas no se cuelan en la cabecera.
        for (final other in cases.values.where((t) => t != entry.value)) {
          expect(
            _inBar(other),
            findsNothing,
            reason: '«$other» en ${entry.key}',
          );
        }
      });
    }

    testWidgets('cubre las cuatro pestañas del menú', (tester) async {
      expect(cases.values.toSet(), appDestinations.map((d) => d.label).toSet());
    });

    testWidgets('una ruta que no es pestaña cae en la primera: Inicio', (
      tester,
    ) async {
      await _pumpShell(tester, '/ruta-desconocida');

      expect(_inBar('Inicio'), findsOneWidget);
    });

    testWidgets('el título usa el estilo titleLarge del tema', (tester) async {
      await _pumpShell(tester, AppRoutes.summary);

      final text = tester.widget<Text>(_inBar('Resumen'));
      final theme = Theme.of(tester.element(_bar));
      expect(text.style, theme.textTheme.titleLarge);
    });

    testWidgets('el selector de mes aparece salvo en Ajustes', (tester) async {
      for (final location in [
        AppRoutes.home,
        AppRoutes.recurring,
        AppRoutes.summary,
      ]) {
        await _pumpShell(tester, location);
        expect(
          find.byTooltip('Mes anterior'),
          findsOneWidget,
          reason: location,
        );
      }
      await _pumpShell(tester, AppRoutes.settings);
      expect(find.byTooltip('Mes anterior'), findsNothing);
    });
  });

  group('AppTopBar: ya no muestra el nombre de la persona', () {
    testWidgets('el nombre completo no está como texto en la cabecera', (
      tester,
    ) async {
      await _pumpShell(tester, AppRoutes.home);

      expect(_inBar(_person), findsNothing);
      expect(find.text(_person), findsNothing);
    });

    testWidgets('sigue el avatar con la inicial (y su etiqueta accesible)', (
      tester,
    ) async {
      await _pumpShell(tester, AppRoutes.home);

      expect(_inBar('D'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Usuario $_person'),
        findsOneWidget,
        reason: 'el nombre queda solo en la etiqueta accesible del avatar',
      );
    });

    testWidgets('con un nombre larguísimo tampoco aparece, solo su inicial', (
      tester,
    ) async {
      await _pumpShell(tester, AppRoutes.home, fullName: longFullName);

      expect(find.text(longFullName), findsNothing);
      expect(_inBar('M'), findsOneWidget);
    });

    testWidgets('sin sesión aún: título presente y avatar sin romperse', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            ...dataOverrides(),
            ...recurringRepositoryOverrides(),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: _shellAt(AppRoutes.recurring),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_inBar('Pagos recurrentes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AppTopBar dentro de la app (router real)', () {
    testWidgets('al tocar cada pestaña la cabecera cambia de nombre', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: _appOverrides(),
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();
      expect(_inBar('Inicio'), findsOneWidget);

      for (final label in [
        'Pagos recurrentes',
        'Resumen',
        'Ajustes',
        'Inicio',
      ]) {
        await tester.tap(find.byTooltip(label));
        await tester.pumpAndSettle();

        expect(_inBar(label), findsOneWidget, reason: label);
        expect(_inBar(_person), findsNothing, reason: label);
        expect(_inBar('D'), findsOneWidget, reason: 'avatar en $label');
      }
    });

    testWidgets(
      'en escritorio (1300, rail) también muestra el nombre de la vista',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1300, 800);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            retry: (_, _) => null,
            overrides: _appOverrides(),
            child: const App(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(NavigationRail),
            matching: find.byIcon(Icons.event_repeat_outlined),
          ),
        );
        await tester.pumpAndSettle();

        expect(_inBar('Pagos recurrentes'), findsOneWidget);
        expect(_inBar(_person), findsNothing);
      },
    );
  });

  group('AppTopBar: sin desbordes', () {
    testWidgets(
      '«Pagos recurrentes» suelta, 320/390/800/1300 × teclado × texto 1.5',
      (tester) async {
        await expectNoOverflow(
          tester,
          const Scaffold(
            body: Column(children: [AppTopBar(title: 'Pagos recurrentes')]),
          ),
          overrides: sessionOverrides().overrides,
        );
      },
    );

    testWidgets('«Pagos recurrentes» sin selector de mes (showMonth: false)', (
      tester,
    ) async {
      await expectNoOverflow(
        tester,
        const Scaffold(
          body: Column(
            children: [AppTopBar(title: 'Pagos recurrentes', showMonth: false)],
          ),
        ),
        overrides: sessionOverrides().overrides,
      );
    });

    testWidgets('MainShell en Pagos recurrentes: todos los tamaños', (
      tester,
    ) async {
      await expectNoOverflow(
        tester,
        _shellAt(AppRoutes.recurring),
        overrides: _appOverrides(fullName: longFullName),
      );
    });

    testWidgets(
      'a 320 px y texto 1.5, «Pagos recurrentes» se lee completo (sin elipsis) y dentro de la pantalla',
      (tester) async {
        await _pumpShell(
          tester,
          AppRoutes.recurring,
          width: 320,
          textScale: 1.5,
        );

        final title = _inBar('Pagos recurrentes');
        expect(title, findsOneWidget);
        final text = tester.widget<Text>(title);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        final rect = tester.getRect(title);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a 320 px el título queda sobre el selector de mes', (
      tester,
    ) async {
      await _pumpShell(tester, AppRoutes.recurring, width: 320);

      final titleBottom = tester.getBottomLeft(_inBar('Pagos recurrentes')).dy;
      final monthTop = tester.getTopLeft(find.byTooltip('Mes anterior')).dy;
      expect(titleBottom, lessThanOrEqualTo(monthTop + 1));
    });
  });
}
