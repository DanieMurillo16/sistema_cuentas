import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/initial_balance/widgets/initial_balance_dialog.dart';
import 'package:sistema_cuentas/features/settings/settings_screen.dart';
import 'package:sistema_cuentas/features/settings/widgets/settings_profile_card.dart';
import 'package:sistema_cuentas/features/settings/widgets/settings_tile.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';
import 'package:sistema_cuentas/shared/widgets/confirm_action_dialog.dart';

import '../../helpers/auth_fixtures.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/inicio_overrides.dart';
import '../../support/pump_screen_app.dart';
import '../../support/session_overrides.dart';

const _screen = Scaffold(body: SettingsScreen());
const _stubs = [
  AppRoutes.settingsTheme,
  AppRoutes.settingsCategories,
  AppRoutes.settingsMethods,
  AppRoutes.settingsContacts,
  AppRoutes.settingsUsers,
];

/// Las entradas del menú, sin la de «Eliminar datos» (su construcción depende
/// de cuánto alcanza a pintar la lista por demanda; tiene su propia prueba en
/// `reset_data_flow_test.dart`).
final _menuTiles = find.byWidgetPredicate(
  (widget) => widget is SettingsTile && widget.title != 'Eliminar datos',
);

Finder get _logoutButton =>
    find.widgetWithText(OutlinedButton, 'Cerrar sesión');

/// El botón está al final de una lista por demanda: se desplaza hasta que se
/// construye y luego se toca.
Future<void> _tapLogout(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    _logoutButton,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(_logoutButton);
  await tester.pumpAndSettle();
  await tester.tap(_logoutButton);
}

