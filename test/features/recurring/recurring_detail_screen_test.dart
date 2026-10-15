import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/recurring/widgets/deleted_category_notice.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_detail.dart';
import 'package:sistema_cuentas/features/recurring/recurring_screen.dart';
import 'package:sistema_cuentas/features/recurring/widgets/due_history_tile.dart';
import 'package:sistema_cuentas/features/recurring/widgets/finish_recurring_dialog.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';
import 'package:sistema_cuentas/shared/widgets/refresh_failed_banner.dart';

import '../../helpers/recurring_fixtures.dart';
import '../../helpers/movement_fixtures.dart';
import '../../support/fake_catalogs_repository.dart';
import '../../support/fake_recurring_repository.dart';
import '../../support/pump_recurring_app.dart';
import '../../support/recurring_overrides.dart';

import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';

Finder get _finishButton => find.descendant(
  of: find.bySubtype<OutlinedButton>(),
  matching: find.text('Finalizar'),
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeRecurringRepository recurring, {
  int id = 10,
  double width = 390,
  bool settle = true,
}) => pumpRecurringApp(
  tester,
  width: width,
  settle: settle,
  initialLocation: AppRoutes.recurringDetailFor(id),
  overrides: recurringOverrides(recurring: recurring),
);

FakeRecurringRepository _repo({
  RecurringDetail? detail,
  Future<RecurringDetail> Function(int id)? onDetail,
}) => FakeRecurringRepository(
  onList: () async => [buildRecurring()],
  onDetail: onDetail ?? (_) async => detail ?? buildDetail(),
);

