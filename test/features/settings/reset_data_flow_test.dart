import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/app.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/features/auth/login_screen.dart';
import 'package:sistema_cuentas/features/auth/providers/splash_min_time_provider.dart';
import 'package:sistema_cuentas/features/settings/settings_screen.dart';
import 'package:sistema_cuentas/features/settings/widgets/reset_data_dialog.dart';
import 'package:sistema_cuentas/features/settings/widgets/settings_data_section.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../../helpers/auth_fixtures.dart';
import '../../support/fake_account_repository.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/inicio_overrides.dart';
import '../../support/pump_screen_app.dart';
import '../../support/recurring_overrides.dart';
import '../../support/session_overrides.dart';
import '../../helpers/recurring_fixtures.dart';

const _screen = Scaffold(body: SettingsScreen());
const _stubs = [
  AppRoutes.settingsTheme,
  AppRoutes.settingsCategories,
  AppRoutes.settingsMethods,
  AppRoutes.settingsContacts,
  AppRoutes.settingsUsers,
];

const _confirmTitle = 'Eliminar todos mis datos';
const _doneTitle = 'Datos eliminados';
const _loadingText = 'Eliminando tus datos… No cierres la app.';

Finder get _confirm => find.widgetWithText(FilledButton, 'Sí, eliminar todo');
Finder get _cancel => find.widgetWithText(OutlinedButton, 'Cancelar');
Finder get _accept => find.widgetWithText(FilledButton, 'Aceptar');
Finder get _close => find.widgetWithIcon(IconButton, Icons.close_rounded);

/// «Eliminar datos» está al final de una lista por demanda: se baja hasta él.
Future<void> _openDialog(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Eliminar datos'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Eliminar datos'));
  await tester.pumpAndSettle();
}

