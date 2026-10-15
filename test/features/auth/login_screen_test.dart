import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/features/auth/login_screen.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../../helpers/auth_fixtures.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/pump_at_sizes.dart';

/// La pantalla dentro de una app con el overlay de `AppToast` instalado, como
/// en `app.dart`.
Future<void> _pumpLogin(WidgetTester tester, FakeAuthRepository repository) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: FlutterSmartDialog.init(),
        home: const LoginScreen(),
      ),
    ),
  );
}

Finder get _usernameField => find.byType(TextFormField).at(0);
Finder get _passwordField => find.byType(TextFormField).at(1);
Finder get _submitButton => find.byType(FilledButton);

Future<void> _fillAndSubmit(
  WidgetTester tester, {
  String username = 'daniel',
  String password = 'secreta',
}) async {
  await tester.enterText(_usernameField, username);
  await tester.enterText(_passwordField, password);
  await tester.tap(_submitButton);
  await tester.pump();
}

bool _submitEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_submitButton).onPressed != null;

void main() {
  group('LoginScreen', () {
    testWidgets(
      'estado inicial: formulario listo, botón activo y sin progreso',
      (tester) async {
        await _pumpLogin(tester, FakeAuthRepository());
        await tester.pump();

        expect(find.text(AppConfig.appName), findsOneWidget);
        expect(find.text('Usuario'), findsOneWidget);
        expect(find.text('Contraseña'), findsOneWidget);
        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(_submitEnabled(tester), isTrue);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'validación: vacío muestra los dos mensajes y no llama al servidor',
      (tester) async {
        final repository = FakeAuthRepository();
        await _pumpLogin(tester, repository);
        await tester.pump();

        await tester.tap(_submitButton);
        await tester.pump();

        expect(find.text('Escribe tu usuario.'), findsOneWidget);
        expect(find.text('Escribe tu contraseña.'), findsOneWidget);
        expect(repository.loginCalls, 0);
      },
    );

    testWidgets('validación: usuario de 2 caracteres se rechaza; con 3 pasa', (
      tester,
    ) async {
      final repository = FakeAuthRepository(
        onLogin: (_, _) async => buildSession(),
      );
      await _pumpLogin(tester, repository);
      await tester.pump();

      await _fillAndSubmit(tester, username: 'ab');
      expect(
        find.text('El usuario tiene al menos 3 caracteres.'),
        findsOneWidget,
      );
      expect(repository.loginCalls, 0);

      await tester.enterText(_usernameField, 'abc');
      await tester.tap(_submitButton);
      await tester.pump();
      expect(
        find.text('El usuario tiene al menos 3 caracteres.'),
        findsNothing,
      );
      expect(repository.loginCalls, 1);
    });

    testWidgets('el usuario no admite espacios al escribir', (tester) async {
      await _pumpLogin(tester, FakeAuthRepository());
      await tester.pump();

      await tester.enterText(_usernameField, 'dan iel');

      final field = tester.widget<EditableText>(
        find.descendant(
          of: _usernameField,
          matching: find.byType(EditableText),
        ),
      );
      expect(field.controller.text, 'daniel');
    });

    testWidgets('el ojo muestra y oculta la contraseña', (tester) async {
      await _pumpLogin(tester, FakeAuthRepository());
      await tester.pump();

      bool obscured() => tester
          .widget<EditableText>(
            find.descendant(
              of: _passwordField,
              matching: find.byType(EditableText),
            ),
          )
          .obscureText;

      expect(obscured(), isTrue);
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(obscured(), isFalse);
      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    });

    testWidgets(
      'cargando: botón deshabilitado con progreso, campos en solo lectura y sin doble envío',
      (tester) async {
        final completer = Completer<Session>();
        final repository = FakeAuthRepository(
          onLogin: (_, _) => completer.future,
        );
        await _pumpLogin(tester, repository);
        await tester.pump();

        await _fillAndSubmit(tester);

        expect(repository.loginCalls, 1);
        expect(
          _submitEnabled(tester),
          isFalse,
          reason: 'deshabilitado, no oculto',
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Iniciar sesión'), findsNothing);
        // Solo lectura (no `enabled: false`): así no se pierde el foco.
        expect(
          tester.widget<TextField>(find.byType(TextField).at(0)).readOnly,
          isTrue,
        );
        expect(
          tester.widget<TextField>(find.byType(TextField).at(1)).readOnly,
          isTrue,
        );

        // Tocar otra vez el botón apagado no envía nada.
        await tester.tap(_submitButton, warnIfMissed: false);
        await tester.pump();
        expect(repository.loginCalls, 1);

        completer.complete(buildSession());
        await tester.pump();
      },
    );

    testWidgets(
      'error: toast con el mensaje del servidor y el botón vuelve a estar activo',
      (tester) async {
        final repository = FakeAuthRepository(
          onLogin: (_, _) async => throw const ApiException(
            'Usuario o contraseña incorrectos.',
            code: 'CREDENCIALES',
            statusCode: 401,
          ),
        );
        await _pumpLogin(tester, repository);
        await tester.pump();

        await _fillAndSubmit(tester, password: 'mala');
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(_submitEnabled(tester), isTrue);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        // Se conserva lo escrito.
        expect(find.text('daniel'), findsOneWidget);

        await tester.pump(const Duration(seconds: 5)); // retira el toast
      },
    );

    testWidgets('error de red: toast con mensaje de conexión', (tester) async {
      final repository = FakeAuthRepository(
        onLogin: (_, _) async => throw const NetworkException(
          'No fue posible conectar con el servidor. Revisa tu conexión.',
        ),
      );
      await _pumpLogin(tester, repository);
      await tester.pump();

      await _fillAndSubmit(tester);
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text(
          'No fue posible conectar con el servidor. Revisa tu conexión.',
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets(
      'éxito: abre la sesión (el router hace el resto) y no hay toast de error',
      (tester) async {
        final repository = FakeAuthRepository(
          onLogin: (_, _) async => buildSession(fullName: 'Ana'),
        );
        await _pumpLogin(tester, repository);
        await tester.pump();
        // Como en la app: el router ya resolvió la sesión (sin token → null)
        // antes de mostrar el login.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(LoginScreen)),
        );
        await tester.runAsync(() => container.read(sessionProvider.future));

        await _fillAndSubmit(tester, username: '  ana ', password: 'secreta');
        await tester.pump(const Duration(milliseconds: 500));

        expect(container.read(sessionProvider).value?.user.fullName, 'Ana');
        expect(find.byIcon(Icons.error_outline), findsNothing);
        expect(repository.lastPassword, 'secreta');
      },
    );

    testWidgets('Enter en la contraseña envía el formulario', (tester) async {
      final repository = FakeAuthRepository(
        onLogin: (_, _) async => buildSession(),
      );
      await _pumpLogin(tester, repository);
      await tester.pump();

      await tester.enterText(_usernameField, 'daniel');
      await tester.enterText(_passwordField, 'secreta');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(repository.loginCalls, 1);
    });

    testWidgets('no desborda en 320/390/800/1300 × teclado × texto 1.5', (
      tester,
    ) async {
      await expectNoOverflow(
        tester,
        const LoginScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
    });

    testWidgets('no desborda con los mensajes de validación visibles', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final width in testWidths) {
        tester.view.physicalSize = Size(width, 700);
        for (final keyboard in testKeyboards) {
          tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
          await _pumpLogin(tester, FakeAuthRepository());
          await tester.pump();
          await tester.ensureVisible(_submitButton);
          await tester.tap(_submitButton);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$width px · teclado $keyboard (con errores de validación)',
          );
        }
      }
    });
  });
}
