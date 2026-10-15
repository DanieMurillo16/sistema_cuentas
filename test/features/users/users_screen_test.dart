import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/users/data/users_repository.dart';
import 'package:sistema_cuentas/features/users/models/managed_user.dart';
import 'package:sistema_cuentas/features/users/models/user_draft.dart';
import 'package:sistema_cuentas/features/users/users_screen.dart';
import 'package:sistema_cuentas/features/users/widgets/user_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/manage_tile.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/user_fixtures.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/fake_users_repository.dart';
import '../../support/pump_screen_app.dart';
import '../../support/session_overrides.dart';

const _screen = UsersScreen();

Finder get _fab => find.byTooltip('Nuevo usuario');
Finder get _create => find.widgetWithText(FilledButton, 'Crear usuario');
Finder get _name => find.widgetWithText(TextFormField, 'Nombre');
Finder get _username => find.widgetWithText(TextFormField, 'Usuario');
Finder get _password => find.widgetWithText(TextFormField, 'Contraseña');

Finder _switchOf(int id) => find.descendant(
  of: find.byKey(ValueKey('user-$id')),
  matching: find.byType(Switch),
);

bool? _switchEnabled(WidgetTester tester, int id) =>
    tester.widget<Switch>(_switchOf(id)).onChanged == null ? false : true;

List<ManagedUser> _users() => [
  buildManagedUser(
    id: 7,
    fullName: 'Daniel Murillo',
    username: 'daniel',
    role: 'ADMINISTRADOR',
  ),
  buildManagedUser(id: 8, fullName: 'Ana María', username: 'ana'),
  buildManagedUser(
    id: 9,
    fullName: 'Pedro Pérez',
    username: 'pedro',
    active: false,
  ),
];

List<Override> _overrides(FakeUsersRepository repo, {bool admin = true}) => [
  ...(admin ? adminSession() : sessionOverrides()).overrides,
  usersRepositoryProvider.overrideWithValue(repo),
];

FakeUsersRepository _repo({
  Future<List<ManagedUser>> Function()? list,
  Future<ManagedUser> Function(UserDraft draft)? create,
  Future<ManagedUser> Function(int id, bool active)? setActive,
}) => FakeUsersRepository(
  onList: list ?? () async => _users(),
  onCreate:
      create ??
      (d) async => buildManagedUser(
        id: 20,
        fullName: d.fullName,
        username: d.username,
        role: d.isAdmin ? 'ADMINISTRADOR' : 'USUARIO',
      ),
  onSetActive:
      setActive ??
      (id, active) async =>
          _users().firstWhere((u) => u.id == id).copyWithActive(active),
);

extension on ManagedUser {
  ManagedUser copyWithActive(bool active) => ManagedUser(
    id: id,
    fullName: fullName,
    username: username,
    role: role,
    active: active,
  );
}

Future<void> _pump(
  WidgetTester tester,
  FakeUsersRepository repo, {
  bool admin = true,
  bool settle = true,
  double width = 390,
  double textScale = 1,
}) async {
  await pumpScreenApp(
    tester,
    screen: _screen,
    overrides: _overrides(repo, admin: admin),
    settle: settle,
    width: width,
    textScale: textScale,
  );
}

