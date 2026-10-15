import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/models/category_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method_draft.dart';
import 'package:sistema_cuentas/features/users/models/user_draft.dart';

void main() {
  group('CategoryDraft.toJson', () {
    test('al crear manda el tipo y NO manda id_categoria', () {
      final json = const CategoryDraft(
        type: MovementType.income,
        name: 'Salario',
        isCapital: false,
        active: true,
      ).toJson();
      expect(json, {
        'tipo': 'INGRESO',
        'nombre': 'Salario',
        'es_capital': false,
        'activo': true,
      });
    });

    test('al editar manda id_categoria y NO manda el tipo', () {
      final json = const CategoryDraft(
        id: 9,
        type: MovementType.expense,
        name: 'Mercado',
        isCapital: true,
        active: false,
      ).toJson();
      expect(json, {
        'id_categoria': 9,
        'nombre': 'Mercado',
        'es_capital': true,
        'activo': false,
      });
      expect(json.containsKey('tipo'), isFalse);
    });
  });

  group('PaymentMethodDraft.toJson', () {
    test('crear: sin id', () {
      expect(const PaymentMethodDraft(name: 'Nequi', active: true).toJson(), {
        'nombre': 'Nequi',
        'activo': true,
      });
    });

    test('editar: con id_medio', () {
      expect(
        const PaymentMethodDraft(id: 2, name: 'Nequi', active: false).toJson(),
        {'id_medio': 2, 'nombre': 'Nequi', 'activo': false},
      );
    });
  });

  group('ContactDraft.toJson', () {
    test('crear sin opcionales: solo nombre y activo', () {
      expect(const ContactDraft(name: 'Oscar', active: true).toJson(), {
        'nombre': 'Oscar',
        'activo': true,
      });
    });

    test('editar con todo: id_contacto, teléfono y nota', () {
      expect(
        const ContactDraft(
          id: 4,
          name: 'Oscar',
          active: false,
          phone: '3001234567',
          note: 'paga el 7',
        ).toJson(),
        {
          'id_contacto': 4,
          'nombre': 'Oscar',
          'activo': false,
          'telefono': '3001234567',
          'nota': 'paga el 7',
        },
      );
    });
  });

  group('UserDraft.toJson', () {
    test('usuario normal: rol USUARIO y la clave va como «clave»', () {
      expect(
        const UserDraft(
          fullName: 'Ana',
          username: 'ana',
          password: 'una-clave-larga',
          isAdmin: false,
        ).toJson(),
        {
          'nombre': 'Ana',
          'usuario': 'ana',
          'clave': 'una-clave-larga',
          'rol': 'USUARIO',
        },
      );
    });
  });
}
