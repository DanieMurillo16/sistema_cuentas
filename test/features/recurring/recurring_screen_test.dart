import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/models/dues_month.dart';
import 'package:sistema_cuentas/features/dues/widgets/due_tile.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';
import 'package:sistema_cuentas/features/recurring/recurring_detail_screen.dart';
import 'package:sistema_cuentas/features/recurring/recurring_form_screen.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_tile.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';
import 'package:sistema_cuentas/shared/widgets/app_pulse.dart';
import 'package:sistema_cuentas/shared/widgets/refresh_failed_banner.dart';

import '../../helpers/recurring_fixtures.dart';
import '../../support/fake_dues_repository.dart';
import '../../support/fake_recurring_repository.dart';
import '../../support/pump_recurring_app.dart';
import '../../support/recurring_overrides.dart';

Finder get _eventualErrorRetry => find.text('Intentar nuevamente');
Finder get _agreementsTab => find.text('Acuerdos');
Finder get _thisMonthTab => find.text('Este mes');

List<Due> _mixedDues() => [
  buildDue(id: 1, description: 'Arriendo de Oscar', contact: 'Oscar'),
  buildDue(
    id: 2,
    type: MovementType.expense,
    description: 'Netflix',
    category: 'Streaming',
    expectedCents: 4500000,
    dueDate: DateTime(2026, 10, 12),
    daysToDue: 8,
  ),
  buildDue(
    id: 3,
    description: 'Cuota de Marta',
    contact: 'Marta',
    expectedCents: 5000000,
    paidCents: 5000000,
    status: DueStatus.paid,
    dueDate: DateTime(2026, 10, 2),
    daysToDue: -2,
  ),
  buildDue(
    id: 4,
    type: MovementType.expense,
    description: 'Gimnasio',
    category: 'Salud',
    expectedCents: 8000000,
    status: DueStatus.cancelled,
    dueDate: DateTime(2026, 10, 3),
  ),
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  FakeDuesRepository? dues,
  FakeRecurringRepository? recurring,
  List<Due>? dueItems,
  List<RecurringPayment>? recurringItems,
  double width = 390,
  bool settle = true,
}) => pumpRecurringApp(
  tester,
  width: width,
  settle: settle,
  overrides: recurringOverrides(
    dues: dues,
    recurring: recurring,
    dueItems: dueItems ?? const [],
    recurringItems: recurringItems ?? const [],
  ),
);

