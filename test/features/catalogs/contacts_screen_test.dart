import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/catalogs/contacts_screen.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact_draft.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/contact_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/manage_tile.dart';

import '../../helpers/movement_fixtures.dart';
import '../../helpers/recurring_fixtures.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/fake_catalogs_repository.dart';
import '../../support/pump_screen_app.dart';
import '../../support/session_overrides.dart';

const _screen = ContactsScreen();

Finder get _fab => find.byTooltip('Nuevo contacto');
Finder get _save => find.widgetWithText(FilledButton, 'Guardar');
Finder get _name => find.widgetWithText(TextFormField, 'Nombre');
Finder get _phone => find.widgetWithText(TextFormField, 'Teléfono (opcional)');
Finder get _note => find.widgetWithText(TextFormField, 'Nota (opcional)');

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
  Future<List<Contact>> Function()? list,
  Future<Contact> Function(ContactDraft draft)? save,
}) => FakeCatalogsRepository(
  onContacts:
      list ??
      () async => [
        buildContact(
          id: 4,
          name: 'Oscar',
          phone: '3001234567',
          note: 'paga el 7',
        ),
        buildContact(id: 5, name: 'Marta'),
        buildContact(id: 6, name: 'Pedro', active: false),
      ],
  onSaveContact:
      save ??
      (d) async => buildContact(
        id: d.id ?? 50,
        name: d.name,
        active: d.active,
        phone: d.phone,
        note: d.note,
      ),
);

Future<void> _pump(
  WidgetTester tester,
  FakeCatalogsRepository repo, {
  bool canManage = true,
  bool settle = true,
  double width = 390,
  double textScale = 1,
}) async {
  await pumpScreenApp(
    tester,
    screen: _screen,
    overrides: _overrides(repo, canManage: canManage),
    settle: settle,
    width: width,
    textScale: textScale,
  );
}

