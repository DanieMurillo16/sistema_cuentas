import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeStorageProvider = Provider<ThemeStorage>(
  (ref) => ThemeStorage(SharedPreferencesAsync()),
);

/// Guarda en el dispositivo el tema que eligió la persona (claro, oscuro o
/// automático). Es una preferencia de este teléfono, no de la cuenta.
class ThemeStorage {
  const ThemeStorage(this._preferences);

  static const _key = 'theme_mode';

  final SharedPreferencesAsync _preferences;

  /// El tema guardado; automático si no hay o no se entiende.
  Future<ThemeMode> read() async {
    try {
      final stored = await _preferences.getString(_key);
      return ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
    } on Object {
      // Sin acceso al almacenamiento la app abre en automático, no se cae.
      return ThemeMode.system;
    }
  }

  /// Si no se puede guardar, el tema elegido sigue valiendo hasta cerrar la app.
  Future<void> save(ThemeMode mode) async {
    try {
      await _preferences.setString(_key, mode.name);
    } on Object {
      // Preferencia cosmética: no vale la pena un error en pantalla.
    }
  }
}
