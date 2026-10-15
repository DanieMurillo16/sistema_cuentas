import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/initial_balance/widgets/initial_balance_dialog.dart';
import 'package:sistema_cuentas/features/initial_balance/widgets/initial_balance_method_fields.dart';
import 'package:sistema_cuentas/features/initial_balance/widgets/initial_balance_no_methods.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/models/movement_draft.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/expect_screen_no_overflow.dart';
import '../../../support/fake_catalogs_repository.dart';
import '../../../support/fake_movements_repository.dart';
import '../../../support/inicio_overrides.dart';
import '../../../support/pick_catalog_card.dart';
import '../../../support/pump_screen_app.dart';
import '../../../support/session_overrides.dart';

const _stubs = [AppRoutes.settingsMethods];

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () => showInitialBalanceDialog(context),
      child: const Text('Abrir'),
    ),
  );
}

class _Rig {
  _Rig({
    List<PaymentMethod>? methods,
    Future<List<PaymentMethod>> Function()? onMethods,
    Future<Movement> Function(MovementDraft draft)? onRegister,
  }) {
    final list = methods ?? defaultMethods();
    catalogs = FakeCatalogsRepository(
      onCategories: () async => [buildCategory(id: 3)],
      onMethods: onMethods ?? () async => list,
      onSaveCategory: (draft) async => Category(
        id: 90,
        type: draft.type,
        name: draft.name,
        isCapital: draft.isCapital,
        active: draft.active,
      ),
    );
    movements = FakeMovementsRepository(
      onList: (_, _) async => const [],
      onRegister:
          onRegister ??
          (draft) async => buildMovement(
            id: 100 + draft.methodId,
            valueCents: draft.amountPesos * 100,
            methodId: draft.methodId,
            description: draft.description,
            date: draft.date,
          ),
    );
  }

  late final FakeCatalogsRepository catalogs;
  late final FakeMovementsRepository movements;

  List<Override> get overrides => [
    ...sessionOverrides().overrides,
    ...dataOverrides(movements: movements, catalogs: catalogs),
  ];
}

Finder get _dialog => find.byType(InitialBalanceDialog);
Finder get _save =>
    find.descendant(of: _dialog, matching: find.bySubtype<FilledButton>());
Finder get _close =>
    find.descendant(of: _dialog, matching: find.byTooltip('Cerrar'));
Finder _field(int methodId) =>
    find.byKey(ValueKey('initial-balance-$methodId'));
Finder get _singleValue =>
    find.widgetWithText(TextFormField, 'Valor que tienes hoy');