void main() {
  group('cuatro estados', () {
    testWidgets('cargando', (tester) async {
      final never = Completer<List<Contact>>();
      await _pump(tester, _repo(list: () => never.future), settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ManageTile), findsNothing);
    });

    testWidgets('datos: nombre, teléfono e inactivo', (tester) async {
      await _pump(tester, _repo());
      expect(find.byType(ManageTile), findsNWidgets(3));
      expect(find.text('Oscar'), findsOneWidget);
      expect(find.text('3001234567'), findsOneWidget);
      expect(find.text('Inactivo'), findsOneWidget);
    });

    testWidgets('vacío', (tester) async {
      await _pump(tester, _repo(list: () async => const []));
      expect(find.text('Sin contactos'), findsOneWidget);
      expect(
        find.text('Crea a las personas con las que tienes acuerdos.'),
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
          return [buildContact()];
        },
      );
      await _pump(tester, repo);
      expect(find.text('Sin conexión con el servidor.'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Intentar nuevamente'));
      await tester.pumpAndSettle();

      expect(find.byType(ManageTile), findsOneWidget);
      expect(repo.contactsCalls, 2);
    });
  });

  group('permisos', () {
    testWidgets('sin catalogos.gestionar: solo lectura', (tester) async {
      await _pump(tester, _repo(), canManage: false);
      expect(find.byType(ManageTile), findsNWidgets(3));
      expect(_fab, findsNothing);
      await tester.tap(find.text('Oscar'));
      await tester.pumpAndSettle();
      expect(find.byType(ContactDialog), findsNothing);
    });
  });

  group('crear', () {
    testWidgets('nombre vacío y teléfono con letras: errores bajo los campos', (
      tester,
    ) async {
      final repo = _repo();
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.enterText(_phone, 'abc123');

      await tester.tap(_save);
      await tester.pumpAndSettle();

      expect(
        find.text('Escribe el nombre del contacto (mínimo 2 letras).'),
        findsOneWidget,
      );
      expect(find.text('Solo números, espacios, + ( ) y -.'), findsOneWidget);
      expect(repo.savedContacts, isEmpty);
      expect(find.byType(ContactDialog), findsOneWidget);
    });

    testWidgets('teléfono y nota en blanco se mandan como ausentes', (
      tester,
    ) async {
      final repo = _repo();
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.enterText(_name, '  Beto ');
      await tester.enterText(_phone, '   ');

      await tester.tap(_save);
      await showToast(tester);

      expect(repo.savedContacts.single.toJson(), {
        'nombre': 'Beto',
        'activo': true,
      });
      await dismissToasts(tester);
    });

    testWidgets('éxito: avisa, cierra y la lista muestra al nuevo', (
      tester,
    ) async {
      final repo = _repo();
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.enterText(_name, 'Beto');
      await tester.enterText(_phone, '+57 310 555 1234');
      await tester.enterText(_note, 'vecino');

      await tester.tap(_save);
      await showToast(tester);

      final draft = repo.savedContacts.single;
      expect(draft.id, isNull);
      expect(draft.phone, '+57 310 555 1234');
      expect(draft.note, 'vecino');
      expect(find.text('Contacto creado'), findsOneWidget);
      await dismissToasts(tester);
      expect(find.byType(ContactDialog), findsNothing);
      expect(find.text('Beto'), findsOneWidget);
      expect(repo.contactsCalls, 1);
    });

    testWidgets('el teléfono no pasa de 20 caracteres', (tester) async {
      await _pump(tester, _repo());
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.enterText(_phone, '1' * 30);
      expect(
        tester.widget<TextFormField>(_phone).controller!.text,
        hasLength(20),
      );
    });
  });

  group('editar', () {
    testWidgets('abre con todos los datos y manda id_contacto', (tester) async {
      final repo = _repo();
      await _pump(tester, repo);
      await tester.tap(find.text('Oscar'));
      await tester.pumpAndSettle();

      expect(find.text('Editar contacto'), findsOneWidget);
      expect(tester.widget<TextFormField>(_name).controller!.text, 'Oscar');
      expect(
        tester.widget<TextFormField>(_phone).controller!.text,
        '3001234567',
      );
      expect(tester.widget<TextFormField>(_note).controller!.text, 'paga el 7');
      expect(find.text('Activo'), findsOneWidget);

      await tester.enterText(_phone, '');
      await tester.tap(_save);
      await showToast(tester);

      expect(repo.savedContacts.single.toJson(), {
        'id_contacto': 4,
        'nombre': 'Oscar',
        'activo': true,
        'nota': 'paga el 7',
      });
      expect(find.text('Contacto actualizado'), findsOneWidget);
      await dismissToasts(tester);
      expect(find.byType(ContactDialog), findsNothing);
      expect(
        find.text('3001234567'),
        findsNothing,
        reason: 'se borró el teléfono',
      );
    });
  });

  group('errores y guardado en curso', () {
    testWidgets('error: avisa y el diálogo sigue abierto con lo escrito', (
      tester,
    ) async {
      final repo = _repo(
        save: (_) async => throw const ApiException(
          'Ya existe un contacto con ese nombre.',
          code: 'DUPLICADO',
          statusCode: 409,
        ),
      );
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.enterText(_name, 'Oscar');

      await tester.tap(_save);
      await showToast(tester);

      expect(
        find.text('Ya existe un contacto con ese nombre.'),
        findsOneWidget,
      );
      expect(find.text('Contacto creado'), findsNothing);
      expect(find.byType(ContactDialog), findsOneWidget);
      expect(tester.widget<TextFormField>(_name).controller!.text, 'Oscar');
      expect(tester.widget<FilledButton>(_save).onPressed, isNotNull);
      await dismissToasts(tester);
    });

    testWidgets('mientras guarda ni la X, ni «Atrás», ni Cancelar cierran', (
      tester,
    ) async {
      final completer = Completer<Contact>();
      final repo = _repo(save: (_) => completer.future);
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.enterText(_name, 'Beto');

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
      expect(find.byType(ContactDialog), findsOneWidget);
      expect(repo.savedContacts, hasLength(1));

      completer.complete(buildContact(id: 50, name: 'Beto'));
      await showToast(tester);
      await dismissToasts(tester);
      expect(find.byType(ContactDialog), findsNothing);
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

  group('distribución del formulario: Nombre | Teléfono', () {
    Future<bool> sameRow(
      WidgetTester tester, {
      required double width,
      double scale = 1,
    }) async {
      await _pump(tester, _repo(), width: width, textScale: scale);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      return tester.getTopLeft(_name).dy == tester.getTopLeft(_phone).dy;
    }

    testWidgets('apilados en 320 y en 390 con texto 1.5', (tester) async {
      expect(await sameRow(tester, width: 320), isFalse, reason: '320');
      expect(
        await sameRow(tester, width: 390, scale: 1.5),
        isFalse,
        reason: '390 · 1.5',
      );
    });

    testWidgets('en pareja en 390, 800 y 1300', (tester) async {
      for (final width in [390.0, 800.0, 1300.0]) {
        expect(await sameRow(tester, width: width), isTrue, reason: '$width');
      }
    });

    testWidgets('la nota (multilínea) va a fila completa, debajo', (
      tester,
    ) async {
      await _pump(tester, _repo(), width: 800);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(_note).dy,
        greaterThan(tester.getTopLeft(_phone).dy),
      );
      expect(
        tester.getSize(_note).width,
        greaterThan(tester.getSize(_phone).width),
      );
    });
  });

  group('sin desbordes', () {
    testWidgets(
      'lista con nombres de 40+ caracteres en 320/390/800/1300 × teclado × texto 1.5',
      (tester) async {
        final repo = _repo(
          list: () async => [
            for (var i = 0; i < 12; i++)
              buildContact(
                id: i + 1,
                name: '$longContactName $i',
                phone: '+57 300 123 4567',
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

    testWidgets('diálogo «Nuevo contacto» abierto con showDialog', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => _overrides(_repo()),
        prepare: (tester) async {
          await tester.tap(_fab);
          await tester.pumpAndSettle();
          expect(find.byType(ContactDialog), findsOneWidget);
        },
      );
    });

    testWidgets(
      'diálogo «Editar» con nombre, teléfono y nota largos y errores de validación',
      (tester) async {
        final repo = _repo(
          list: () async => [
            buildContact(
              id: 4,
              name: longContactName,
              phone: '+57 300 123 4567 89',
              note: longDescription,
            ),
          ],
        );
        await expectScreenNoOverflow(
          tester,
          screen: _screen,
          overrides: () => _overrides(repo),
          prepare: (tester) async {
            await tester.tap(find.byType(ManageTile));
            await tester.pumpAndSettle();
            await tester.enterText(_name, '');
            await tester.enterText(_phone, 'abc');
            await tester.tap(_save);
            await tester.pumpAndSettle();
            expect(find.byType(ContactDialog), findsOneWidget);
          },
        );
      },
    );
  });
}