void main() {
  group('«Este mes»: cuatro estados', () {
    testWidgets('cargando: cargador de página; el «+» y el selector siguen', (
      tester,
    ) async {
      final completer = Completer<DuesMonth>();
      await _pump(
        tester,
        settle: false,
        dues: FakeDuesRepository((_) => completer.future),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(DueTile), findsNothing);
      expect(find.byTooltip('Nuevo pago recurrente'), findsOneWidget);
      expect(_thisMonthTab, findsOneWidget);

      completer.complete(buildDuesMonth([buildDue()]));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(DueTile), findsOneWidget);
    });

    testWidgets('error: mensaje en español y «Intentar nuevamente» recarga', (
      tester,
    ) async {
      var fail = true;
      final dues = FakeDuesRepository((_) async {
        if (fail) throw const NetworkException('Sin conexión con el servidor.');
        return buildDuesMonth(_mixedDues());
      });
      await _pump(tester, dues: dues);

      expect(find.text('Sin conexión con el servidor.'), findsOneWidget);
      expect(_eventualErrorRetry, findsOneWidget);
      expect(find.byType(DueTile), findsNothing);

      fail = false;
      await tester.tap(_eventualErrorRetry);
      await tester.pumpAndSettle();

      expect(dues.calls, 2);
      expect(find.text('Sin conexión con el servidor.'), findsNothing);
      expect(find.byType(DueTile), findsNWidgets(4));
    });

    testWidgets('vacío: «Sin vencimientos este mes»', (tester) async {
      await _pump(tester);
      expect(find.text('Sin vencimientos este mes'), findsOneWidget);
      expect(find.byType(DueTile), findsNothing);
    });

    testWidgets(
      'datos: tarjetas Por cobrar / Por pagar y una fila por vencimiento',
      (tester) async {
        await _pump(tester, dueItems: _mixedDues());

        expect(find.text('Por cobrar'), findsOneWidget);
        expect(find.text('Por pagar'), findsOneWidget);
        expect(find.byType(DueTile), findsNWidgets(4));
        // El nombre primero: el contacto; bajo él, qué es y la fecha.
        expect(find.text('Oscar'), findsOneWidget);
        // Cada dato es un Text aparte (la fecha nunca se parte).
        expect(find.text('Arriendo de Oscar ·'), findsOneWidget);
        expect(find.text('7 oct.'), findsOneWidget);
        expect(find.text('Netflix'), findsOneWidget);
        expect(find.text('Streaming ·'), findsOneWidget);
        expect(find.text('12 oct.'), findsOneWidget);
        expect(find.text('Se paga en 3 días'), findsOneWidget);
        expect(find.text('Cobrado'), findsOneWidget);
        expect(find.text('Omitido'), findsOneWidget);
      },
    );
  });

  group('«Este mes»: filas', () {
    testWidgets('abiertos primero por fecha; cobrados y omitidos al final', (
      tester,
    ) async {
      await _pump(tester, dueItems: _mixedDues());
      double y(String text) => tester.getTopLeft(find.text(text)).dy;

      expect(y('Oscar'), lessThan(y('Netflix')));
      expect(y('Netflix'), lessThan(y('Marta')));
      expect(y('Marta'), lessThan(y('Gimnasio')));
    });

    testWidgets('«Cobrar» y «Pagar» solo en lo que se puede pagar (canPay)', (
      tester,
    ) async {
      await _pump(tester, dueItems: _mixedDues());

      expect(find.widgetWithText(FilledButton, 'Cobrar'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Pagar'), findsOneWidget);
      // Cobrado y omitido no tienen botón.
      final marta = find.ancestor(
        of: find.text('Marta'),
        matching: find.byType(DueTile),
      );
      final gym = find.ancestor(
        of: find.text('Gimnasio'),
        matching: find.byType(DueTile),
      );
      expect(
        find.descendant(of: marta, matching: find.byType(FilledButton)),
        findsNothing,
      );
      expect(
        find.descendant(of: gym, matching: find.byType(FilledButton)),
        findsNothing,
      );
    });

    testWidgets(
      'el botón dice a qué vencimiento corresponde (lectores de pantalla)',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(
          tester,
          dueItems: [buildDue(description: 'Arriendo de Oscar')],
        );

        expect(
          find.bySemanticsLabel(RegExp('Cobrar Arriendo de Oscar')),
          findsOneWidget,
        );
        handle.dispose();
      },
    );

    testWidgets(
      'un vencimiento ya vencido sigue teniendo botón y se ve en rojo',
      (tester) async {
        await _pump(tester, dueItems: [buildDue(overdue: true, daysToDue: -5)]);
        expect(find.text('Vencido hace 5 días'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Cobrar'), findsOneWidget);
      },
    );

    testWidgets('el ojo tapa las cifras de las tarjetas y de las filas', (
      tester,
    ) async {
      final container = await _pump(tester, dueItems: _mixedDues());
      expect(find.text(r'$ 180.000'), findsWidgets);
      expect(find.text(AnimatedNumberText.mask), findsNothing);

      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();

      expect(find.text(r'$ 180.000'), findsNothing);
      expect(find.text(r'$ 45.000'), findsNothing);
      // 2 tarjetas + 4 filas.
      expect(find.text(AnimatedNumberText.mask), findsNWidgets(6));

      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();
      expect(find.text(r'$ 180.000'), findsWidgets);
    });
  });

  group('«Este mes»: filtro Todos / Me pagan / Yo pago', () {
    testWidgets('Me pagan deja solo los ingresos y Yo pago solo los gastos', (
      tester,
    ) async {
      await _pump(tester, dueItems: _mixedDues());
      expect(find.byType(DueTile), findsNWidgets(4));

      await tester.tap(find.text('Me pagan'));
      await tester.pumpAndSettle();
      expect(find.byType(DueTile), findsNWidgets(2));
      expect(find.text('Oscar'), findsOneWidget);
      expect(find.text('Netflix'), findsNothing);

      await tester.tap(find.text('Yo pago'));
      await tester.pumpAndSettle();
      expect(find.byType(DueTile), findsNWidgets(2));
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Oscar'), findsNothing);

      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(find.byType(DueTile), findsNWidgets(4));
    });

    testWidgets('filtrar no vuelve a pedir al servidor', (tester) async {
      final dues = FakeDuesRepository(
        (_) async => buildDuesMonth(_mixedDues()),
      );
      await _pump(tester, dues: dues);
      await tester.tap(find.text('Yo pago'));
      await tester.pumpAndSettle();
      expect(dues.calls, 1);
    });

    testWidgets('un tipo sin vencimientos: «Nada de este tipo»', (
      tester,
    ) async {
      await _pump(tester, dueItems: [buildDue()]);
      await tester.tap(find.text('Yo pago'));
      await tester.pumpAndSettle();

      expect(find.text('Nada de este tipo'), findsOneWidget);
      expect(find.byType(DueTile), findsNothing);
    });
  });

  group('«Este mes»: recargas que no vacían la pantalla', () {
    testWidgets(
      'cambiar de mes con la respuesta pendiente: siguen las filas y NO sale «Nada de este tipo»',
      (tester) async {
        final pending = Completer<DuesMonth>();
        var first = true;
        final dues = FakeDuesRepository((_) {
          if (first) {
            first = false;
            return Future.value(buildDuesMonth(_mixedDues()));
          }
          return pending.future;
        });
        final container = await _pump(tester, dues: dues);
        expect(find.byType(DueTile), findsNWidgets(4));

        container.read(selectedMonthProvider.notifier).previous();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DueTile), findsNWidgets(4), reason: 'filas siguen');
        expect(find.text('Nada de este tipo'), findsNothing);
        expect(find.text('Sin vencimientos este mes'), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        pending.complete(
          buildDuesMonth([buildDue(id: 9, description: 'Septiembre')]),
        );
        await tester.pumpAndSettle();
        expect(find.byType(DueTile), findsOneWidget);
        expect(find.text('Septiembre'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'con un filtro activo, cambiar de mes tampoco muestra el vacío mientras carga',
      (tester) async {
        final pending = Completer<DuesMonth>();
        var first = true;
        final dues = FakeDuesRepository((_) {
          if (first) {
            first = false;
            return Future.value(buildDuesMonth(_mixedDues()));
          }
          return pending.future;
        });
        final container = await _pump(tester, dues: dues);
        await tester.tap(find.text('Yo pago'));
        await tester.pumpAndSettle();

        container.read(selectedMonthProvider.notifier).previous();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DueTile), findsNWidgets(2));
        expect(find.text('Nada de este tipo'), findsNothing);
        pending.complete(buildDuesMonth(const []));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'un cambio de mes que falla conserva las filas y avisa con «Reintentar»',
      (tester) async {
        var fail = false;
        final dues = FakeDuesRepository((_) async {
          if (fail) throw const NetworkException('Sin conexión.');
          return buildDuesMonth(_mixedDues());
        });
        final container = await _pump(tester, dues: dues);

        fail = true;
        container.read(selectedMonthProvider.notifier).previous();
        await tester.pumpAndSettle();

        expect(find.byType(DueTile), findsNWidgets(4));
        expect(find.byType(RefreshFailedBanner), findsOneWidget);
        expect(find.text('Sin conexión.'), findsOneWidget);

        fail = false;
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();
        expect(find.byType(RefreshFailedBanner), findsNothing);
        expect(find.byType(DueTile), findsNWidgets(4));
      },
    );
  });

  group('«Acuerdos»', () {
    final items = [
      buildRecurring(
        id: 1,
        description: 'Arriendo de Oscar',
        contact: 'Oscar',
        nextDueDate: DateTime(2026, 11, 7),
      ),
      buildRecurring(
        id: 2,
        type: MovementType.expense,
        description: 'Netflix',
        valueCents: 4500000,
        day: 12,
        everyMonths: 3,
        category: 'Streaming',
      ),
      buildRecurring(
        id: 3,
        description: 'Préstamo viejo',
        active: false,
        endDate: DateTime(2026, 9, 30),
      ),
    ];

    Future<ProviderContainer> pumpAgreements(
      WidgetTester tester, {
      FakeRecurringRepository? recurring,
      double width = 390,
      bool settle = true,
    }) async {
      final container = await _pump(
        tester,
        recurring:
            recurring ?? FakeRecurringRepository(onList: () async => items),
        width: width,
        settle: settle,
      );
      await tester.tap(_agreementsTab);
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
      }
      return container;
    }

    testWidgets('el toggle cambia de «Este mes» a «Acuerdos» y de vuelta', (
      tester,
    ) async {
      await _pump(tester, dueItems: [buildDue()], recurringItems: items);
      expect(find.byType(DueTile), findsOneWidget);
      expect(find.byType(RecurringTile), findsNothing);

      await tester.tap(_agreementsTab);
      await tester.pumpAndSettle();
      expect(find.byType(DueTile), findsNothing);
      expect(find.byType(RecurringTile), findsNWidgets(2));

      await tester.tap(_thisMonthTab);
      await tester.pumpAndSettle();
      expect(find.byType(DueTile), findsOneWidget);
      expect(find.byType(RecurringTile), findsNothing);
    });

    testWidgets('«Este mes» no pide los acuerdos hasta entrar a «Acuerdos»', (
      tester,
    ) async {
      final recurring = FakeRecurringRepository(onList: () async => items);
      await _pump(tester, recurring: recurring);
      expect(recurring.listCalls, 0);

      await tester.tap(_agreementsTab);
      await tester.pumpAndSettle();
      expect(recurring.listCalls, 1);
    });

    testWidgets('cargando: cargador de página', (tester) async {
      final completer = Completer<List<RecurringPayment>>();
      await pumpAgreements(
        tester,
        settle: false,
        recurring: FakeRecurringRepository(onList: () => completer.future),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(RecurringTile), findsNothing);

      completer.complete(items);
      await tester.pumpAndSettle();
      expect(find.byType(RecurringTile), findsNWidgets(2));
    });

    testWidgets('error: mensaje y «Intentar nuevamente» recarga', (
      tester,
    ) async {
      var fail = true;
      final recurring = FakeRecurringRepository(
        onList: () async {
          if (fail) {
            throw const NetworkException('Sin conexión con el servidor.');
          }
          return items;
        },
      );
      await pumpAgreements(tester, recurring: recurring);
      expect(find.text('Sin conexión con el servidor.'), findsOneWidget);

      fail = false;
      await tester.tap(_eventualErrorRetry);
      await tester.pumpAndSettle();

      expect(recurring.listCalls, 2);
      expect(find.byType(RecurringTile), findsNWidgets(2));
    });

    testWidgets('datos: nombre, de quién, día · cadencia, próximo y valor', (
      tester,
    ) async {
      await pumpAgreements(tester);

      // El nombre primero (el contacto) y, debajo, qué es.
      expect(find.text('Oscar'), findsOneWidget);
      expect(find.text('Arriendo de Oscar ·'), findsOneWidget);
      expect(find.text('Día 7 · Cada mes ·'), findsOneWidget);
      expect(find.text('próximo 7 nov.'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Streaming ·'), findsOneWidget);
      expect(find.text('Día 12 · Cada 3 meses'), findsOneWidget);
      expect(find.text(r'$ 180.000'), findsOneWidget);
      expect(find.text(r'$ 45.000'), findsOneWidget);
      // Por defecto se ven los activos.
      expect(find.text('Préstamo viejo'), findsNothing);
    });

    testWidgets('el filtro Finalizados muestra solo los cerrados', (
      tester,
    ) async {
      await pumpAgreements(tester);

      await tester.tap(find.text('Finalizados'));
      await tester.pumpAndSettle();

      expect(find.byType(RecurringTile), findsOneWidget);
      expect(find.text('Préstamo viejo'), findsOneWidget);
      expect(find.text('Netflix'), findsNothing);

      await tester.tap(find.text('Activos'));
      await tester.pumpAndSettle();
      expect(find.byType(RecurringTile), findsNWidgets(2));
    });

    testWidgets('el ojo tapa los valores de los acuerdos', (tester) async {
      final container = await pumpAgreements(tester);
      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();

      expect(find.text(r'$ 180.000'), findsNothing);
      expect(find.text(AnimatedNumberText.mask), findsNWidgets(2));
    });

    testWidgets(
      'vacío: invita a crear el primero y el botón abre el formulario',
      (tester) async {
        await pumpAgreements(
          tester,
          recurring: FakeRecurringRepository(onList: () async => const []),
        );

        expect(find.text('No tienes pagos recurrentes'), findsOneWidget);
        expect(find.text('Crear mi primer pago recurrente'), findsOneWidget);

        await tester.tap(find.text('Crear mi primer pago recurrente'));
        await tester.pumpAndSettle();

        expect(find.byType(RecurringFormScreen), findsOneWidget);
        expect(find.text('Nuevo pago recurrente'), findsOneWidget);
      },
    );

    testWidgets('sin finalizados: mensaje propio y sin botón de crear', (
      tester,
    ) async {
      await pumpAgreements(
        tester,
        recurring: FakeRecurringRepository(onList: () async => [items.first]),
      );
      await tester.tap(find.text('Finalizados'));
      await tester.pumpAndSettle();

      expect(find.text('Ningún pago finalizado'), findsOneWidget);
      expect(find.text('Crear mi primer pago recurrente'), findsNothing);
    });

    testWidgets('tocar un acuerdo abre su detalle con ese id', (tester) async {
      final recurring = FakeRecurringRepository(
        onList: () async => items,
        onDetail: (id) async => buildDetail(
          payment: buildRecurring(id: id, description: 'Arriendo de Oscar'),
        ),
      );
      await pumpAgreements(tester, recurring: recurring);

      await tester.tap(find.text('Oscar'));
      await tester.pumpAndSettle();

      expect(find.byType(RecurringDetailScreen), findsOneWidget);
      expect(recurring.detailIds, [1]);
    });
  });

  group('botón «+»', () {
    testWidgets('abre el formulario de un pago recurrente nuevo', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.byTooltip('Nuevo pago recurrente'));
      await tester.pumpAndSettle();
      expect(find.byType(RecurringFormScreen), findsOneWidget);
    });
  });

  group('botón «+»: se oculta solo cuando la invitación ya hace lo mismo', () {
    final fab = find.byTooltip('Nuevo pago recurrente');
    final cta = find.text('Crear mi primer pago recurrente');
    final active = buildRecurring(id: 1);
    final finished = buildRecurring(id: 3, active: false);

    // sección, acuerdos (con su estado) y filtro → ¿se ve el «+» y la invitación?
    final cases =
        <
          ({
            String name,
            List<RecurringPayment> items,
            bool agreements,
            bool finishedFilter,
            bool fabVisible,
          })
        >[
          (
            name: '«Este mes» sin acuerdos',
            items: const [],
            agreements: false,
            finishedFilter: false,
            fabVisible: true,
          ),
          (
            name: '«Acuerdos» con uno activo',
            items: [active],
            agreements: true,
            finishedFilter: false,
            fabVisible: true,
          ),
          (
            name: '«Acuerdos» sin ninguno: la invitación sustituye al «+»',
            items: const [],
            agreements: true,
            finishedFilter: false,
            fabVisible: false,
          ),
          (
            name: '«Acuerdos» con solo finalizados y filtro Activos (vacío)',
            items: [finished],
            agreements: true,
            finishedFilter: false,
            fabVisible: false,
          ),
          (
            name: '«Acuerdos», filtro Finalizados vacío (hay uno activo)',
            items: [active],
            agreements: true,
            finishedFilter: true,
            fabVisible: true,
          ),
        ];

    for (final c in cases) {
      testWidgets(c.name, (tester) async {
        await _pump(tester, recurringItems: c.items);
        if (c.agreements) {
          await tester.tap(_agreementsTab);
          await tester.pumpAndSettle();
        }
        if (c.finishedFilter) {
          await tester.tap(find.text('Finalizados'));
          await tester.pumpAndSettle();
          expect(find.text('Ningún pago finalizado'), findsOneWidget);
        }

        expect(fab, c.fabVisible ? findsOneWidget : findsNothing);
        final invited =
            c.agreements &&
            !c.finishedFilter &&
            c.items.where((p) => p.active).isEmpty;
        expect(cta, invited ? findsOneWidget : findsNothing);
      });
    }

    testWidgets('volver a «Este mes» devuelve el «+»', (tester) async {
      await _pump(tester);
      await tester.tap(_agreementsTab);
      await tester.pumpAndSettle();
      expect(fab, findsNothing);

      await tester.tap(_thisMonthTab);
      await tester.pumpAndSettle();
      expect(fab, findsOneWidget);
    });

    testWidgets(
      'la invitación va dentro de un AppPulse: late fuerte y sin parar',
      (tester) async {
        await _pump(tester);
        await tester.tap(_agreementsTab);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        final pulse = find.ancestor(
          of: find.widgetWithText(
            FilledButton,
            'Crear mi primer pago recurrente',
          ),
          matching: find.byType(AppPulse),
        );
        expect(pulse, findsOneWidget);
        expect(tester.widget<AppPulse>(pulse).scale, 1.1);
        expect(
          tester.widget<AppPulse>(pulse).beats,
          isNull,
          reason: 'late sin parar (en pruebas, un solo latido)',
        );

        final scale = find.descendant(
          of: pulse,
          matching: find.byType(ScaleTransition),
        );
        await tester.pump(const Duration(milliseconds: 450));
        expect(
          tester.widget<ScaleTransition>(scale).scale.value,
          greaterThan(1.05),
          reason: 'a mitad del latido se nota: crece de verdad',
        );

        // En pruebas el bucle sin fin se corta tras un latido (sin timers colgados).
        await tester.pumpAndSettle();
        expect(tester.widget<ScaleTransition>(scale).scale.value, 1);
      },
    );
  });
}
