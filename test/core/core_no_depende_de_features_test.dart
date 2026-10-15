import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `core/` no importa de `features/` (única excepción: el router, que arma las
/// rutas de las pantallas). Protege la dirección de las dependencias.
void main() {
  test('core no importa de features, salvo el router', () {
    final offenders = <String>[];
    for (final entity in Directory('lib/core').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('/router/')) continue;
      final imports = entity.readAsLinesSync().where(
        (line) => line.startsWith('import ') && line.contains('/features/'),
      );
      if (imports.isNotEmpty) offenders.add(entity.path);
    }
    expect(offenders, isEmpty, reason: 'core importa de features: $offenders');
  });
}
