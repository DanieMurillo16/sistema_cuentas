import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lo guardado al abrir la app. `main` lo reemplaza por el leído del
/// dispositivo (antes del primer cuadro: las cifras no salen un instante a la
/// vista); sin eso, parte vacío.
final hiddenPrefsStorageProvider = Provider<HiddenPrefsStorage>(
  (ref) => HiddenPrefsStorage(SharedPreferencesAsync.new),
);

/// Guarda en el dispositivo qué cifras tapó cada cuenta (el ojo de la cabecera
/// y los de la tarjeta de balance y del total de cada día), para que sigan
/// tapadas al cerrar y volver a abrir la app. Es de este teléfono y de cada
/// cuenta: otra cuenta empieza con todo visible.
///
/// Se lee una vez ([load]) y se consulta en memoria; si no se puede leer o
/// guardar, lo elegido sigue valiendo hasta cerrar la app.
class HiddenPrefsStorage {
  /// [open] crea el acceso al almacén solo cuando hace falta (y dentro de los
  /// `try`): si la plataforma no lo tiene, la app sigue sin guardar.
  HiddenPrefsStorage(this._open);

  static const _allPrefix = 'balances_hidden_';
  static const _sectionsPrefix = 'hidden_sections_';

  final SharedPreferencesAsync Function() _open;
  late final SharedPreferencesAsync _preferences = _open();
  final _all = <int, bool>{};
  final _sections = <int, Set<String>>{};

  Future<void> load() async {
    try {
      final stored = await _preferences.getAll();
      stored.forEach((key, value) {
        if (key.startsWith(_allPrefix) && value is bool) {
          final id = int.tryParse(key.substring(_allPrefix.length));
          if (id != null) _all[id] = value;
        } else if (key.startsWith(_sectionsPrefix) && value is List) {
          final id = int.tryParse(key.substring(_sectionsPrefix.length));
          if (id != null) _sections[id] = value.whereType<String>().toSet();
        }
      });
    } on Object {
      // Sin acceso al almacenamiento la app abre con todo visible, no se cae.
    }
  }

  /// ¿Tapó esta cuenta todas las cifras con el ojo de la cabecera?
  bool allHidden(int userId) => _all[userId] ?? false;

  /// Las secciones que tapó esta cuenta por separado.
  Set<String> hiddenSections(int userId) =>
      Set.of(_sections[userId] ?? const <String>{});

  Future<void> saveAllHidden(int userId, {required bool hidden}) async {
    _all[userId] = hidden;
    try {
      await _preferences.setBool('$_allPrefix$userId', hidden);
    } on Object {
      // Preferencia cosmética: no vale la pena un error en pantalla.
    }
  }

  Future<void> saveHiddenSections(int userId, Set<String> sections) async {
    _sections[userId] = Set.of(sections);
    try {
      await _preferences.setStringList('$_sectionsPrefix$userId', [
        ...sections,
      ]);
    } on Object {
      // Igual que arriba.
    }
  }
}
