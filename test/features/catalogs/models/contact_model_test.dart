import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';

import '../../../helpers/recurring_fixtures.dart';

void main() {
  group('Contact.fromJson', () {
    test('mapea todos los campos', () {
      final c = Contact.fromJson(
        contactJson(
          id: 4,
          name: 'Oscar',
          phone: '3001234567',
          note: 'paga el 7',
        ),
      );
      expect(c.id, 4);
      expect(c.name, 'Oscar');
      expect(c.phone, '3001234567');
      expect(c.note, 'paga el 7');
      expect(c.active, isTrue);
    });

    test('teléfono y nota ausentes, vacíos o de espacios quedan en null', () {
      expect(Contact.fromJson(contactJson()).phone, isNull);
      final blank = Contact.fromJson(
        contactJson()
          ..['telefono'] = '   '
          ..['nota'] = '',
      );
      expect(blank.phone, isNull);
      expect(blank.note, isNull);
    });

    test('activo ausente se considera activo; false lo desactiva', () {
      expect(Contact.fromJson(contactJson()..remove('activo')).active, isTrue);
      expect(Contact.fromJson(contactJson(active: false)).active, isFalse);
    });

    test('sin nombre o sin id: error propio en español', () {
      for (final key in ['nombre', 'id_contacto']) {
        expect(
          () => parseApi(() => Contact.fromJson(contactJson()..remove(key))),
          throwsA(
            isA<UnexpectedException>().having(
              (e) => e.message,
              'message',
              startsWith('El servidor devolvió datos'),
            ),
          ),
          reason: 'falta $key',
        );
      }
    });
  });
}