Future<ProviderContainer> _open(
  WidgetTester tester,
  _Rig rig, {
  double width = 390,
  double textScale = 1,
}) async {
  final container = await pumpScreenApp(
    tester,
    screen: const _Host(),
    overrides: rig.overrides,
    stubs: _stubs,
    width: width,
    textScale: textScale,
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _enter(WidgetTester tester, int methodId, String text) async {
  await tester.ensureVisible(_field(methodId));
  await tester.enterText(_field(methodId), text);
  await tester.pump();
}

Future<void> _chooseMode(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: _dialog,
      matching: find.ancestor(
        of: find.text(label),
        matching: find.byType(InkWell),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.ensureVisible(_save);
  await tester.pumpAndSettle();
  await tester.tap(_save);
}

List<PaymentMethod> _methods(int count, {String? prefix}) => [
  for (var i = 1; i <= count; i++)
    buildMethod(id: i, name: prefix == null ? 'Medio $i' : '$prefix $i'),
];

void main() {
  group('apertura (por medio)', () {
    testWidgets('título, subtítulo, un campo por medio activo y total en 0', (
      tester,
    ) async {
      final rig = _Rig(
        methods: [
          buildMethod(id: 2, name: 'Nequi'),
          buildMethod(id: 5, name: 'Bancolombia'),
          buildMethod(id: 9, name: 'Viejo', active: false),
        ],
      );
      await _open(tester, rig);

      expect(find.text('Saldo inicial'), findsOneWidget);
      expect(find.text('¿Con cuánto cuentas hoy?'), findsOneWidget);
      expect(find.text('Por medio'), findsOneWidget);
      expect(find.text('Un valor'), findsOneWidget);
      expect(_field(2), findsOneWidget);
      expect(_field(5), findsOneWidget);
      expect(_field(9), findsNothing, reason: 'los inactivos no salen');
      expect(find.text('Nequi'), findsOneWidget);
      expect(find.text('Bancolombia'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text(r'$ 0'), findsOneWidget);
      expect(find.text('Guardar saldo'), findsOneWidget);
    });

    testWidgets('el botón está habilitado y hay «Cancelar»', (tester) async {
      await _open(tester, _Rig());

      expect(tester.widget<FilledButton>(_save).onPressed, isNotNull);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('los campos dan formato de miles al escribir', (tester) async {
      await _open(tester, _Rig());

      await _enter(tester, 2, '1500000');

      expect(
        tester.widget<TextFormField>(_field(2)).controller!.text,
        '1.500.000',
      );
    });
  });

  group('total en vivo', () {
    testWidgets('suma lo escrito en cada medio y baja al borrar', (
      tester,
    ) async {
      await _open(tester, _Rig());

      await _enter(tester, 2, '1500000');
      expect(find.text(r'$ 1.500.000'), findsWidgets);
      await _enter(tester, 5, '250000');
      expect(find.text(r'$ 1.750.000'), findsOneWidget);

      await _enter(tester, 2, '');
      expect(find.text(r'$ 250.000'), findsWidgets);
      expect(find.text(r'$ 1.750.000'), findsNothing);
    });

    testWidgets('un cero no suma', (tester) async {
      await _open(tester, _Rig());

      await _enter(tester, 2, '0');
      await _enter(tester, 5, '1000');

      expect(find.text(r'$ 1.000'), findsWidgets);
    });
  });

  group('modo «Un valor»', () {
    testWidgets('cambia los campos: un valor y el medio', (tester) async {
      await _open(tester, _Rig());

      await _chooseMode(tester, 'Un valor');

      expect(_singleValue, findsOneWidget);
      expect(find.text('En qué medio lo tienes'), findsOneWidget);
      expect(_field(2), findsNothing);
      expect(find.byType(InitialBalanceMethodFields), findsNothing);
    });

    testWidgets('el total muestra lo escrito aunque falte elegir el medio', (
      tester,
    ) async {
      await _open(tester, _Rig());
      await _chooseMode(tester, 'Un valor');

      await tester.enterText(_singleValue, '2000000');
      await tester.pump();

      expect(find.text(r'$ 2.000.000'), findsWidgets);
      expect(find.text(r'$ 0'), findsNothing);
    });

    testWidgets('al elegir el medio el total no cambia', (tester) async {
      await _open(tester, _Rig());
      await _chooseMode(tester, 'Un valor');
      await tester.enterText(_singleValue, '2000000');
      await tester.pump();

      await pickCatalogOption(tester, 'En qué medio lo tienes', 'Nequi');

      expect(find.text(r'$ 2.000.000'), findsWidgets);
    });

    testWidgets('borrar el valor devuelve el total a 0', (tester) async {
      await _open(tester, _Rig());
      await _chooseMode(tester, 'Un valor');
      await tester.enterText(_singleValue, '5000');
      await tester.pump();

      await tester.enterText(_singleValue, '');
      await tester.pump();

      expect(find.text(r'$ 0'), findsOneWidget);
    });

    testWidgets('sin escribir nada pide el valor y el medio', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _chooseMode(tester, 'Un valor');

      await _tapSave(tester);
      await tester.pumpAndSettle();

      expect(find.text('Escribe el valor.'), findsOneWidget);
      expect(find.text('Elige el medio de pago.'), findsOneWidget);
      expect(rig.movements.registerCalls, 0);
    });

    testWidgets('un valor y un medio: registra uno solo', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _chooseMode(tester, 'Un valor');
      await tester.enterText(_singleValue, '900000');
      await pickCatalogOption(tester, 'En qué medio lo tienes', 'Bancolombia');

      await _tapSave(tester);
      await showToast(tester);
      await dismissToasts(tester);

      expect(rig.movements.registerCalls, 1);
      expect(rig.movements.drafts.single.amountPesos, 900000);
      expect(rig.movements.drafts.single.methodId, 5);
    });

    testWidgets('volver a «Por medio» conserva lo que se escribió', (
      tester,
    ) async {
      await _open(tester, _Rig());
      await _enter(tester, 2, '5000');

      await _chooseMode(tester, 'Un valor');
      await _chooseMode(tester, 'Por medio');

      expect(tester.widget<TextFormField>(_field(2)).controller!.text, '5.000');
    });
  });

  group('validación', () {
    testWidgets('todo vacío: aviso «Escribe al menos un valor.» y no guarda', (
      tester,
    ) async {
      final rig = _Rig();
      await _open(tester, rig);

      await _tapSave(tester);
      await showToast(tester);

      expect(find.text('Escribe al menos un valor.'), findsOneWidget);
      expect(rig.movements.registerCalls, 0);
      expect(_dialog, findsOneWidget);
      await dismissToasts(tester);
    });

    testWidgets('un cero escrito se marca bajo el campo y no guarda', (
      tester,
    ) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _enter(tester, 2, '0');

      await _tapSave(tester);
      await tester.pumpAndSettle();

      expect(find.text('Escribe un valor mayor que cero.'), findsOneWidget);
      expect(rig.movements.registerCalls, 0);
    });
  });

  group('guardar por medio', () {
    testWidgets('un movimiento por cada medio con valor; el vacío se ignora', (
      tester,
    ) async {
      final rig = _Rig(methods: _methods(3));
      final container = await _open(tester, rig);
      // Inicio (que vive en el menú) ya tiene cargados los movimientos.
      await container.read(movementsProvider.future);
      await _enter(tester, 1, '1500000');
      await _enter(tester, 3, '250000');

      await _tapSave(tester);
      await showToast(tester);

      expect(rig.movements.registerCalls, 2);
      expect(
        [for (final d in rig.movements.drafts) (d.methodId, d.amountPesos)],
        [(1, 1500000), (3, 250000)],
      );
      for (final draft in rig.movements.drafts) {
        expect(draft.type, MovementType.income);
        expect(draft.description, 'Saldo inicial');
        expect(draft.date, dateOnly(DateTime.now()));
      }
      expect(find.text('Saldo inicial registrado'), findsOneWidget);
      expect(_dialog, findsNothing);
      expect(
        container.read(movementsProvider).requireValue.map((m) => m.id),
        containsAll([101, 103]),
      );
      await dismissToasts(tester);
    });

    testWidgets('la categoría «Saldo inicial» se crea una vez, de capital', (
      tester,
    ) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _enter(tester, 2, '1000');
      await _enter(tester, 5, '2000');

      await _tapSave(tester);
      await showToast(tester);
      await dismissToasts(tester);

      expect(rig.catalogs.savedCategories, hasLength(1));
      expect(rig.catalogs.savedCategories.single.isCapital, isTrue);
    });

    testWidgets('mientras guarda: progreso, campos de solo lectura y no se '
        'puede cerrar', (tester) async {
      final gate = Completer<Movement>();
      final rig = _Rig(onRegister: (_) => gate.future);
      await _open(tester, rig);
      await _enter(tester, 2, '1000');

      await _tapSave(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.descendant(
          of: _save,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(_save).onPressed, isNull);
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: _field(2), matching: find.byType(TextField)),
            )
            .readOnly,
        isTrue,
      );
      await tester.tap(_close, warnIfMissed: false);
      await tester.pump();
      await tester.tapAt(const Offset(2, 2));
      await tester.pump();
      expect(_dialog, findsOneWidget);

      gate.complete(buildMovement(id: 7));
      await showToast(tester);
      expect(_dialog, findsNothing);
      await dismissToasts(tester);
    });

    testWidgets('anti doble envío: dos toques, una sola llamada', (
      tester,
    ) async {
      final gate = Completer<Movement>();
      final rig = _Rig(onRegister: (_) => gate.future);
      await _open(tester, rig);
      await _enter(tester, 2, '1000');

      await _tapSave(tester);
      await tester.pump();
      await tester.tap(_save, warnIfMissed: false);
      await tester.pump();

      expect(rig.movements.registerCalls, 1);
      gate.complete(buildMovement(id: 7));
      await showToast(tester);
      await dismissToasts(tester);
      expect(rig.movements.registerCalls, 1);
    });

    testWidgets('error: toast en español, el diálogo sigue y reintentar no '
        'repite lo ya registrado', (tester) async {
      var fail = true;
      final rig = _Rig(
        methods: _methods(2),
        onRegister: (draft) async {
          if (draft.methodId == 2 && fail) {
            throw const NetworkException('Sin conexión con el servidor.');
          }
          return buildMovement(
            id: 100 + draft.methodId,
            methodId: draft.methodId,
          );
        },
      );
      await _open(tester, rig);
      await _enter(tester, 1, '1000');
      await _enter(tester, 2, '2000');

      await _tapSave(tester);
      await showToast(tester);

      expect(find.text('Sin conexión con el servidor.'), findsOneWidget);
      expect(_dialog, findsOneWidget);
      expect(find.text('Saldo inicial registrado'), findsNothing);
      await dismissToasts(tester);

      fail = false;
      await tester.tap(_save);
      await showToast(tester);

      expect(rig.movements.drafts.map((d) => d.methodId), [1, 2, 2]);
      expect(_dialog, findsNothing);
      await dismissToasts(tester);
    });
  });

  group('«Cancelar» y cerrar', () {
    testWidgets('Cancelar y la X cierran sin registrar', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(_dialog, findsNothing);

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(_close);
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(rig.movements.registerCalls, 0);
    });
  });

  group('medios de pago sin cargar o sin medios', () {
    testWidgets('sin medios activos: texto, botón «Ir a Medios de pago» y '
        'ningún campo', (tester) async {
      await _open(tester, _Rig(methods: const []));

      expect(find.byType(InitialBalanceNoMethods), findsOneWidget);
      expect(
        find.textContaining('Aún no tienes medios de pago'),
        findsOneWidget,
      );
      expect(find.text('Ir a Medios de pago'), findsOneWidget);
      expect(find.byType(InitialBalanceMethodFields), findsNothing);
    });

    testWidgets('solo inactivos cuenta como sin medios', (tester) async {
      await _open(
        tester,
        _Rig(methods: [buildMethod(id: 9, name: 'Viejo', active: false)]),
      );

      expect(find.byType(InitialBalanceNoMethods), findsOneWidget);
    });

    testWidgets('«Ir a Medios de pago» cierra el diálogo y navega', (
      tester,
    ) async {
      await _open(tester, _Rig(methods: const []));

      await tester.tap(find.text('Ir a Medios de pago'));
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(find.text('Destino ${AppRoutes.settingsMethods}'), findsOneWidget);
    });

    testWidgets('cargando los medios: barra de progreso', (tester) async {
      final gate = Completer<List<PaymentMethod>>();
      final rig = _Rig(onMethods: () => gate.future);
      await pumpScreenApp(
        tester,
        screen: const _Host(),
        overrides: rig.overrides,
        stubs: _stubs,
      );
      await tester.tap(find.text('Abrir'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.descendant(
          of: _dialog,
          matching: find.byType(LinearProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(find.byType(InitialBalanceMethodFields), findsNothing);

      gate.complete(defaultMethods());
      await tester.pumpAndSettle();
      expect(find.byType(InitialBalanceMethodFields), findsOneWidget);
    });

    testWidgets(
      'error al cargar: mensaje y «Intentar nuevamente» que recarga',
      (tester) async {
        var fail = true;
        final rig = _Rig(
          onMethods: () async {
            if (fail) throw const NetworkException('Sin conexión.');
            return defaultMethods();
          },
        );
        await _open(tester, rig);
        expect(find.text('Sin conexión.'), findsOneWidget);

        fail = false;
        await tester.tap(find.text('Intentar nuevamente'));
        await tester.pumpAndSettle();

        expect(find.byType(InitialBalanceMethodFields), findsOneWidget);
      },
    );
  });

  group('campos de dos en dos (AppFormPair, mínimo de campos cortos)', () {
    double top(WidgetTester tester, int id) => tester.getTopLeft(_field(id)).dy;

    testWidgets('390 px: Nequi y Bancolombia comparten fila', (tester) async {
      await _open(tester, _Rig());

      expect(top(tester, 2), top(tester, 5));
      expect(
        tester.getTopLeft(_field(5)).dx,
        greaterThan(tester.getTopLeft(_field(2)).dx),
      );
    });

    testWidgets('320 px: el diálogo deja 240 px útiles y aún caben en pareja', (
      tester,
    ) async {
      await _open(tester, _Rig(), width: 320);

      expect(top(tester, 2), top(tester, 5));
    });

    testWidgets('300 px (menos de 240 útiles): se apilan', (tester) async {
      await _open(tester, _Rig(), width: 300);

      expect(top(tester, 5), greaterThan(top(tester, 2)));
      expect(tester.getTopLeft(_field(5)).dx, tester.getTopLeft(_field(2)).dx);
    });

    testWidgets('con texto 1.5 a 390 px también se apilan (el mínimo crece)', (
      tester,
    ) async {
      await _open(tester, _Rig(), textScale: 1.5);

      expect(top(tester, 5), greaterThan(top(tester, 2)));
    });

    testWidgets('800 px: en pareja', (tester) async {
      await _open(tester, _Rig(), width: 800);

      expect(top(tester, 2), top(tester, 5));
    });

    testWidgets('6 medios a 390 px: tres filas de dos', (tester) async {
      await _open(tester, _Rig(methods: _methods(6)));

      expect(top(tester, 1), top(tester, 2));
      expect(top(tester, 3), top(tester, 4));
      expect(top(tester, 5), top(tester, 6));
      expect(top(tester, 3), greaterThan(top(tester, 1)));
      expect(top(tester, 5), greaterThan(top(tester, 3)));
    });

    testWidgets('5 medios: el último queda solo, a todo el ancho', (
      tester,
    ) async {
      await _open(tester, _Rig(methods: _methods(5)));

      expect(top(tester, 5), greaterThan(top(tester, 3)));
      expect(
        tester.getSize(_field(5)).width,
        greaterThan(tester.getSize(_field(1)).width + 10),
      );
    });

    testWidgets('un solo medio: a todo el ancho', (tester) async {
      await _open(tester, _Rig(methods: _methods(1)));

      expect(_field(1), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('sin desbordes (320/390/800/1300 × teclado × texto 1.5)', () {
    final longMethods = _methods(6, prefix: longCatalogName);

    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(_dialog, findsOneWidget);
    }

    testWidgets('6 medios de nombre largo, por medio', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const _Host(),
        overrides: () => _Rig(methods: longMethods).overrides,
        prepare: open,
      );
    });

    testWidgets('6 medios, uno con un importe de 6 dígitos', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const _Host(),
        overrides: () => _Rig(methods: longMethods).overrides,
        prepare: (tester) async {
          await open(tester);
          await _enter(tester, 1, '999999');
        },
      );
    });

    testWidgets('un medio con 12 dígitos (el máximo del campo)', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: const _Host(),
        overrides: () => _Rig(methods: longMethods).overrides,
        prepare: (tester) async {
          await open(tester);
          await _enter(tester, 1, '999999999999');
        },
      );
    });

    testWidgets('un medio con 8 dígitos y texto 1.5 a 320 px', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const _Host(),
        overrides: () => _Rig(methods: longMethods).overrides,
        widths: const [320],
        scales: const [1.5],
        prepare: (tester) async {
          await open(tester);
          await _enter(tester, 1, '99999999');
        },
      );
    });

    testWidgets('los 6 medios con 12 dígitos cada uno (la suma de 13)', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: const _Host(),
        overrides: () => _Rig(methods: longMethods).overrides,
        prepare: (tester) async {
          await open(tester);
          for (final method in longMethods) {
            await _enter(tester, method.id, '999999999999');
          }
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('modo «Un valor»', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const _Host(),
        overrides: () => _Rig(methods: longMethods).overrides,
        prepare: (tester) async {
          await open(tester);
          await _chooseMode(tester, 'Un valor');
        },
      );
    });

    testWidgets('modo «Un valor» con un medio de nombre largo elegido', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: const _Host(),
        overrides: () => _Rig(methods: longMethods).overrides,
        prepare: (tester) async {
          await open(tester);
          await _chooseMode(tester, 'Un valor');
          await tester.enterText(_singleValue, '999999999999');
          await pickFirstCatalogOption(tester, 'En qué medio lo tienes');
          expect(
            find.descendant(
              of: catalogCard('En qué medio lo tienes'),
              matching: find.textContaining(longCatalogName),
            ),
            findsOneWidget,
            reason: 'el nombre largo crece en la tarjeta, no se recorta',
          );
        },
      );
    });

    testWidgets('sin medios', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const _Host(),
        overrides: () => _Rig(methods: const []).overrides,
        prepare: open,
      );
    });

    testWidgets('con los avisos de validación visibles', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const _Host(),
        overrides: () => _Rig(methods: longMethods).overrides,
        prepare: (tester) async {
          await open(tester);
          await _enter(tester, 1, '0');
          await _tapSave(tester);
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
