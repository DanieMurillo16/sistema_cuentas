import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/models/user_profile.dart';

import '../../helpers/auth_fixtures.dart';

void main() {
  group('UserProfile.fromJson', () {
    test('lee todos los campos', () {
      final user = UserProfile.fromJson(
        profileJson(
          id: 3,
          fullName: 'Ana Gómez',
          username: 'ana',
          role: 'USUARIO',
        ),
      );
      expect(user.id, 3);
      expect(user.fullName, 'Ana Gómez');
      expect(user.username, 'ana');
      expect(user.role, 'USUARIO');
      expect(user.isAdmin, isFalse);
    });

    test('ADMINISTRADOR es admin', () {
      expect(
        UserProfile.fromJson(profileJson(role: 'ADMINISTRADOR')).isAdmin,
        isTrue,
      );
    });

    test('el id puede llegar como double (num)', () {
      final json = profileJson()..['id_usuario'] = 9.0;
      expect(UserProfile.fromJson(json).id, 9);
    });

    test('textos ausentes o nulos quedan vacíos', () {
      final user = UserProfile.fromJson({
        'id_usuario': 1,
        'nombre_completo': null,
      });
      expect(user.fullName, '');
      expect(user.username, '');
      expect(user.role, '');
      expect(user.isAdmin, isFalse);
    });

    test('sin id_usuario falla (dato obligatorio)', () {
      expect(
        () => UserProfile.fromJson({'usuario': 'x'}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('Session.fromJson', () {
    test('lee perfil y permisos', () {
      final session = Session.fromJson({
        'perfil': profileJson(),
        'permisos': [Permissions.registerMovements, Permissions.manageCatalogs],
      });
      expect(session.user.username, 'daniel');
      expect(session.permissions, {
        'movimientos.registrar',
        'catalogos.gestionar',
      });
    });

    test('hasPermission distingue lo que tiene de lo que no', () {
      final session = Session.fromJson({
        'perfil': profileJson(),
        'permisos': [Permissions.registerMovements],
      });
      expect(session.hasPermission(Permissions.registerMovements), isTrue);
      expect(session.hasPermission(Permissions.manageUsers), isFalse);
    });

    test('sin permisos o con un valor que no es lista queda vacío', () {
      expect(Session.fromJson({'perfil': profileJson()}).permissions, isEmpty);
      expect(
        Session.fromJson({'perfil': profileJson(), 'permisos': 'x'})
            .permissions,
        isEmpty,
      );
    });

    test('permisos repetidos se colapsan', () {
      final session = Session.fromJson({
        'perfil': profileJson(),
        'permisos': ['a.b', 'a.b'],
      });
      expect(session.permissions, {'a.b'});
    });

    test('acepta el data completo del login (con token y expira_en)', () {
      final session = Session.fromJson(loginDataJson());
      expect(session.user.fullName, 'Daniel Murillo');
    });

    test('sin perfil falla', () {
      expect(
        () => Session.fromJson({'permisos': []}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
