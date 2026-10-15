import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/features/movements/utils/frequent_rules.dart';

void main() {
  group('FrequentRules.topIds', () {
    // (nombre, ids en el orden de la lista de movimientos, esperado)
    final cases = <(String, List<int>, List<int>)>[
      ('vacío: no hay frecuentes', [], []),
      ('uno solo', [7], [7]),
      ('el más usado primero', [1, 2, 2, 3, 3, 3], [3, 2, 1]),
      (
        'empate: el que apareció antes (movimiento más reciente)',
        [5, 9, 5, 9, 4],
        [5, 9, 4],
      ),
      ('empate triple conserva el orden de aparición', [8, 6, 7], [8, 6, 7]),
      (
        'máximo 4 aunque haya más ids',
        [1, 1, 1, 2, 2, 3, 4, 5, 6],
        [1, 2, 3, 4],
      ),
      (
        'el límite corta después de ordenar, no antes',
        [1, 2, 3, 4, 5, 5, 5],
        [5, 1, 2, 3],
      ),
    ];

    for (final (name, ids, expected) in cases) {
      test(name, () => expect(FrequentRules.topIds(ids), expected));
    }

    test('acepta otro límite', () {
      expect(FrequentRules.topIds([1, 1, 2, 3], limit: 2), [1, 2]);
      expect(FrequentRules.limit, 4);
    });
  });
}