void main() {
  group('categoría eliminada', () {
    Future<void> pumpWith(WidgetTester tester, {required bool deleted}) =>
        pumpRecurringApp(
          tester,
          initialLocation: AppRoutes.recurringDetailFor(10),
          overrides: recurringOverrides(
            recurring: _repo(),
            catalogs: FakeCatalogsRepository(
              onCategories: () async => [
                buildCategory(
                  id: 9,
                  type: MovementType.income,
                  name: 'Arriendos',
                  active: !deleted,
                  deleted: deleted,
                ),
              ],
              onMethods: () async => defaultMethods(),
              onContacts: () async => [buildContact()],
            ),
          ),
        );

    testWidgets('avisa que ya no existe, con su nombre, y la ficha sigue', (
      tester,
    ) async {
      await pumpWith(tester, deleted: true);

      expect(find.byType(DeletedCategoryNotice), findsOneWidget);
      expect(
        find.text(
          'La categoría «Arriendos» ya no existe. Los pagos de este acuerdo '
          'siguen usándola.',
        ),
        findsOneWidget,
      );
      expect(_finishButton, findsOneWidget);
    });

    testWidgets('con la categoría vigente no hay aviso', (tester) async {
      await pumpWith(tester, deleted: false);

      expect(find.textContaining('ya no existe'), findsNothing);
    });
  });

  group('cuatro estados', () {
    testWidgets('cargando: cargador de página con la barra de título', (
      tester,
    ) async {
      final completer = Completer<RecurringDetail>();
      await _pump(
        tester,
        _repo(onDetail: (_) => completer.future),
        settle: false,
      );

      expect(find.text('Pago recurrente'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_finishButton, findsNothing);

      completer.complete(buildDetail());
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_finishButton, findsOneWidget);
    });

    testWidgets('error: mensaje en español y «Intentar nuevamente» recarga', (
      tester,
    ) async {
      var fail = true;
      final recurring = _repo(
        onDetail: (_) async {
          if (fail) {
            throw const NetworkException('Sin conexión con el servidor.');
          }
          return buildDetail();
        },
      );
      await _pump(tester, recurring);

      expect(find.text('Sin conexión con el servidor.'), findsOneWidget);
      expect(_finishButton, findsNothing);

      fail = false;
      await tester.tap(find.text('Intentar nuevamente'));
      await tester.pumpAndSettle();

      expect(recurring.detailCalls, 2);
      expect(find.text('Sin conexión con el servidor.'), findsNothing);
      expect(_finishButton, findsOneWidget);
    });

    testWidgets('404: muestra el mensaje del servidor', (tester) async {
      await _pump(
        tester,
        _repo(
          onDetail: (_) async => throw const ApiException(
            'El pago recurrente no existe.',
            statusCode: 404,
          ),
        ),
      );
      expect(find.text('El pago recurrente no existe.'), findsOneWidget);
    });

    testWidgets(
      'sin historial: la ficha y el encabezado «Historial», sin filas',
      (tester) async {
        await _pump(tester, _repo(detail: buildDetail(history: const [])));

        expect(find.text('Historial'), findsOneWidget);
        expect(find.byType(DueHistoryTile), findsNothing);
        expect(find.text('Arriendo de Oscar'), findsOneWidget);
      },
    );

    testWidgets('datos: ficha completa e historial', (tester) async {
      await _pump(
        tester,
        _repo(
          detail: buildDetail(
            payment: buildRecurring(
              contact: 'Oscar',
              capitalCents: 500000000,
              note: 'Casa 2',
              totalPaidCents: 54000000,
            ),
            history: [
              buildHistoryItem(id: 3, period: DateTime(2026, 10), daysToDue: 3),
              buildHistoryItem(
                id: 2,
                period: DateTime(2026, 9),
                paidCents: 18000000,
                status: DueStatus.paid,
                daysToDue: -36,
              ),
              buildHistoryItem(
                id: 1,
                period: DateTime(2026, 8),
                paidCents: 5000000,
                status: DueStatus.partial,
                overdue: true,
                daysToDue: -66,
              ),
            ],
          ),
        ),
      );

      // El título es el contacto (nombre primero) y también va en «Me paga».
      expect(find.text('Oscar'), findsNWidgets(2));
      expect(find.text('Me paga'), findsOneWidget);
      expect(find.text('Día 7 · Cada mes'), findsOneWidget);
      expect(find.text('Arriendos'), findsOneWidget);
      expect(find.text('Total cobrado'), findsOneWidget);
      expect(find.text(r'$ 540.000'), findsOneWidget);
      expect(find.text(r'$ 5.000.000'), findsOneWidget);
      expect(find.text('Casa 2'), findsOneWidget);

      expect(find.byType(DueHistoryTile), findsNWidgets(3));
      expect(find.text('Octubre 2026'), findsOneWidget);
      expect(find.text('Septiembre 2026'), findsOneWidget);
      expect(find.text(r'$ 180.000 de $ 180.000'), findsOneWidget);
      expect(find.text('Cobrado'), findsOneWidget);
      expect(find.text('Parcial · Vencido hace 66 días'), findsOneWidget);
    });

    testWidgets('gasto: «Le pago a» y «Total pagado»', (tester) async {
      await _pump(
        tester,
        _repo(
          detail: buildDetail(
            payment: buildRecurring(
              type: MovementType.expense,
              contact: 'Claro',
              totalPaidCents: 100,
            ),
          ),
        ),
      );
      expect(find.text('Le pago a'), findsOneWidget);
      expect(find.text('Total pagado'), findsOneWidget);
    });

    testWidgets('el ojo tapa los importes de la ficha y del historial', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        _repo(
          detail: buildDetail(
            payment: buildRecurring(totalPaidCents: 54000000),
            history: [buildHistoryItem(paidCents: 18000000)],
          ),
        ),
      );
      expect(find.text(r'$ 180.000'), findsOneWidget);

      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();

      expect(find.text(r'$ 180.000'), findsNothing);
      expect(find.text(r'$ 540.000'), findsNothing);
      expect(find.textContaining(r'$ '), findsNothing);
      expect(find.text(AnimatedNumberText.mask), findsWidgets);
    });
  });

  group('«Finalizar»', () {
    testWidgets('solo aparece si el acuerdo está activo', (tester) async {
      await _pump(tester, _repo());
      expect(_finishButton, findsOneWidget);
    });

    testWidgets('finalizado: sin botón y con fecha y motivo de cierre', (
      tester,
    ) async {
      await _pump(
        tester,
        _repo(
          detail: buildDetail(
            payment: buildRecurring(
              active: false,
              endDate: DateTime(2026, 9, 30),
              closingNote: 'Se mudó de ciudad',
            ),
          ),
        ),
      );

      expect(_finishButton, findsNothing);
      expect(find.text('Finalizado'), findsOneWidget);
      expect(find.text('30/09/2026'), findsOneWidget);
      expect(find.text('Motivo'), findsOneWidget);
      expect(find.text('Se mudó de ciudad'), findsOneWidget);
    });

    testWidgets('abre el diálogo de cierre', (tester) async {
      await _pump(tester, _repo());
      await tester.tap(_finishButton);
      await tester.pumpAndSettle();
      expect(find.byType(FinishRecurringDialog), findsOneWidget);
    });
  });

  group('recargas', () {
    testWidgets(
      'un refresco que falla conserva la ficha y avisa con «Reintentar»',
      (tester) async {
        var fail = false;
        final recurring = _repo(
          onDetail: (_) async {
            if (fail) throw const NetworkException('Sin conexión.');
            return buildDetail();
          },
        );
        final container = await _pump(tester, recurring);

        fail = true;
        container.invalidate(recurringDetailProvider(10));
        await tester.pumpAndSettle();

        expect(find.text('Arriendo de Oscar'), findsOneWidget);
        expect(find.byType(RefreshFailedBanner), findsOneWidget);
        expect(find.text('Sin conexión.'), findsOneWidget);

        fail = false;
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();
        expect(find.byType(RefreshFailedBanner), findsNothing);
        expect(find.text('Arriendo de Oscar'), findsOneWidget);
      },
    );

    testWidgets(
      'al recargar con datos no se vacía (barra fina, sin cargador)',
      (tester) async {
        final pending = Completer<RecurringDetail>();
        var first = true;
        final recurring = _repo(
          onDetail: (_) {
            if (first) {
              first = false;
              return Future.value(buildDetail());
            }
            return pending.future;
          },
        );
        final container = await _pump(tester, recurring);

        container.invalidate(recurringDetailProvider(10));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Arriendo de Oscar'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        pending.complete(buildDetail());
        await tester.pumpAndSettle();
      },
    );
  });

  group('navegación', () {
    testWidgets(
      '«Atrás» sin historial (recarga en esta dirección) va a Pagos recurrentes',
      (tester) async {
        await _pump(tester, _repo());

        await tester.tap(find.byTooltip('Atrás'));
        await tester.pumpAndSettle();

        expect(find.byType(RecurringScreen), findsOneWidget);
      },
    );
  });
}
