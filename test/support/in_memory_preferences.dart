// El paquete ya está resuelto (lo trae shared_preferences); solo las pruebas
// importan su almacén en memoria.
// ignore_for_file: depend_on_referenced_packages

import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// Las preferencias del dispositivo en memoria (sin disco) para esta prueba.
InMemorySharedPreferencesAsync useInMemoryPreferences([
  Map<String, Object> data = const {},
]) {
  final store = InMemorySharedPreferencesAsync.withData(data);
  SharedPreferencesAsyncPlatform.instance = store;
  return store;
}

/// Preferencias que fallan al leer o al guardar (disco lleno, plataforma rota).
base class ThrowingPreferences extends InMemorySharedPreferencesAsync {
  ThrowingPreferences({this.failRead = true, this.failWrite = true})
    : super.empty();

  final bool failRead;
  final bool failWrite;

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) {
    if (failRead) throw StateError('no se puede leer');
    return super.getString(key, options);
  }

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    if (failWrite) throw StateError('no se puede guardar');
    return super.setString(key, value, options);
  }
}

/// Pone [store] como la plataforma de preferencias.
abstract final class SharedPreferencesAsyncPlatformSetter {
  static void use(SharedPreferencesAsyncPlatform store) =>
      SharedPreferencesAsyncPlatform.instance = store;
}
