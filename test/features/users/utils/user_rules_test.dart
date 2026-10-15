import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/features/users/utils/user_rules.dart';

void main() {
  group('validateName', () {
    test('nulo, vacío, espacios o una letra piden el nombre', () {
      for (final value in [null, '', '   ', 'a', ' a ']) {
        expect(
          UserRules.validateName(value),
          'Escribe el nombre (mínimo 2 letras).',
          reason: '"$value"',
        );
      }
    });

    test('dos letras (recortadas) ya es válido', () {
      expect(UserRules.validateName('Al'), isNull);
      expect(UserRules.validateName('  Al '), isNull);
    });
  });

  group('validateUsername', () {
    test('mínimo 3 caracteres, contando después de recortar', () {
      expect(UserRules.validateUsername(null), 'Mínimo 3 caracteres.');
      expect(UserRules.validateUsername('ab'), 'Mínimo 3 caracteres.');
      expect(UserRules.validateUsername(' ab '), 'Mínimo 3 caracteres.');
      expect(UserRules.validateUsername('abc'), isNull);
    });

    test('acepta minúsculas, números, punto, guion y guion bajo', () {
      for (final user in [
        'daniel',
        'ana.maria',
        'juan_perez',
        'a-b-1',
        '123',
      ]) {
        expect(UserRules.validateUsername(user), isNull, reason: user);
      }
    });

    test('rechaza mayúsculas, espacios internos, tildes y símbolos', () {
      for (final user in ['Daniel', 'ana maria', 'josé', 'ana@x', 'a/b/c']) {
        expect(
          UserRules.validateUsername(user),
          'Solo minúsculas, números, punto, guion y guion bajo.',
          reason: user,
        );
      }
    });
  });

  group('validatePassword', () {
    test('mínimo 10 caracteres (inclusivo)', () {
      expect(UserRules.validatePassword(null), 'Mínimo 10 caracteres.');
      expect(UserRules.validatePassword(''), 'Mínimo 10 caracteres.');
      expect(UserRules.validatePassword('a' * 9), 'Mínimo 10 caracteres.');
      expect(UserRules.validatePassword('a' * 10), isNull);
    });

    test('no se recorta: los espacios cuentan como caracteres', () {
      expect(UserRules.validatePassword('          '), isNull);
    });
  });

  group('draft', () {
    test('recorta nombre y usuario pero NO la contraseña', () {
      final draft = UserRules.draft(
        name: '  Ana María ',
        username: ' ana.maria ',
        password: ' clave segura ',
        isAdmin: false,
      );
      expect(draft.fullName, 'Ana María');
      expect(draft.username, 'ana.maria');
      expect(draft.password, ' clave segura ');
      expect(draft.isAdmin, isFalse);
    });

    test('el rol sale del interruptor de administrador', () {
      final admin = UserRules.draft(
        name: 'Ana',
        username: 'ana',
        password: 'x' * 10,
        isAdmin: true,
      );
      expect(admin.toJson()['rol'], 'ADMINISTRADOR');
    });
  });
}
