import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';

void main() {
  test('un error propio muestra su mensaje en español', () {
    expect(
      userErrorMessage(const NetworkException('Sin conexión.')),
      'Sin conexión.',
    );
  });

  test('un error desconocido muestra el mensaje genérico', () {
    expect(userErrorMessage(StateError('x')), contains('inesperado'));
  });

  test('el error de un provider dependiente conserva su mensaje', () {
    final base = Provider<int>(
      (ref) => throw const ConfigurationException('Falta configurar.'),
    );
    final dependent = Provider<int>((ref) => ref.watch(base));
    final container = ProviderContainer();
    addTearDown(container.dispose);

    Object? caught;
    try {
      container.read(dependent);
    } catch (error) {
      caught = error;
    }

    expect(caught, isA<ProviderException>());
    expect(userErrorMessage(caught), 'Falta configurar.');
  });
}
