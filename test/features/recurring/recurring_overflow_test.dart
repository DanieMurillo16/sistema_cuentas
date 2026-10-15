import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/models/dues_month.dart';
import 'package:sistema_cuentas/features/dues/widgets/pay_due_dialog.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_detail.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';
import 'package:sistema_cuentas/features/recurring/widgets/finish_recurring_dialog.dart';

import '../../helpers/movement_fixtures.dart';
import '../../helpers/recurring_fixtures.dart';
import '../../support/expect_recurring_no_overflow.dart';
import '../../support/fake_catalogs_repository.dart';
import '../../support/fake_dues_repository.dart';
import '../../support/fake_recurring_repository.dart';
import '../../support/pick_catalog_card.dart';
import '../../support/recurring_overrides.dart';

const _hugeCents = 99999999999900; // 12 dígitos, el máximo del formulario

/// 40 vencimientos con nombres, contactos y categorías largos, importes de 12
/// dígitos y todos los estados.
List<Due> _longDues() => [
  for (var i = 1; i <= 40; i++)
    buildDue(
      id: i,
      type: i.isEven ? MovementType.income : MovementType.expense,
      description: '$longRecurringName $i',
      contact: '$longContactName $i',
      category: longCatalogName,
      expectedCents: i % 3 == 0 ? _hugeCents : 1234500 * i,
      paidCents: i % 5 == 0 ? 1234500 : 0,
      status: switch (i % 4) {
        0 => DueStatus.paid,
        1 => DueStatus.pending,
        2 => DueStatus.partial,
        _ => DueStatus.cancelled,
      },
      overdue: i % 7 == 0,
      daysToDue: i % 7 == 0 ? -12 : i,
      dueDate: DateTime(2026, 10, 1 + i % 28),
    ),
];

List<RecurringPayment> _longAgreements() => [
  for (var i = 1; i <= 40; i++)
    buildRecurring(
      id: i,
      type: i.isEven ? MovementType.income : MovementType.expense,
      description: '$longRecurringName $i',
      contact: '$longContactName $i',
      category: longCatalogName,
      valueCents: i % 3 == 0 ? _hugeCents : 1234500 * i,
      day: 1 + i % 28,
      everyMonths: 1 + i % 12,
      active: i % 6 != 0,
      endDate: i % 6 == 0 ? DateTime(2026, 9, 30) : null,
      nextDueDate: DateTime(2026, 11, 7),
    ),
];

/// Lleva [finder] a la vista (aunque aún no esté construido en la lista) y lo
/// toca. Con 320 px, teclado y texto 1.5 casi nada cabe sin desplazarse.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 150);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder get _finishButton => find.descendant(
  of: find.bySubtype<OutlinedButton>(),
  matching: find.text('Finalizar'),
);

