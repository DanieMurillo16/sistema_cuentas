import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/features/auth/providers/splash_min_time_provider.dart';
import 'package:sistema_cuentas/app.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/features/movements/widgets/new_movement_sheet.dart';
import 'package:sistema_cuentas/shared/widgets/floating_pill_nav.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/movement_fixtures.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/inicio_overrides.dart';

/// La app completa (router real + MainShell + Inicio) con la sesión abierta.
Future<void> _pumpApp(
  WidgetTester tester, {
  required double width,
  double height = 700,
  double keyboard = 0,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
  // El texto ampliado entra por la plataforma: envolver `App` en un MediaQuery
  // propio le quitaría el teclado (viewInsets) que justo se quiere probar.
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            storedToken: true,
            onFetchSession: () async => buildSession(),
          ),
        ),
        ...dataOverrides(
          items: [
            for (var i = 1; i <= 30; i++)
              buildMovement(id: i, date: DateTime.now()),
          ],
        ),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _fab => find.byType(FloatingActionButton);
Finder get _sheet => find.byType(BottomSheet);

/// ¿El toque en [position] llega a algún hijo de la píldora?
bool _pillReceivesTouchAt(WidgetTester tester, Offset position) {
  final result = HitTestResult();
  tester.binding.hitTestInView(result, position, tester.view.viewId);
  final pill = tester.renderObject(_pill);
  return result.path.any((entry) {
    final target = entry.target;
    return target is RenderObject && _isInside(target, pill);
  });
}

bool _isInside(RenderObject node, RenderObject ancestor) {
  for (
    RenderObject? current = node;
    current != null;
    current = current.parent
  ) {
    if (current == ancestor) return true;
  }
  return false;
}

Finder get _pill => find.byType(FloatingPillNav);

void main() {
  group('el «+» de Inicio y la píldora del menú', () {
    for (final width in [320.0, 390.0, 599.0]) {
      testWidgets(
        'a $width px el «+» queda por encima de la píldora, sin tocarla',
        (tester) async {
          await _pumpApp(tester, width: width);

          expect(_fab, findsOneWidget);
          expect(_pill, findsOneWidget);
          final fab = tester.getRect(_fab);
          final pill = tester.getRect(_pill);
          expect(
            fab.bottom,
            lessThanOrEqualTo(pill.top),
            reason: 'FAB $fab · píldora $pill',
          );
          expect(fab.right, lessThanOrEqualTo(width));
          expect(fab.left, greaterThanOrEqualTo(0));
        },
      );
    }

    testWidgets('con texto 1.5 sigue por encima de la píldora', (tester) async {
      await _pumpApp(tester, width: 390, textScale: 1.5);
      expect(
        tester.getRect(_fab).bottom,
        lessThanOrEqualTo(tester.getRect(_pill).top),
      );
    });

    testWidgets('el «+» no queda tapado: al tocarlo abre la hoja', (
      tester,
    ) async {
      await _pumpApp(tester, width: 390);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(find.byType(NewMovementSheet), findsOneWidget);
    });

    testWidgets(
      'con el teclado abierto la píldora se va y el «+» queda sobre el teclado',
      (tester) async {
        await _pumpApp(tester, width: 390, height: 700, keyboard: 300);

        final fab = tester.getRect(_fab);
        expect(fab.bottom, lessThanOrEqualTo(700 - 300));
        expect(fab.top, greaterThanOrEqualTo(0));
        final opacity = tester.widget<AnimatedOpacity>(
          find.byWidgetPredicate(
            (w) => w is AnimatedOpacity && w.child is FloatingPillNav,
          ),
        );
        expect(opacity.opacity, 0);
      },
    );

    testWidgets('en pantalla ancha (rail) el «+» está dentro de la pantalla', (
      tester,
    ) async {
      await _pumpApp(tester, width: 1300);
      expect(_pill, findsNothing);
      final fab = tester.getRect(_fab);
      expect(fab.bottom, lessThanOrEqualTo(700));
      expect(fab.right, lessThanOrEqualTo(1300));
    });
  });

  group('la hoja del «+» y la píldora del menú', () {
    testWidgets('la hoja se abre en el navegador raíz (por encima del menú)', (
      tester,
    ) async {
      await _pumpApp(tester, width: 390);
      await tester.tap(_fab);
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(NewMovementSheet));
      expect(
        Navigator.of(context),
        same(Navigator.of(context, rootNavigator: true)),
        reason: 'la ruta de la hoja vive en el navegador raíz, no en el de la pestaña',
      );
    });

    for (final width in [320.0, 390.0, 599.0]) {
      testWidgets(
        'a $width px la hoja cubre la píldora y la píldora no recibe toques',
        (tester) async {
          await _pumpApp(tester, width: width);
          final pill = tester.getRect(_pill);
          // Control: sin la hoja, el centro de la píldora SÍ recibe el toque.
          expect(_pillReceivesTouchAt(tester, pill.center), isTrue);

          await tester.tap(_fab);
          await tester.pumpAndSettle();

          final sheet = tester.getRect(_sheet);
          expect(
            sheet.bottom,
            greaterThanOrEqualTo(pill.bottom),
            reason: 'hoja $sheet · píldora $pill',
          );
          expect(
            sheet.top,
            lessThanOrEqualTo(pill.top),
            reason: 'hoja $sheet · píldora $pill',
          );
          expect(sheet.left, lessThanOrEqualTo(pill.left));
          expect(sheet.right, greaterThanOrEqualTo(pill.right));
          for (final point in [
            pill.center,
            pill.topLeft + const Offset(8, 8),
            pill.bottomRight - const Offset(8, 8),
          ]) {
            expect(
              _pillReceivesTouchAt(tester, point),
              isFalse,
              reason: 'toque en $point con la hoja abierta',
            );
          }
        },
      );
    }

    testWidgets('al cerrar la hoja la píldora vuelve a recibir toques', (
      tester,
    ) async {
      await _pumpApp(tester, width: 390);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(_sheet, findsOneWidget);

      Navigator.of(
        tester.element(find.byType(NewMovementSheet)),
        rootNavigator: true,
      ).pop();
      await tester.pumpAndSettle();

      expect(_sheet, findsNothing);
      expect(
        _pillReceivesTouchAt(tester, tester.getRect(_pill).center),
        isTrue,
      );
    });
  });
}