void main() {
  group('cuatro estados', () {
    testWidgets('cargando', (tester) async {
      final never = Completer<List<ManagedUser>>();
      await _pump(tester, _repo(list: () => never.future), settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ManageTile), findsNothing);
    });

    testWidgets('datos: nombre, usuario · rol e inactivo', (tester) async {
      await _pump(tester, _repo());
      expect(find.byType(ManageTile), findsNWidgets(3));
      expect(find.text('daniel · Administrador'), findsOneWidget);
      expect(find.text('ana · Usuario'), findsOneWidget);
      expect(find.text('Inactivo'), findsOneWidget);
    });

    testWidgets('vacío', (tester) async {
      await _pump(tester, _repo(list: () async => const []));
      expect(find.text('Sin usuarios'), findsOneWidget);
      expect(
        find.text('Da de alta a las personas que usarán la app.'),
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
          return _users();
        },
      );
      await _pump(tester, repo);
      expect(find.text('Sin conexión con el servidor.'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Intentar nuevamente'));
      await tester.pumpAndSettle();

      expect(find.byType(ManageTile), findsNWidgets(3));
      expect(repo.listCalls, 2);
    });
  });

  group('permiso usuarios.gestionar', () {
    testWidgets(
      'sin el permiso: «Sin acceso», sin botón y sin pedir la lista',
      (tester) async {
        final repo = _repo();
        await _pump(tester, repo, admin: false);

        expect(find.text('Sin acceso'), findsOneWidget);
        expect(
          find.text('Solo un administrador puede ver y crear usuarios.'),
          findsOneWidget,
        );
        expect(_fab, findsNothing);
        expect(find.byType(ManageTile), findsNothing);
        expect(repo.listCalls, 0);
      },
    );

    testWidgets('con el permiso aparece el botón «Nuevo usuario»', (
      tester,
    ) async {
      await _pump(tester, _repo());
      expect(_fab, findsOneWidget);
    });
  });

  group('interruptor activo / inactivo', () {
    testWidgets(
      'el de uno mismo está apagado (con su explicación); los demás no',
      (tester) async {
        await _pump(tester, _repo());

        expect(_switchEnabled(tester, 7), isFalse, reason: 'yo (id 7)');
        expect(_switchEnabled(tester, 8), isTrue);
        expect(_switchEnabled(tester, 9), isTrue);
        expect(tester.widget<Switch>(_switchOf(7)).value, isTrue);
        expect(
          find.byTooltip('No puedes desactivarte a ti mismo'),
          findsOneWidget,
        );
        expect(find.byTooltip('Activo'), findsNWidgets(2));
      },
    );

    testWidgets('tocar el de uno mismo no llama al servidor', (tester) async {
      final repo = _repo();
      await _pump(tester, repo);
      await tester.tap(_switchOf(7), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(repo.setActiveCalls, 0);
      expect(tester.widget<Switch>(_switchOf(7)).value, isTrue);
    });

    testWidgets('desactivar a otro: manda (id, false) y la fila cambia', (
      tester,
    ) async {
      final repo = _repo();
      await _pump(tester, repo);

      await tester.tap(_switchOf(8));
      await tester.pumpAndSettle();

      expect(repo.activeChanges.single, (8, false));
      expect(tester.widget<Switch>(_switchOf(8)).value, isFalse);
      expect(find.text('Inactivo'), findsNWidgets(2));
      expect(repo.listCalls, 1, reason: 'upsert, sin recargar la lista');
    });

    testWidgets('activar a un inactivo manda (id, true)', (tester) async {
      final repo = _repo();
      await _pump(tester, repo);

      await tester.tap(_switchOf(9));
      await tester.pumpAndSettle();

      expect(repo.activeChanges.single, (9, true));
      expect(find.text('Inactivo'), findsNothing);
    });

    testWidgets('mientras guarda todos los interruptores quedan apagados', (
      tester,
    ) async {
      final completer = Completer<ManagedUser>();
      final repo = _repo(setActive: (_, _) => completer.future);
      await _pump(tester, repo);

      await tester.tap(_switchOf(8));
      await tester.pump();

      expect(_switchEnabled(tester, 8), isFalse);
      expect(_switchEnabled(tester, 9), isFalse);
      await tester.tap(_switchOf(9), warnIfMissed: false);
      await tester.pump();
      expect(repo.setActiveCalls, 1);

      completer.complete(
        buildManagedUser(id: 8, fullName: 'Ana María', active: false),
      );
      await tester.pumpAndSettle();
      expect(_switchEnabled(tester, 9), isTrue);
    });

    testWidgets('error: avisa en español y la fila queda como estaba', (
      tester,
    ) async {
      final repo = _repo(
        setActive: (_, _) async => throw const NetworkException(
          'No fue posible conectar con el servidor. Revisa tu conexión.',
        ),
      );
      await _pump(tester, repo);

      await tester.tap(_switchOf(8));
      await showToast(tester);

      expect(
        find.text(
          'No fue posible conectar con el servidor. Revisa tu conexión.',
        ),
        findsOneWidget,
      );
      expect(tester.widget<Switch>(_switchOf(8)).value, isTrue);
      expect(_switchEnabled(tester, 8), isTrue, reason: 'puede reintentar');
      await dismissToasts(tester);
    });

    // DEFECTO (user_active_switch.dart, ref.listen dentro de build): cada fila
    // de la lista escucha el mismo provider, así que un solo fallo dispara un
    // aviso POR FILA y se encolan uno tras otro (con 3 usuarios, ≈9 s de aviso
    // repetido). Debe verse una vez. Se queda en rojo hasta que se escuche en
    // un solo lugar (p. ej. la pantalla o `listenSave`).
    testWidgets('un solo fallo muestra UN aviso (no uno por fila)', (
      tester,
    ) async {
      final repo = _repo(
        setActive: (_, _) async => throw const NetworkException('Falla X.'),
      );
      await _pump(tester, repo);

      await tester.tap(_switchOf(8));
      await showToast(tester);
      expect(find.text('Falla X.'), findsOneWidget);

      // Pasa lo que dura un aviso (≈3 s): no debe aparecer otro igual detrás.
      var again = 0;
      for (var i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (i >= 8 && find.text('Falla X.').evaluate().isNotEmpty) again++;
      }
      expect(again, 0, reason: 'avisos repetidos en cola');
      await dismissToasts(tester);
    });

    testWidgets('el lector de pantalla oye «nombre: activo/inactivo»', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _repo());
      expect(
        find.bySemanticsLabel(RegExp('Ana María: activo')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Pedro Pérez: inactivo')),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('alta de usuario', () {
    Future<void> openDialog(
      WidgetTester tester,
      FakeUsersRepository repo,
    ) async {
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(find.byType(UserDialog), findsOneWidget);
    }

    testWidgets('vacío: errores bajo cada campo y no llama al servidor', (
      tester,
    ) async {
      final repo = _repo();
      await openDialog(tester, repo);

      await tester.tap(_create);
      await tester.pumpAndSettle();

      expect(find.text('Escribe el nombre (mínimo 2 letras).'), findsOneWidget);
      expect(find.text('Mínimo 3 caracteres.'), findsOneWidget);
      expect(find.text('Mínimo 10 caracteres.'), findsOneWidget);
      expect(repo.createCalls, 0);
      expect(find.byType(UserDialog), findsOneWidget);
    });

    testWidgets(
      'el usuario solo admite minúsculas, números, punto, guion y guion bajo',
      (tester) async {
        await openDialog(tester, _repo());
        await tester.enterText(_username, 'Ana María_01 x.y-z!');
        expect(
          tester.widget<TextFormField>(_username).controller!.text,
          'naara_01x.y-z',
        );
      },
    );

    testWidgets('la contraseña va oculta y el ojo la muestra', (tester) async {
      await openDialog(tester, _repo());
      Finder editable() =>
          find.descendant(of: _password, matching: find.byType(EditableText));
      expect(tester.widget<EditableText>(editable()).obscureText, isTrue);

      await tester.tap(find.byTooltip('Mostrar'));
      await tester.pumpAndSettle();

      expect(tester.widget<EditableText>(editable()).obscureText, isFalse);
      expect(find.byTooltip('Ocultar'), findsOneWidget);
    });

    testWidgets(
      'éxito: manda el borrador, avisa, cierra y la lista muestra al nuevo',
      (tester) async {
        final repo = _repo();
        await openDialog(tester, repo);
        await tester.enterText(_name, '  Luis Gómez ');
        await tester.enterText(_username, 'luis.gomez');
        await tester.enterText(_password, 'una-clave-larga');
        await tester.tap(find.text('Administrador'));
        await tester.pumpAndSettle();

        await tester.tap(_create);
        await showToast(tester);

        final draft = repo.created.single;
        expect(draft.toJson(), {
          'nombre': 'Luis Gómez',
          'usuario': 'luis.gomez',
          'clave': 'una-clave-larga',
          'rol': 'ADMINISTRADOR',
        });
        expect(find.text('Usuario creado'), findsOneWidget);
        await dismissToasts(tester);
        expect(find.byType(UserDialog), findsNothing);
        expect(find.text('Luis Gómez'), findsOneWidget);
        expect(find.text('luis.gomez · Administrador'), findsOneWidget);
        expect(repo.listCalls, 1);
      },
    );

    testWidgets('por defecto el rol es USUARIO', (tester) async {
      final repo = _repo();
      await openDialog(tester, repo);
      await tester.enterText(_name, 'Luis');
      await tester.enterText(_username, 'luis');
      await tester.enterText(_password, 'una-clave-larga');

      await tester.tap(_create);
      await showToast(tester);

      expect(repo.created.single.isAdmin, isFalse);
      await dismissToasts(tester);
    });

    testWidgets(
      'error (usuario repetido): avisa y el diálogo sigue abierto con lo escrito',
      (tester) async {
        final repo = _repo(
          create: (_) async => throw const ApiException(
            'Ese usuario ya existe.',
            code: 'DUPLICADO',
            statusCode: 409,
          ),
        );
        await openDialog(tester, repo);
        await tester.enterText(_name, 'Luis');
        await tester.enterText(_username, 'daniel');
        await tester.enterText(_password, 'una-clave-larga');

        await tester.tap(_create);
        await showToast(tester);

        expect(find.text('Ese usuario ya existe.'), findsOneWidget);
        expect(find.text('Usuario creado'), findsNothing);
        expect(find.byType(UserDialog), findsOneWidget);
        expect(
          tester.widget<TextFormField>(_username).controller!.text,
          'daniel',
        );
        expect(tester.widget<FilledButton>(_create).onPressed, isNotNull);
        await dismissToasts(tester);
      },
    );

    testWidgets('mientras guarda ni la X, ni «Atrás», ni Cancelar cierran', (
      tester,
    ) async {
      final completer = Completer<ManagedUser>();
      final repo = _repo(create: (_) => completer.future);
      await openDialog(tester, repo);
      await tester.enterText(_name, 'Luis');
      await tester.enterText(_username, 'luis');
      await tester.enterText(_password, 'una-clave-larga');

      await tester.tap(_create);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<FilledButton>(_create).onPressed, isNull);
      await tester.tap(find.byTooltip('Cerrar'), warnIfMissed: false);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.tap(find.text('Cancelar'), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(UserDialog), findsOneWidget);
      expect(repo.createCalls, 1);

      completer.complete(
        buildManagedUser(id: 20, fullName: 'Luis', username: 'luis'),
      );
      await showToast(tester);
      await dismissToasts(tester);
      expect(find.byType(UserDialog), findsNothing);
    });

    group('distribución: un campo por fila', () {
      Future<void> open(
        WidgetTester tester, {
        required double width,
        double scale = 1,
      }) async {
        await _pump(tester, _repo(), width: width, textScale: scale);
        await tester.tap(_fab);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      testWidgets('Nombre, Usuario y Contraseña van uno debajo del otro', (
        tester,
      ) async {
        for (final (width, scale) in [
          (320.0, 1.0),
          (390.0, 1.0),
          (390.0, 1.5),
          (800.0, 1.0),
          (1300.0, 1.0),
        ]) {
          await open(tester, width: width, scale: scale);
          final tops = [
            _name,
            _username,
            _password,
          ].map((f) => tester.getTopLeft(f).dy).toList();
          expect(
            tops,
            orderedEquals([...tops]..sort()),
            reason: '$width · $scale',
          );
          expect(tops.toSet(), hasLength(3), reason: '$width · $scale');
          // Misma anchura: ya no hay un campo más angosto que el otro.
          expect(
            tester.getSize(_username).width,
            tester.getSize(_password).width,
            reason: '$width · $scale',
          );
        }
      });

      testWidgets('muestra qué se espera en Usuario y Contraseña', (
        tester,
      ) async {
        await open(tester, width: 390);
        expect(find.textContaining('Minúsculas, números'), findsOneWidget);
        expect(find.text('Mínimo 10 caracteres'), findsOneWidget);
      });
    });
  });

  testWidgets('«Atrás» de la barra vuelve a la pantalla anterior', (
    tester,
  ) async {
    await _pump(tester, _repo());
    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();
    expect(find.text(previousScreenText), findsOneWidget);
  });

  group('sin desbordes', () {
    testWidgets(
      'lista con nombres de 40+ caracteres en 320/390/800/1300 × teclado × texto 1.5',
      (tester) async {
        expect(longFullName.length, greaterThan(40));
        final repo = _repo(
          list: () async => [
            for (var i = 0; i < 12; i++)
              buildManagedUser(
                id: i == 0 ? 7 : i + 100,
                fullName: '$longFullName $i',
                username: longUsername,
                role: i.isEven ? 'ADMINISTRADOR' : 'USUARIO',
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

    testWidgets('vacío, error y sin acceso', (tester) async {
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
        overrides: () => _overrides(_repo(), admin: false),
      );
    });

    // Lista vacía: así el desborde de la fila inactiva (defecto de ManageTile,
    // ver la prueba de la lista) no tapa lo que se mide del diálogo.
    testWidgets('diálogo «Nuevo usuario» abierto con showDialog', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => _overrides(_repo(list: () async => const [])),
        prepare: (tester) async {
          await tester.tap(_fab);
          await tester.pumpAndSettle();
          expect(find.byType(UserDialog), findsOneWidget);
        },
      );
    });

    testWidgets('diálogo con textos largos y errores de validación visibles', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => _overrides(_repo(list: () async => const [])),
        prepare: (tester) async {
          await tester.tap(_fab);
          await tester.pumpAndSettle();
          await tester.enterText(_name, longFullName);
          await tester.enterText(_username, longUsername);
          await tester.enterText(_password, 'x');
          await tester.tap(_create);
          await tester.pumpAndSettle();
          expect(find.byType(UserDialog), findsOneWidget);
        },
      );
    });
  });
}