/// Avanza con tiempo (hay un indicador girando: `pumpAndSettle` no termina).
Future<void> _advance(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<
  ({
    FakeAccountRepository account,
    FakeAuthRepository auth,
    ProviderContainer container,
  })
>
_pumpSettings(WidgetTester tester, {FakeAccountRepository? account}) async {
  final repo = account ?? FakeAccountRepository();
  final s = sessionOverrides();
  final container = await pumpScreenApp(
    tester,
    screen: _screen,
    overrides: [...s.overrides, repo.asOverride],
    stubs: _stubs,
  );
  return (account: repo, auth: s.auth, container: container);
}

void main() {
  group('sección «Mis datos» y apertura del diálogo', () {
    testWidgets(
      'la sección aparece entre el resto y «Cerrar sesión», en rojo',
      (tester) async {
        await _pumpSettings(tester);
        await tester.scrollUntilVisible(
          find.text('Cerrar sesión'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.byType(SettingsDataSection), findsOneWidget);
        expect(find.text('Mis datos'), findsOneWidget);
        expect(find.text('Eliminar datos'), findsOneWidget);
        expect(
          find.text('Empezar desde cero; tu usuario se conserva'),
          findsOneWidget,
        );
        expect(
          tester.getTopLeft(find.text('Mis datos')).dy,
          lessThan(tester.getTopLeft(find.text('Cerrar sesión')).dy),
        );
        // El diálogo no se abre solo.
        expect(find.byType(ResetDataDialog), findsNothing);
      },
    );

    testWidgets(
      'tocar abre el diálogo con lo que se borra y lo que se conserva',
      (tester) async {
        final h = await _pumpSettings(tester);
        await _openDialog(tester);

        expect(find.byType(ResetDataDialog), findsOneWidget);
        expect(find.text(_confirmTitle), findsOneWidget);
        for (final bullet in [
          'Todos tus ingresos y gastos',
          'Tus pagos recurrentes y sus vencimientos',
          'Tus contactos',
          'Tus categorías y medios de pago',
        ]) {
          expect(find.textContaining(bullet), findsOneWidget, reason: bullet);
        }
        expect(
          find.textContaining('Se conserva tu usuario y tu contraseña'),
          findsOneWidget,
        );
        expect(find.textContaining('volver a iniciar sesión'), findsOneWidget);
        expect(_confirm, findsOneWidget);
        expect(tester.widget<FilledButton>(_confirm).onPressed, isNotNull);
        expect(h.account.resetCalls, 0, reason: 'abrir no borra nada');
      },
    );

    testWidgets('Cancelar y la X cierran el diálogo sin llamar al servidor', (
      tester,
    ) async {
      final h = await _pumpSettings(tester);

      await _openDialog(tester);
      await tester.tap(_cancel);
      await tester.pumpAndSettle();
      expect(find.byType(ResetDataDialog), findsNothing);

      await _openDialog(tester);
      await tester.tap(_close);
      await tester.pumpAndSettle();
      expect(find.byType(ResetDataDialog), findsNothing);

      expect(h.account.resetCalls, 0);
      expect(h.container.read(sessionProvider).value, isNotNull);
      expect(h.auth.logoutCalls, 0);
    });

    testWidgets('tocar fuera del diálogo no lo cierra (barrierDismissible)', (
      tester,
    ) async {
      await _pumpSettings(tester);
      await _openDialog(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.byType(ResetDataDialog), findsOneWidget);
    });
  });

  group('flujo completo', () {
    testWidgets(
      'confirmar → eliminando (bloqueado) → «Datos eliminados» → Aceptar cierra la sesión',
      (tester) async {
        final done = Completer<void>();
        final h = await _pumpSettings(
          tester,
          account: FakeAccountRepository(onReset: () => done.future),
        );
        await _openDialog(tester);

        await tester.tap(_confirm);
        await _advance(tester);

        // Eliminando: progreso, botones apagados, no se puede cerrar.
        expect(h.account.resetCalls, 1);
        expect(find.text(_loadingText), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        expect(tester.widget<FilledButton>(_confirm).onPressed, isNull);
        expect(tester.widget<OutlinedButton>(_cancel).onPressed, isNull);
        expect(tester.widget<IconButton>(_close).onPressed, isNull);
        await tester.binding.handlePopRoute(); // «atrás» del sistema
        await _advance(tester);
        expect(find.byType(ResetDataDialog), findsOneWidget);
        await tester.tapAt(const Offset(5, 5)); // fuera del diálogo
        await _advance(tester);
        expect(find.byType(ResetDataDialog), findsOneWidget);
        expect(h.container.read(sessionProvider).value, isNotNull);

        done.complete();
        await _advance(tester);
        await tester.pumpAndSettle();

        // Terminó: solo «Aceptar», sin Cancelar ni X, y la sesión sigue hasta aceptar.
        expect(find.text(_doneTitle), findsOneWidget);
        expect(find.textContaining('Tus datos se eliminaron'), findsOneWidget);
        expect(_accept, findsOneWidget);
        expect(_cancel, findsNothing);
        expect(_confirm, findsNothing);
        expect(tester.widget<IconButton>(_close).onPressed, isNull);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(ResetDataDialog), findsOneWidget);
        expect(h.auth.logoutCalls, 0);
        expect(h.container.read(sessionProvider).value, isNotNull);

        await tester.tap(_accept);
        await tester.pumpAndSettle();

        expect(find.byType(ResetDataDialog), findsNothing);
        expect(h.auth.logoutCalls, 1);
        expect(h.account.resetCalls, 1);
        expect(h.container.read(sessionProvider).value, isNull);
      },
    );

    testWidgets('con la app real, Aceptar lleva al login', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 700);
      addTearDown(tester.view.reset);
      final auth = FakeAuthRepository(
        storedToken: true,
        onFetchSession: () async => buildSession(),
      );
      final account = FakeAccountRepository();
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            splashMinDurationProvider.overrideWithValue(Duration.zero),
            account.asOverride,
            ...dataOverrides(),
            ...recurringRepositoryOverrides(
              dueItems: [buildDue()],
              recurringItems: [buildRecurring()],
            ),
          ],
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsNothing);

      await _openDialog(tester);
      await tester.tap(_confirm);
      await tester.pumpAndSettle();
      expect(find.text(_doneTitle), findsOneWidget);
      await tester.tap(_accept);
      await tester.pumpAndSettle();

      expect(find.byType(ResetDataDialog), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
      expect(auth.logoutCalls, 1);
      expect(account.resetCalls, 1);
    });
  });

  group('error', () {
    testWidgets(
      'avisa en español, vuelve a la confirmación (sesión intacta) y se puede reintentar',
      (tester) async {
        var fail = true;
        final h = await _pumpSettings(
          tester,
          account: FakeAccountRepository(
            onReset: () async {
              if (fail) {
                throw const NetworkException(
                  'No fue posible conectar con el servidor. Revisa tu conexión.',
                );
              }
            },
          ),
        );
        await _openDialog(tester);

        await tester.tap(_confirm);
        await showToast(tester);

        expect(
          find.text(
            'No fue posible conectar con el servidor. Revisa tu conexión.',
          ),
          findsOneWidget,
        );
        expect(find.text(_confirmTitle), findsOneWidget);
        expect(find.text(_loadingText), findsNothing);
        expect(find.text(_doneTitle), findsNothing);
        expect(tester.widget<FilledButton>(_confirm).onPressed, isNotNull);
        expect(tester.widget<OutlinedButton>(_cancel).onPressed, isNotNull);
        expect(h.auth.logoutCalls, 0);
        expect(h.container.read(sessionProvider).value, isNotNull);
        await dismissToasts(tester);

        fail = false;
        await tester.tap(_confirm);
        await tester.pumpAndSettle();

        expect(h.account.resetCalls, 2);
        expect(find.text(_doneTitle), findsOneWidget);
        expect(_accept, findsOneWidget);
      },
    );
  });
}
