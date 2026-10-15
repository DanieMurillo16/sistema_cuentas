import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_cancel_rules.dart';

import '../../../helpers/movement_fixtures.dart';

void main() {
  group('reason', () {
    test('es el texto que la app manda sola', () {
      expect(MovementCancelRules.reason, 'Eliminado desde la app');
    });

    test('cumple el contrato del servidor (3 a 255 caracteres)', () {
      expect(
        MovementCancelRules.reason.trim().length,
        inInclusiveRange(3, 255),
      );
      expect(MovementCancelRules.reason, MovementCancelRules.reason.trim());
    });
  });

  group('título y subtítulo', () {
    test('el título dice si es ingreso o gasto', () {
      expect(
        MovementCancelRules.title(buildMovement(type: MovementType.income)),
        'Eliminar ingreso',
      );
      expect(MovementCancelRules.title(buildMovement()), 'Eliminar gasto');
    });

    test('el subtítulo trae descripción y monto con signo', () {
      expect(
        MovementCancelRules.subtitle(
          buildMovement(description: 'mercado del mes'),
        ),
        r'Mercado del mes · -$ 25.000',
      );
      expect(
        MovementCancelRules.subtitle(
          buildMovement(
            type: MovementType.income,
            description: 'Salario',
            valueCents: 150000000,
          ),
        ),
        r'Salario · +$ 1.500.000',
      );
    });

    test('con importe de 12 dígitos no falla', () {
      final text = MovementCancelRules.subtitle(
        buildMovement(valueCents: 99999999999900),
      );
      expect(text, contains('999.999.999.999'));
    });
  });
}
