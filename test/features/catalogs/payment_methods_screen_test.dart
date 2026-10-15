import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method_draft.dart';
import 'package:sistema_cuentas/features/catalogs/payment_methods_screen.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/payment_method_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/manage_tile.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/fake_catalogs_repository.dart';
import '../../support/pump_screen_app.dart';
import '../../support/session_overrides.dart';

const _screen = PaymentMethodsScreen();

Finder get _fab => find.byTooltip('Nuevo medio de pago');
Finder get _save => find.widgetWithText(FilledButton, 'Guardar');
Finder get _name => find.widgetWithText(TextFormField, 'Nombre');

List<Override> _overrides(
  FakeCatalogsRepository repo, {
  bool canManage = true,
}) => [
  ...sessionOverrides(
    permissions: {
      Permissions.registerMovements,
      if (canManage) Permissions.manageCatalogs,
    },
  ).overrides,
  catalogsRepositoryProvider.overrideWithValue(repo),
];

FakeCatalogsRepository _repo({
  Future<List<PaymentMethod>> Function()? list,
  Future<PaymentMethod> Function(PaymentMethodDraft draft)? save,
}) => FakeCatalogsRepository(
  onMethods:
      list ??
      () async => [
        buildMethod(id: 2, name: 'Nequi'),
        buildMethod(id: 5, name: 'Bancolombia'),
        buildMethod(id: 6, name: 'Daviplata', active: false),
      ],
  onSaveMethod:
      save ??
      (d) async => buildMethod(id: d.id ?? 50, name: d.name, active: d.active),
);

Future<void> _pump(
  WidgetTester tester,
  FakeCatalogsRepository repo, {
  bool canManage = true,
  bool settle = true,
}) async {
  await pumpScreenApp(
    tester,
    screen: _screen,
    overrides: _overrides(repo, canManage: canManage),
    settle: settle,
  );
}