void main() {
  group('RecurringScreen sin desbordes (320/390/800/1300 × teclado × 1.5)', () {
    testWidgets('«Este mes» con 40 vencimientos de datos largos', (
      tester,
    ) async {
      expect(longRecurringName.length, greaterThan(60));
      expect(longContactName.length, greaterThan(40));
      await expectRecurringNoOverflow(
        tester,
        overrides: () => recurringOverrides(
          dueItems: _longDues(),
          recurringItems: _longAgreements(),
        ),
      );
    });

    testWidgets('«Acuerdos» con 40 acuerdos de datos largos', (tester) async {
      await expectRecurringNoOverflow(
        tester,
        overrides: () => recurringOverrides(
          dueItems: _longDues(),
          recurringItems: _longAgreements(),
        ),
        prepare: (tester) async {
          await tester.tap(find.text('Acuerdos'));
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('«Acuerdos» filtrando «Finalizados»', (tester) async {
      await expectRecurringNoOverflow(
        tester,
        overrides: () => recurringOverrides(recurringItems: _longAgreements()),
        prepare: (tester) async {
          await tester.tap(find.text('Acuerdos'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Finalizados'));
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('«Este mes» vacío', (tester) async {
      await expectRecurringNoOverflow(
        tester,
        overrides: () => recurringOverrides(),
      );
    });

    testWidgets('«Acuerdos» vacío', (tester) async {
      await expectRecurringNoOverflow(
        tester,
        overrides: () => recurringOverrides(),
        prepare: (tester) async {
          await tester.tap(find.text('Acuerdos'));
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('«Este mes» con error de red (mensaje largo)', (tester) async {
      await expectRecurringNoOverflow(
        tester,
        overrides: () => recurringOverrides(
          dues: FakeDuesRepository(
            (_) async =>
                throw NetworkException('Sin conexión con el servidor. ' * 6),
          ),
        ),
      );
    });

    testWidgets('«Acuerdos» con error de red (mensaje largo)', (tester) async {
      await expectRecurringNoOverflow(
        tester,
        overrides: () => recurringOverrides(
          recurring: FakeRecurringRepository(
            onList: () async =>
                throw NetworkException('Sin conexión con el servidor. ' * 6),
          ),
        ),
        prepare: (tester) async {
          await tester.tap(find.text('Acuerdos'));
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('«Este mes» cargando (cargador de página)', (tester) async {
      final never = Completer<DuesMonth>();
      await expectRecurringNoOverflow(
        tester,
        overrides: () =>
            recurringOverrides(dues: FakeDuesRepository((_) => never.future)),
        // Con el cargador girando no hay reposo.
        settle: false,
      );
    });
  });

  group('RecurringDetailScreen sin desbordes', () {
    RecurringDetail longDetail({bool active = true}) => buildDetail(
      payment: buildRecurring(
        description: longRecurringName,
        contact: longContactName,
        category: longCatalogName,
        valueCents: _hugeCents,
        capitalCents: _hugeCents,
        totalPaidCents: _hugeCents,
        note: longDescription,
        active: active,
        endDate: active ? null : DateTime(2026, 9, 30),
        closingNote: active ? null : longDescription,
      ),
      history: longHistory(40),
    );

    for (final active in [true, false]) {
      testWidgets(
        '${active ? 'activo' : 'finalizado'} con 40 meses de historial y datos largos',
        (tester) async {
          await expectRecurringNoOverflow(
            tester,
            initialLocation: AppRoutes.recurringDetailFor(10),
            overrides: () => recurringOverrides(
              recurring: FakeRecurringRepository(
                onList: () async => [longDetail(active: active).payment],
                onDetail: (_) async => longDetail(active: active),
              ),
            ),
          );
        },
      );
    }

    testWidgets('con error de red (mensaje largo)', (tester) async {
      await expectRecurringNoOverflow(
        tester,
        initialLocation: AppRoutes.recurringDetailFor(10),
        overrides: () => recurringOverrides(
          recurring: FakeRecurringRepository(
            onDetail: (_) async =>
                throw NetworkException('Sin conexión con el servidor. ' * 6),
          ),
        ),
      );
    });
  });

  group('RecurringFormScreen sin desbordes', () {
    testWidgets('formulario nuevo', (tester) async {
      await expectRecurringNoOverflow(
        tester,
        initialLocation: AppRoutes.recurringNew,
        overrides: () => recurringOverrides(),
      );
    });

    testWidgets('con categorías y contactos de nombre largo', (tester) async {
      await expectRecurringNoOverflow(
        tester,
        initialLocation: AppRoutes.recurringNew,
        overrides: () => recurringOverrides(
          catalogs: FakeCatalogsRepository(
            onCategories: () async => [
              buildCategory(
                id: 9,
                type: MovementType.income,
                name: longCatalogName,
              ),
              buildCategory(id: 3, name: longCatalogName),
            ],
            onMethods: () async => defaultMethods(),
            onContacts: () async => [buildContact(name: longContactName)],
          ),
        ),
        prepare: (tester) async {
          // Elige categoría y contacto largos y otra cadencia: lo elegido
          // también debe caber (las tarjetas crecen, no se recortan).
          await pickCatalogOption(tester, 'Categoría', longCatalogName);
          await pickCatalogOption(
            tester,
            'Contacto (opcional)',
            longContactName,
          );
          await pickCatalogOption(tester, 'Se repite', 'Cada 3 meses');
        },
      );
    });

    testWidgets('con los catálogos en error (mensaje largo)', (tester) async {
      await expectRecurringNoOverflow(
        tester,
        initialLocation: AppRoutes.recurringNew,
        overrides: () => recurringOverrides(
          catalogs: FakeCatalogsRepository(
            onCategories: () async =>
                throw NetworkException('Sin conexión con el servidor. ' * 6),
            onMethods: () async => defaultMethods(),
            onContacts: () async => const [],
          ),
        ),
      );
    });
  });

  group('diálogos abiertos con showDialog sin desbordes', () {
    testWidgets('PayDueDialog (cobro, datos largos)', (tester) async {
      await expectRecurringNoOverflow(
        tester,
        overrides: () => recurringOverrides(
          dueItems: [
            buildDue(
              description: longRecurringName,
              contact: longContactName,
              category: longCatalogName,
              expectedCents: _hugeCents,
            ),
          ],
        ),
        prepare: (tester) async {
          // Con nombres largos la tarjeta es alta: el botón puede quedar bajo
          // el borde del listado y hay que desplazarlo a la vista.
          await tester.ensureVisible(find.byType(FilledButton).last);
          await tester.pumpAndSettle();
          await tester.tap(find.byType(FilledButton).last);
          await tester.pumpAndSettle();
          expect(find.byType(PayDueDialog), findsOneWidget);
        },
      );
    });

    testWidgets('PayDueDialog (pago de un gasto, con el medio elegido)', (
      tester,
    ) async {
      await expectRecurringNoOverflow(
        tester,
        overrides: () => recurringOverrides(
          dueItems: [
            buildDue(
              type: MovementType.expense,
              description: longRecurringName,
              expectedCents: _hugeCents,
            ),
          ],
          catalogs: FakeCatalogsRepository(
            onCategories: () async => defaultCategories(),
            onMethods: () async => [buildMethod(id: 2, name: longCatalogName)],
            onContacts: () async => const [],
          ),
        ),
        prepare: (tester) async {
          // Con nombres largos la tarjeta es alta: el botón puede quedar bajo
          // el borde del listado y hay que desplazarlo a la vista.
          await tester.ensureVisible(find.byType(FilledButton).last);
          await tester.pumpAndSettle();
          await tester.tap(find.byType(FilledButton).last);
          await tester.pumpAndSettle();
          await pickCatalogOption(tester, 'Medio de pago', longCatalogName);
        },
      );
    });

    testWidgets('FinishRecurringDialog (datos largos)', (tester) async {
      await expectRecurringNoOverflow(
        tester,
        initialLocation: AppRoutes.recurringDetailFor(10),
        overrides: () => recurringOverrides(
          recurring: FakeRecurringRepository(
            onList: () async => [buildRecurring()],
            onDetail: (_) async => buildDetail(
              payment: buildRecurring(
                description: longRecurringName,
                contact: longContactName,
                valueCents: _hugeCents,
              ),
            ),
          ),
        ),
        prepare: (tester) async {
          await _tapVisible(tester, _finishButton);
          expect(find.byType(FinishRecurringDialog), findsOneWidget);
        },
      );
    });

    testWidgets('FinishRecurringDialog con capital y su medio de pago', (
      tester,
    ) async {
      await expectRecurringNoOverflow(
        tester,
        initialLocation: AppRoutes.recurringDetailFor(10),
        overrides: () => recurringOverrides(
          recurring: FakeRecurringRepository(
            onList: () async => [buildRecurring()],
            onDetail: (_) async => buildDetail(
              payment: buildRecurring(description: longRecurringName),
            ),
          ),
          catalogs: FakeCatalogsRepository(
            onCategories: () async => defaultCategories(),
            onMethods: () async => [buildMethod(id: 2, name: longCatalogName)],
            onContacts: () async => const [],
          ),
        ),
        prepare: (tester) async {
          await _tapVisible(tester, _finishButton);
          // El capital hace aparecer «Medio de pago del capital».
          final dialog = find.byType(FinishRecurringDialog);
          await tester.enterText(
            find.descendant(
              of: dialog,
              matching: find.widgetWithText(
                TextFormField,
                'Capital (opcional)',
              ),
            ),
            '999999999999',
          );
          await tester.pumpAndSettle();
          await pickCatalogOption(
            tester,
            'Medio de pago del capital',
            longCatalogName,
          );
        },
      );
    });
  });
}
