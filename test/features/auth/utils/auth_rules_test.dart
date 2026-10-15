import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/features/auth/utils/auth_rules.dart';

void main() {
  group('AuthRules.validateUsername', () {
    test('vacío o nulo pide el usuario', () {
      expect(AuthRules.validateUsername(null), 'Escribe tu usuario.');
      expect(AuthRules.validateUsername(''), 'Escribe tu usuario.');
    });

    test('solo espacios cuenta como vacío', () {
      expect(AuthRules.validateUsername('   '), 'Escribe tu usuario.');
    });

    test('menos de 3 caracteres es inválido', () {
      expect(
        AuthRules.validateUsername('ab'),
        'El usuario tiene al menos 3 caracteres.',
      );
    });

    test('los espacios de los extremos no cuentan para el mínimo', () {
      expect(
        AuthRules.validateUsername('  ab  '),
        'El usuario tiene al menos 3 caracteres.',
      );
    });

    test('exactamente 3 caracteres es válido (borde)', () {
      expect(AuthRules.validateUsername('abc'), isNull);
    });

    test('un usuario normal y uno de largo máximo son válidos', () {
      expect(AuthRules.validateUsername('daniel.murillo'), isNull);
      expect(
        AuthRules.validateUsername('a' * AuthRules.usernameMaxLength),
        isNull,
      );
    });
  });

  group('AuthRules.validatePassword', () {
    test('vacío o nulo pide la contraseña', () {
      expect(AuthRules.validatePassword(null), 'Escribe tu contraseña.');
      expect(AuthRules.validatePassword(''), 'Escribe tu contraseña.');
    });

    test('no recorta espacios: " " es una contraseña escrita', () {
      expect(AuthRules.validatePassword(' '), isNull);
    });

    test(
      'cualquier contraseña no vacía es válida, también de largo máximo',
      () {
        expect(AuthRules.validatePassword('x'), isNull);
        expect(
          AuthRules.validatePassword('p' * AuthRules.passwordMaxLength),
          isNull,
        );
      },
    );
  });

  test('límites de longitud coinciden con el backend (50 y 72)', () {
    expect(AuthRules.usernameMaxLength, 50);
    expect(AuthRules.passwordMaxLength, 72);
  });
}
