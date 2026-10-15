import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/settings/settings_screen.dart';
import 'package:sistema_cuentas/features/settings/widgets/reset_data_dialog.dart';

import '../../support/expect_layout.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/fake_account_repository.dart';
import '../../support/pump_screen_app.dart';
import '../../support/session_overrides.dart';

const _screen = Scaffold(body: SettingsScreen());

Future<void> _showTile(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Eliminar datos'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openDialog(WidgetTester tester) async {
  await _showTile(tester);
  await tester.tap(find.text('Eliminar datos'));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(ResetDataDialog), findsOneWidget);
}

/// Hasta el paso pedido, avanzando con tiempo (hay un indicador girando).
Future<void> _toLoading(WidgetTester tester) async {
  await _openDialog(tester);
  await tester.tap(find.widgetWithText(FilledButton, 'Sí, eliminar todo'));
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.textContaining('Eliminando tus datos'), findsOneWidget);
}

Future<void> _toDone(WidgetTester tester, Completer<void> gate) async {
  await _toLoading(tester);
  gate.complete();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  // Con el teclado abierto el encabezado se oculta: se mira el cuerpo.
  expect(find.textContaining('Tus datos se eliminaron'), findsOneWidget);
}

void main() {
  group('Ajustes con la sección «Mis datos»', () {
    testWidgets('sin desbordes en 320/390/800/1300 × teclado × texto 1.5', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => [
          ...sessionOverrides(fullName: 'x' * 60).overrides,
          FakeAccountRepository().asOverride,
        ],
        // La lista es por demanda: se baja hasta construir la sección nueva.
        prepare: _showTile,
      );
    });

    // En pruebas no se carga Inter: se usa una fuente más ancha (1 em por
    // carácter), así que el conteo de líneas es más estricto que en el teléfono.
    for (final (width, scale, maxLines) in [
      (320.0, 1.5, 2),
      (390.0, 1.0, 1),
      (800.0, 1.0, 1),
    ]) {
      testWidgets(
        'el título «Eliminar datos» ocupa ≤ $maxLines línea(s) a $width px · texto $scale',
        (tester) async {
          await pumpScreenApp(
            tester,
            screen: _screen,
            overrides: [
              ...sessionOverrides().overrides,
              FakeAccountRepository().asOverride,
            ],
            width: width,
            textScale: scale,
          );
          await _showTile(tester);

          expectMaxLines(tester, find.text('Eliminar datos'), maxLines);
          expect(
            tester.getRect(find.text('Eliminar datos')).right,
            lessThanOrEqualTo(width),
          );
        },
      );
    }
  });

  group('diálogo «Eliminar datos» (showDialog) sin desbordes', () {
    // Matriz completa 320/390/800/1300 × teclado 0/300 × texto 1.0/1.5 en cada
    // uno de los tres pasos.
    testWidgets('paso 1: confirmación', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => [
          ...sessionOverrides().overrides,
          FakeAccountRepository().asOverride,
        ],
        prepare: _openDialog,
      );
    });

    testWidgets('paso 2: eliminando (progreso)', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => [
          ...sessionOverrides().overrides,
          FakeAccountRepository(onReset: () => Completer<void>().future)
              .asOverride,
        ],
        prepare: _toLoading,
      );
    });

    testWidgets('paso 3: datos eliminados (solo Aceptar)', (tester) async {
      late Completer<void> gate;
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () {
          gate = Completer<void>();
          return [
            ...sessionOverrides().overrides,
            FakeAccountRepository(onReset: () => gate.future).asOverride,
          ];
        },
        prepare: (tester) => _toDone(tester, gate),
      );
    });

    testWidgets('error: toast con mensaje largo sobre la confirmación', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => [
          ...sessionOverrides().overrides,
          FakeAccountRepository(
            onReset: () async => throw NetworkException(
              'No fue posible conectar con el servidor. ' * 4,
            ),
          ).asOverride,
        ],
        widths: const [320, 390],
        scales: const [1.5],
        prepare: (tester) async {
          await _openDialog(tester);
          await tester.tap(
            find.widgetWithText(FilledButton, 'Sí, eliminar todo'),
          );
          await showToast(tester);
          expect(find.textContaining('Se conserva tu usuario'), findsOneWidget);
          await dismissToasts(tester);
        },
      );
    });
  });
}