void main() {
  group('perfil', () {
    testWidgets('muestra nombre, usuario y rol de la sesión', (tester) async {
      final s = sessionOverrides(fullName: 'daniel murillo');
      await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
      );

      expect(find.byType(SettingsProfileCard), findsOneWidget);
      expect(
        find.text('Daniel murillo'),
        findsOneWidget,
        reason: 'inicial en mayúscula',
      );
      expect(find.text('daniel · Usuario'), findsOneWidget);
    });

    testWidgets('administrador: lo dice en el perfil', (tester) async {
      final s = adminSession();
      await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
      );
      expect(find.text('daniel · Administrador'), findsOneWidget);
    });

    testWidgets('sin sesión no hay tarjeta de perfil (ni revienta)', (
      tester,
    ) async {
      final s = sessionOverrides();
      s.auth.storedToken = false;
      await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
      );
      expect(find.text('daniel · Usuario'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('entradas del menú', () {
    testWidgets(
      'usuario normal: Tema, tres catálogos, Saldo inicial y NO «Usuarios»',
      (tester) async {
        final s = sessionOverrides();
        await pumpScreenApp(
          tester,
          screen: _screen,
          overrides: s.overrides,
          stubs: _stubs,
        );

        // Tema + Categorías, Medios de pago, Contactos + Saldo inicial.
        expect(_menuTiles, findsNWidgets(5));
        expect(find.text('Apariencia'), findsOneWidget);
        expect(find.text('Tema'), findsOneWidget);
        expect(find.text('Saldo inicial'), findsOneWidget);
        expect(find.text('Categorías'), findsOneWidget);
        expect(find.text('Medios de pago'), findsOneWidget);
        expect(find.text('Contactos'), findsOneWidget);
        expect(find.text('Usuarios'), findsNothing);
        expect(find.text('Administración'), findsNothing);
      },
    );

    testWidgets('quien gestiona catálogos pero no usuarios tampoco lo ve', (
      tester,
    ) async {
      final s = sessionOverrides(
        role: 'ADMINISTRADOR',
        permissions: const {Permissions.manageCatalogs},
      );
      await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
      );
      expect(find.text('Usuarios'), findsNothing);
      // Sin permiso de registrar movimientos no hay «Saldo inicial».
      expect(find.text('Saldo inicial'), findsNothing);
      expect(_menuTiles, findsNWidgets(4));
    });

    testWidgets('con el permiso usuarios.gestionar aparece «Usuarios»', (
      tester,
    ) async {
      final s = adminSession();
      await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
      );

      expect(_menuTiles, findsNWidgets(6));
      expect(find.text('Administración'), findsOneWidget);
      expect(find.text('Usuarios'), findsOneWidget);
    });

    testWidgets('«Apariencia → Tema» muestra el modo actual (Automático por '
        'defecto)', (tester) async {
      final s = sessionOverrides();
      await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
      );

      expect(find.text('Apariencia'), findsOneWidget);
      expect(find.text('Automático'), findsOneWidget);
    });

    testWidgets('«Apariencia» va antes que «Catálogos»', (tester) async {
      final s = sessionOverrides();
      await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
      );

      expect(
        tester.getTopLeft(find.text('Apariencia')).dy,
        lessThan(tester.getTopLeft(find.text('Catálogos')).dy),
      );
    });

    for (final (label, route) in [
      ('Tema', AppRoutes.settingsTheme),
      ('Categorías', AppRoutes.settingsCategories),
      ('Medios de pago', AppRoutes.settingsMethods),
      ('Contactos', AppRoutes.settingsContacts),
      ('Usuarios', AppRoutes.settingsUsers),
    ]) {
      testWidgets('tocar «$label» va a $route', (tester) async {
        final s = adminSession();
        await pumpScreenApp(
          tester,
          screen: _screen,
          overrides: s.overrides,
          stubs: _stubs,
        );

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(find.text('Destino $route'), findsOneWidget);
      });
    }
  });

  group('Saldo inicial', () {
    testWidgets('con permiso de registrar, «Saldo inicial» abre el diálogo', (
      tester,
    ) async {
      final s = sessionOverrides();
      await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: [...s.overrides, ...dataOverrides()],
        stubs: _stubs,
      );

      await tester.tap(find.text('Saldo inicial'));
      await tester.pumpAndSettle();

      expect(find.byType(InitialBalanceDialog), findsOneWidget);
      expect(find.text('¿Con cuánto cuentas hoy?'), findsOneWidget);
    });

    testWidgets('su subtítulo explica para qué sirve', (tester) async {
      final s = sessionOverrides();
      await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
      );

      expect(
        find.text('Con cuánto cuentas hoy, por medio de pago'),
        findsOneWidget,
      );
    });
  });

  group('cerrar sesión', () {
    testWidgets('pide confirmación y NO cierra todavía', (tester) async {
      final s = sessionOverrides();
      await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
      );

      await _tapLogout(tester);
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmActionDialog), findsOneWidget);
      expect(
        find.text('Saldrás de tu cuenta en este dispositivo.'),
        findsOneWidget,
      );
      expect(s.auth.logoutCalls, 0);
    });

    testWidgets('Cancelar cierra el diálogo sin llamar a signOut', (
      tester,
    ) async {
      final s = sessionOverrides();
      final container = await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
      );
      await _tapLogout(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmActionDialog), findsNothing);
      expect(s.auth.logoutCalls, 0);
      expect(container.read(sessionProvider).value, isNotNull);
    });

    testWidgets('la X del diálogo tampoco cierra la sesión', (tester) async {
      final s = sessionOverrides();
      await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
      );
      await _tapLogout(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmActionDialog), findsNothing);
      expect(s.auth.logoutCalls, 0);
    });

    testWidgets('confirmar llama a signOut y la sesión queda en null', (
      tester,
    ) async {
      final s = sessionOverrides();
      final container = await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
      );
      expect(container.read(sessionProvider).value, isNotNull);
      await _tapLogout(tester);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmActionDialog),
          matching: find.widgetWithText(FilledButton, 'Cerrar sesión'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmActionDialog), findsNothing);
      expect(s.auth.logoutCalls, 1);
      expect(container.read(sessionProvider).value, isNull);
      expect(find.text('daniel · Usuario'), findsNothing);
    });
  });

  group('distribución', () {
    testWidgets('en escritorio el contenido no se estira (formMaxWidth)', (
      tester,
    ) async {
      final s = adminSession();
      await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
        width: 1300,
      );

      final card = tester.getRect(find.byType(SettingsProfileCard));
      expect(card.width, lessThanOrEqualTo(DesignTokens.formMaxWidth));
      expect(
        (card.center.dx - 650).abs(),
        lessThan(1),
        reason: 'centrado en la pantalla',
      );
    });

    testWidgets('en teléfono ocupa casi todo el ancho', (tester) async {
      final s = adminSession();
      await pumpScreenApp(
        tester,
        screen: _screen,
        overrides: s.overrides,
        stubs: _stubs,
      );
      expect(
        tester.getRect(find.byType(SettingsProfileCard)).width,
        390 - 2 * DesignTokens.spaceMd,
      );
    });
  });

  group('sin desbordes', () {
    testWidgets(
      'administrador con un nombre de 60+ caracteres en 320/390/800/1300 × teclado × texto 1.5',
      (tester) async {
        expect(longFullName.length, greaterThan(40));
        await expectScreenNoOverflow(
          tester,
          screen: _screen,
          overrides: () => adminSession(fullName: longFullName).overrides,
        );
      },
    );

    testWidgets('usuario normal (sin «Usuarios»)', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => sessionOverrides().overrides,
      );
    });

    testWidgets('con el diálogo de cerrar sesión abierto (showDialog)', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => adminSession(fullName: longFullName).overrides,
        prepare: (tester) async {
          await _tapLogout(tester);
          await tester.pumpAndSettle();
          expect(find.byType(ConfirmActionDialog), findsOneWidget);
        },
      );
    });
  });
}
