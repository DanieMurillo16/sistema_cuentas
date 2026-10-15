import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/category_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method_draft.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/contacts_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/payment_methods_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/save_catalog_providers.dart';

import '../../helpers/movement_fixtures.dart';
import '../../helpers/recurring_fixtures.dart';
import '../../support/container_helpers.dart';
import '../../support/fake_catalogs_repository.dart';
import '../../support/recurring_harness.dart';

const _networkError = NetworkException('Sin conexión con el servidor.');

/// Cuántas veces se pidió cada vista que muestra nombres de catálogo:
/// `(movimientos, vencimientos, acuerdos, resumen)`.
(int, int, int, int) _dependents(RecurringHarness h) => (
  h.movements.listCalls,
  h.dues.calls,
  h.recurring.listCalls,
  h.summary.calls,
);

void main() {
  group('saveCategoryProvider', () {
    const draftNew = CategoryDraft(
      type: MovementType.income,
      name: 'Salario',
      isCapital: false,
      active: true,
    );

    RecurringHarness harness({
      Future<Category> Function(CategoryDraft draft)? save,
      List<Category>? initial,
    }) {
      final h = RecurringHarness(
        catalogs: FakeCatalogsRepository(
          onCategories: () async =>
              initial ?? [buildCategory(id: 3, name: 'Alimentación')],
          onSaveCategory:
              save ??
              (d) async => buildCategory(
                id: d.id ?? 20,
                type: d.type,
                name: d.name,
                active: d.active,
              ),
        ),
      );
      keepAlive(h.container, [saveCategoryProvider, categoriesProvider]);
      return h;
    }

    test('estado inicial: en reposo', () {
      final h = harness();
      expect(h.container.read(saveCategoryProvider).isLoading, isFalse);
      expect(h.container.read(saveCategoryProvider).hasError, isFalse);
    });

    test('crear: manda el borrador y hace upsert sin recargar nada', () async {
      final h = harness();
      await h.openViews();
      await h.container.read(categoriesProvider.future);
      final before = _dependents(h);

      await h.container.read(saveCategoryProvider.notifier).save(draftNew);

      expect(h.container.read(saveCategoryProvider).hasError, isFalse);
      expect((h.catalogs).categoriesCalls, 1, reason: 'upsert, no recarga');
      expect(
        h.container.read(categoriesProvider).requireValue.map((c) => c.name),
        ['Salario', 'Alimentación'],
        reason: 'ingresos primero',
      );
      expect(_dependents(h), before, reason: 'crear no deja nada viejo');
    });

    test('crear: otra vista (selector de categorías) ve la nueva', () async {
      final h = harness();
      keepAlive(h.container, [categoriesForTypeProvider(MovementType.income)]);
      await h.container.read(categoriesProvider.future);
      expect(
        h.container
            .read(categoriesForTypeProvider(MovementType.income))
            .requireValue,
        isEmpty,
      );

      await h.container.read(saveCategoryProvider.notifier).save(draftNew);

      expect(
        h.container
            .read(categoriesForTypeProvider(MovementType.income))
            .requireValue
            .map((c) => c.name),
        ['Salario'],
      );
    });

    test('editar: reemplaza, los selectores sacan la inactiva y se piden de '
        'nuevo movimientos, vencimientos, acuerdos y resumen', () async {
      final h = harness();
      keepAlive(h.container, [categoriesForTypeProvider(MovementType.expense)]);
      await h.openViews();
      await h.container.read(categoriesProvider.future);
      expect(
        h.container
            .read(categoriesForTypeProvider(MovementType.expense))
            .requireValue,
        hasLength(1),
      );

      await h.container
          .read(saveCategoryProvider.notifier)
          .save(
            const CategoryDraft(
              id: 3,
              type: MovementType.expense,
              name: 'Alimentación',
              isCapital: false,
              active: false,
            ),
          );
      await h.settleViews();

      final all = h.container.read(categoriesProvider).requireValue;
      expect(all, hasLength(1), reason: 'reemplaza, no duplica');
      expect(all.single.active, isFalse);
      expect(
        h.container
            .read(categoriesForTypeProvider(MovementType.expense))
            .requireValue,
        isEmpty,
        reason: 'el selector solo ofrece las activas',
      );
      expect(_dependents(h), (2, 2, 2, 2));
      expect(h.catalogs.categoriesCalls, 1);
    });

    test('error: queda en error con el mensaje, no toca la lista ni '
        'los dependientes', () async {
      final h = harness(save: (_) async => throw _networkError);
      await h.openViews();
      await h.container.read(categoriesProvider.future);
      final before = _dependents(h);

      await h.container.read(saveCategoryProvider.notifier).save(draftNew);

      final state = h.container.read(saveCategoryProvider);
      expect(state.hasError, isTrue);
      expect(userErrorMessage(state.error), 'Sin conexión con el servidor.');
      expect(
        h.container.read(categoriesProvider).requireValue.map((c) => c.id),
        [3],
      );
      expect(_dependents(h), before);
    });

    test(
      'anti doble envío: con una petición en curso ignora la segunda',
      () async {
        final completer = Completer<Category>();
        var calls = 0;
        final h = harness(
          save: (_) {
            calls++;
            return completer.future;
          },
        );
        await h.container.read(categoriesProvider.future);
        final notifier = h.container.read(saveCategoryProvider.notifier);

        final first = notifier.save(draftNew);
        await Future<void>.delayed(Duration.zero);
        expect(h.container.read(saveCategoryProvider).isLoading, isTrue);
        await notifier.save(draftNew); // ignorada
        expect(calls, 1);

        completer.complete(buildCategory(id: 20, name: 'Salario'));
        await first;
        expect(calls, 1);
        expect(h.container.read(saveCategoryProvider).isLoading, isFalse);
      },
    );

    test(
      'keepAlive: nadie la observa y aun así termina y deja el upsert',
      () async {
        final completer = Completer<Category>();
        final h = RecurringHarness(
          catalogs: FakeCatalogsRepository(
            onCategories: () async => [buildCategory(id: 3)],
            onSaveCategory: (_) => completer.future,
          ),
        );
        // Solo la lista compartida está viva; el notifier de escritura NO.
        keepAlive(h.container, [categoriesProvider]);
        await h.container.read(categoriesProvider.future);

        final done = h.container
            .read(saveCategoryProvider.notifier)
            .save(draftNew);
        // Pasan varios cuadros sin oyentes: un autoDispose sin keepAlive se
        // habría soltado y la escritura fallaría con «Ref disposed».
        for (var i = 0; i < 3; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        completer.complete(buildCategory(id: 20, name: 'Salario'));
        await done;

        expect(
          h.container.read(categoriesProvider).requireValue.map((c) => c.id),
          containsAll([3, 20]),
        );
      },
    );
  });

  group('savePaymentMethodProvider', () {
    const draftNew = PaymentMethodDraft(name: 'Daviplata', active: true);

    RecurringHarness harness({
      Future<PaymentMethod> Function(PaymentMethodDraft draft)? save,
    }) {
      final h = RecurringHarness(
        catalogs: FakeCatalogsRepository(
          onMethods: () async => [buildMethod(id: 2, name: 'Nequi')],
          onSaveMethod:
              save ??
              (d) async =>
                  buildMethod(id: d.id ?? 30, name: d.name, active: d.active),
        ),
      );
      keepAlive(h.container, [
        savePaymentMethodProvider,
        paymentMethodsProvider,
        activePaymentMethodsProvider,
      ]);
      return h;
    }

    test(
      'crear: upsert ordenado por nombre; el selector la ve; no recarga',
      () async {
        final h = harness();
        await h.openViews();
        await h.container.read(paymentMethodsProvider.future);
        final before = _dependents(h);

        await h.container
            .read(savePaymentMethodProvider.notifier)
            .save(draftNew);

        expect(
          h.container
              .read(activePaymentMethodsProvider)
              .requireValue
              .map((m) => m.name),
          ['Daviplata', 'Nequi'],
        );
        expect(h.catalogs.methodsCalls, 1);
        expect(_dependents(h), before);
      },
    );

    test('editar a inactivo: sale del selector pero sigue en la lista de '
        'Ajustes, y se piden de nuevo las vistas con su nombre', () async {
      final h = harness();
      await h.openViews();
      await h.container.read(paymentMethodsProvider.future);

      await h.container
          .read(savePaymentMethodProvider.notifier)
          .save(const PaymentMethodDraft(id: 2, name: 'Nequi', active: false));
      await h.settleViews();

      expect(
        h.container.read(activePaymentMethodsProvider).requireValue,
        isEmpty,
      );
      expect(
        h.container.read(paymentMethodsProvider).requireValue.single.active,
        isFalse,
      );
      expect(_dependents(h), (2, 2, 2, 2));
    });

    test('error: mensaje del servidor y la lista queda igual', () async {
      final h = harness(
        save: (_) async => throw const ApiException(
          'Ya existe un medio con ese nombre.',
          code: 'DUPLICADO',
          statusCode: 409,
        ),
      );
      await h.container.read(paymentMethodsProvider.future);

      await h.container.read(savePaymentMethodProvider.notifier).save(draftNew);

      final state = h.container.read(savePaymentMethodProvider);
      expect(
        userErrorMessage(state.error),
        'Ya existe un medio con ese nombre.',
      );
      expect(
        h.container.read(paymentMethodsProvider).requireValue.map((m) => m.id),
        [2],
      );
    });

    test('anti doble envío y keepAlive', () async {
      final completer = Completer<PaymentMethod>();
      var calls = 0;
      final h = harness(
        save: (_) {
          calls++;
          return completer.future;
        },
      );
      await h.container.read(paymentMethodsProvider.future);
      final notifier = h.container.read(savePaymentMethodProvider.notifier);

      final first = notifier.save(draftNew);
      await Future<void>.delayed(Duration.zero);
      await notifier.save(draftNew);
      expect(calls, 1);

      completer.complete(buildMethod(id: 30, name: 'Daviplata'));
      await first;
      expect(
        h.container.read(paymentMethodsProvider).requireValue.map((m) => m.id),
        containsAll([2, 30]),
      );
    });
  });

  group('saveContactProvider', () {
    const draftNew = ContactDraft(name: 'Marta', active: true);

    RecurringHarness harness({
      Future<Contact> Function(ContactDraft draft)? save,
    }) {
      final h = RecurringHarness(
        catalogs: FakeCatalogsRepository(
          onCategories: () async => defaultCategories(),
          onMethods: () async => defaultMethods(),
          onContacts: () async => [buildContact(id: 4, name: 'Oscar')],
          onSaveContact:
              save ??
              (d) async => buildContact(
                id: d.id ?? 40,
                name: d.name,
                active: d.active,
                phone: d.phone,
              ),
        ),
      );
      keepAlive(h.container, [
        saveContactProvider,
        contactsProvider,
        activeContactsProvider,
      ]);
      return h;
    }

    test('crear: upsert ordenado, el selector lo ve y no recarga', () async {
      final h = harness();
      await h.openViews();
      await h.container.read(contactsProvider.future);
      final before = _dependents(h);

      await h.container.read(saveContactProvider.notifier).save(draftNew);

      expect(
        h.container
            .read(activeContactsProvider)
            .requireValue
            .map((c) => c.name),
        ['Marta', 'Oscar'],
      );
      expect(h.catalogs.contactsCalls, 1);
      expect(_dependents(h), before);
    });

    test(
      'editar: reemplaza (con teléfono) y vuelve a pedir las vistas',
      () async {
        final h = harness();
        await h.openViews();
        await h.container.read(contactsProvider.future);

        await h.container
            .read(saveContactProvider.notifier)
            .save(
              const ContactDraft(
                id: 4,
                name: 'Oscar',
                active: true,
                phone: '3001234567',
              ),
            );
        await h.settleViews();

        final contacts = h.container.read(contactsProvider).requireValue;
        expect(contacts, hasLength(1));
        expect(contacts.single.phone, '3001234567');
        expect(_dependents(h), (2, 2, 2, 2));
      },
    );

    test('error y anti doble envío', () async {
      final failing = harness(save: (_) async => throw _networkError);
      await failing.container.read(contactsProvider.future);
      await failing.container.read(saveContactProvider.notifier).save(draftNew);
      expect(failing.container.read(saveContactProvider).hasError, isTrue);
      expect(
        failing.container.read(contactsProvider).requireValue.map((c) => c.id),
        [4],
      );

      final completer = Completer<Contact>();
      var calls = 0;
      final h = harness(
        save: (_) {
          calls++;
          return completer.future;
        },
      );
      await h.container.read(contactsProvider.future);
      final notifier = h.container.read(saveContactProvider.notifier);
      final first = notifier.save(draftNew);
      await Future<void>.delayed(Duration.zero);
      await notifier.save(draftNew);
      expect(calls, 1);
      completer.complete(buildContact(id: 40, name: 'Marta'));
      await first;
    });
  });

  group('upsert de las listas compartidas', () {
    test('categorías: ingresos primero y, dentro de cada tipo, por nombre', () async {
      final container = makeContainer(
        overrides: [
          catalogsRepositoryProvider.overrideWithValue(
            FakeCatalogsRepository(
              onCategories: () async => [
                buildCategory(id: 1, name: 'Zapatos'),
                buildCategory(id: 2, type: MovementType.income, name: 'Venta'),
              ],
            ),
          ),
        ],
      );
      keepAlive(container, [categoriesProvider]);
      await container.read(categoriesProvider.future);

      container
          .read(categoriesProvider.notifier)
          .upsert(buildCategory(id: 3, name: 'alimentación'));
      container
          .read(categoriesProvider.notifier)
          .upsert(
            buildCategory(id: 4, type: MovementType.income, name: 'Arriendo'),
          );

      expect(
        container.read(categoriesProvider).requireValue.map((c) => c.id),
        [4, 2, 3, 1],
        reason:
            'ingresos (Arriendo, Venta) y luego gastos (alimentación, Zapatos)',
      );
    });

    test('contactos: ordenados por nombre sin importar mayúsculas', () async {
      final container = makeContainer(
        overrides: [
          catalogsRepositoryProvider.overrideWithValue(
            FakeCatalogsRepository(
              onContacts: () async => [buildContact(id: 1, name: 'Oscar')],
            ),
          ),
        ],
      );
      keepAlive(container, [contactsProvider]);
      await container.read(contactsProvider.future);

      container
          .read(contactsProvider.notifier)
          .upsert(buildContact(id: 2, name: 'ana'));
      container
          .read(contactsProvider.notifier)
          .upsert(buildContact(id: 3, name: 'Beto'));

      expect(container.read(contactsProvider).requireValue.map((c) => c.name), [
        'ana',
        'Beto',
        'Oscar',
      ]);
    });

    test('upsert antes de que cargue la lista no hace nada (ni revienta)', () {
      final container = makeContainer(
        overrides: [
          catalogsRepositoryProvider.overrideWithValue(
            FakeCatalogsRepository(
              onContacts: () => Completer<List<Contact>>().future,
            ),
          ),
        ],
      );
      keepAlive(container, [contactsProvider]);
      container.read(contactsProvider.notifier).upsert(buildContact());
      expect(container.read(contactsProvider).isLoading, isTrue);
    });
  });
}