void main() {
  group('cuatro estados', () {
    testWidgets('cargando', (tester) async {
      final never = Completer<List<PaymentMethod>>();
      await _pump(tester, _repo(list: () => never.future), settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ManageTile), findsNothing);
    });

    testWidgets('datos: activos e inactivos', (tester) async {
      await _pump(tester, _repo());
      expect(find.byType(ManageTile), findsNWidgets(3));
      expect(find.text('Nequi'), findsOneWidget);
      expect(find.text('Inactivo'), findsOneWidget);
    });

    testWidgets('vacío', (tester) async {
      await _pump(tester, _repo(list: () async => const []));
      expect(find.text('Sin medios de pago'), findsOneWidget);
      expect(
        find.text(
          'Crea Nequi, Bancolombia, efectivo… para registrar tus pagos.',
        ),
        findsOneWidget,
      );
      expect(_fab, findsOneWidget);
    });

    testWidgets('error y «Intentar nuevamente»', (tester) async {
      var fail = true;
      final repo = _repo(
        list: () async {
          if (fail) {
            throw const NetworkException('Sin conexión con el servidor.');
          }
          return [buildMethod()];
        },
      );
      await _pump(tester, repo);
      expect(find.text('Sin conexión con el servidor.'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Intentar nuevamente'));
      await tester.pumpAndSettle();

      expect(find.byType(ManageTile), findsOneWidget);
      expect(repo.methodsCalls, 2);
    });
  });

  group('permisos', () {
    testWidgets('sin catalogos.gestionar: solo lectura', (tester) async {
      await _pump(tester, _repo(), canManage: false);
      expect(find.byType(ManageTile), findsNWidgets(3));
      expect(_fab, findsNothing);
      await tester.tap(find.text('Nequi'));
      await tester.pumpAndSettle();
      expect(find.byType(PaymentMethodDialog), findsNothing);
    });
  });

  group('crear', () {
    testWidgets('nombre vacío: error bajo el campo y no llama al servidor', (
      tester,
    ) async {
      final repo = _repo();
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();

      await tester.tap(_save);
      await tester.pumpAndSettle();

      expect(
        find.text('Escribe el nombre del medio de pago (mínimo 2 letras).'),
        findsOneWidget,
      );
      expect(repo.savedMethods, isEmpty);
      expect(find.byType(PaymentMethodDialog), findsOneWidget);
      expect(
        find.text('Activo'),
        findsNothing,
        reason: 'al crear siempre activo',
      );
    });

    testWidgets('éxito: avisa, cierra y la lista muestra el nuevo (ordenado)', (
      tester,
    ) async {
      final repo = _repo();
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.enterText(_name, '  Efectivo ');

      await tester.tap(_save);
      await showToast(tester);

      final draft = repo.savedMethods.single;
      expect(draft.id, isNull);
      expect(draft.name, 'Efectivo');
      expect(draft.active, isTrue);
      expect(find.text('Medio creado'), findsOneWidget);
      await dismissToasts(tester);
      expect(find.byType(PaymentMethodDialog), findsNothing);
      expect(find.text('Efectivo'), findsOneWidget);
      expect(repo.methodsCalls, 1);
      // Orden alfabético: Bancolombia, Daviplata, Efectivo, Nequi.
      expect(
        tester.getTopLeft(find.text('Efectivo')).dy,
        lessThan(tester.getTopLeft(find.text('Nequi')).dy),
      );
    });
  });

  group('editar', () {
    testWidgets(
      'abre con el nombre; desactivar manda id_medio y activo false',
      (tester) async {
        final repo = _repo();
        await _pump(tester, repo);
        await tester.tap(find.text('Nequi'));
        await tester.pumpAndSettle();

        expect(find.text('Editar medio de pago'), findsOneWidget);
        expect(tester.widget<TextFormField>(_name).controller!.text, 'Nequi');
        await tester.tap(find.text('Activo'));
        await tester.pumpAndSettle();

        await tester.tap(_save);
        await showToast(tester);

        final draft = repo.savedMethods.single;
        expect(draft.toJson(), {
          'id_medio': 2,
          'nombre': 'Nequi',
          'activo': false,
        });
        expect(find.text('Medio actualizado'), findsOneWidget);
        await dismissToasts(tester);
        expect(find.byType(PaymentMethodDialog), findsNothing);
        expect(find.text('Inactivo'), findsNWidgets(2));
      },
    );
  });

  group('errores y guardado en curso', () {
    testWidgets('error: avisa y el diálogo sigue abierto con lo escrito', (
      tester,
    ) async {
      final repo = _repo(
        save: (_) async => throw const ApiException(
          'Ya existe un medio con ese nombre.',
          code: 'DUPLICADO',
          statusCode: 409,
        ),
      );
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.enterText(_name, 'Nequi');

      await tester.tap(_save);
      await showToast(tester);

      expect(find.text('Ya existe un medio con ese nombre.'), findsOneWidget);
      expect(find.text('Medio creado'), findsNothing);
      expect(find.byType(PaymentMethodDialog), findsOneWidget);
      expect(tester.widget<TextFormField>(_name).controller!.text, 'Nequi');
      expect(tester.widget<FilledButton>(_save).onPressed, isNotNull);
      await dismissToasts(tester);
    });

    testWidgets('mientras guarda ni la X, ni «Atrás», ni Cancelar cierran', (
      tester,
    ) async {
      final completer = Completer<PaymentMethod>();
      final repo = _repo(save: (_) => completer.future);
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.enterText(_name, 'Efectivo');

      await tester.tap(_save);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<FilledButton>(_save).onPressed, isNull);
      await tester.tap(find.byTooltip('Cerrar'), warnIfMissed: false);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.tap(find.text('Cancelar'), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(PaymentMethodDialog), findsOneWidget);
      expect(repo.savedMethods, hasLength(1));

      completer.complete(buildMethod(id: 50, name: 'Efectivo'));
      await showToast(tester);
      await dismissToasts(tester);
      expect(find.byType(PaymentMethodDialog), findsNothing);
    });

    testWidgets('«Atrás» de la barra vuelve a la pantalla anterior', (
      tester,
    ) async {
      await _pump(tester, _repo());
      await tester.tap(find.byTooltip('Atrás'));
      await tester.pumpAndSettle();
      expect(find.text(previousScreenText), findsOneWidget);
    });
  });

  group('sin desbordes', () {
    testWidgets(
      'lista con nombres de 40+ caracteres en 320/390/800/1300 × teclado × texto 1.5',
      (tester) async {
        final repo = _repo(
          list: () async => [
            for (var i = 0; i < 12; i++)
              buildMethod(
                id: i + 1,
                name: '$longCatalogName $i',
                active: i % 3 != 0,
              ),
          ],
        );
        await expectScreenNoOverflow(
          tester,
          screen: _screen,
          overrides: () => _overrides(repo),
        );
      },
    );

    testWidgets('vacío, error y solo lectura', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => _overrides(_repo(list: () async => const [])),
      );
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => _overrides(
          _repo(
            list: () async =>
                throw NetworkException('Sin conexión con el servidor. ' * 6),
          ),
        ),
      );
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => _overrides(_repo(), canManage: false),
      );
    });

    testWidgets('diálogo «Nuevo medio de pago» abierto con showDialog', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => _overrides(_repo()),
        prepare: (tester) async {
          await tester.tap(_fab);
          await tester.pumpAndSettle();
          expect(find.byType(PaymentMethodDialog), findsOneWidget);
        },
      );
    });

    testWidgets('diálogo «Editar» con nombre largo y error de validación', (
      tester,
    ) async {
      final repo = _repo(
        list: () async => [buildMethod(id: 2, name: longCatalogName)],
      );
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => _overrides(repo),
        prepare: (tester) async {
          await tester.tap(find.byType(ManageTile));
          await tester.pumpAndSettle();
          await tester.enterText(_name, '');
          await tester.tap(_save);
          await tester.pumpAndSettle();
          expect(find.byType(PaymentMethodDialog), findsOneWidget);
        },
      );
    });
  });
}
