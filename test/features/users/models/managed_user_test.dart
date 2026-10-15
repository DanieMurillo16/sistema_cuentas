import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/features/users/models/managed_user.dart';

import '../../../helpers/user_fixtures.dart';

void main() {
  group('ManagedUser.fromJson', () {
    test('mapea todos los campos', () {
      final u = ManagedUser.fromJson(
        managedUserJson(
          id: 3,
          fullName: 'Ana María',
          username: 'ana.maria',
          role: 'ADMINISTRADOR',
          active: false,
        ),
      );
      expect(u.id, 3);
      expect(u.fullName, 'Ana María');
      expect(u.username, 'ana.maria');
      expect(u.role, 'ADMINISTRADOR');
      expect(u.active, isFalse);
      expect(u.isAdmin, isTrue);
    });

    test('un USUARIO no es administrador', () {
      expect(ManagedUser.fromJson(managedUserJson()).isAdmin, isFalse);
    });

    test('activo ausente se considera activo', () {
      expect(
        ManagedUser.fromJson(managedUserJson()..remove('activo')).active,
        isTrue,
      );
    });

    test('textos ausentes quedan vacíos; el id es obligatorio', () {
      final u = ManagedUser.fromJson({'id_usuario': 1});
      expect(u.fullName, '');
      expect(u.username, '');
      expect(u.role, '');
      expect(
        () => parseApi(() => ManagedUser.fromJson(const {})),
        throwsA(isA<UnexpectedException>()),
      );
    });

    test('el id puede llegar como texto', () {
      expect(
        ManagedUser.fromJson(managedUserJson()..['id_usuario'] = '12').id,
        12,
      );
    });
  });
}
