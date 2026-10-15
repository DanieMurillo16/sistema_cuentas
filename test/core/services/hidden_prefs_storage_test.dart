import 'package:flutter_test/flutter_test.dart';
// El paquete ya viene con shared_preferences; solo las pruebas usan su almacén.
// ignore_for_file: depend_on_referenced_packages

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:sistema_cuentas/core/services/hidden_prefs_storage.dart';

import '../../support/in_memory_preferences.dart';

/// Un almacén roto: ni lee ni guarda lo que usa este servicio.
base class _BrokenPreferences extends InMemorySharedPreferencesAsync {
  _BrokenPreferences() : super.empty();

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) => throw StateError('no se puede leer');

  @override
  Future<bool> setBool(String key, bool value, SharedPreferencesOptions o) =>
      throw StateError('no se puede guardar');

  @override
  Future<bool> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions o,
  ) => throw StateError('no se puede guardar');
}

HiddenPrefsStorage _storage() => HiddenPrefsStorage(SharedPreferencesAsync.new);

void main() {
  test('sin nada guardado todo está visible', () async {
    useInMemoryPreferences();
    final storage = _storage();
    await storage.load();

    expect(storage.allHidden(7), isFalse);
    expect(storage.hiddenSections(7), isEmpty);
  });

  test('lo guardado se lee al abrir la app, por cuenta', () async {
    final store = useInMemoryPreferences();
    final first = _storage();
    await first.saveAllHidden(7, hidden: true);
    await first.saveHiddenSections(7, {'balance-card', 'day-2026-10-14'});
    await first.saveHiddenSections(8, {'balance-card'});
    expect(store, isNotNull);

    // «Otro arranque»: un almacén nuevo que lee lo que quedó en el teléfono.
    final reopened = _storage();
    await reopened.load();

    expect(reopened.allHidden(7), isTrue);
    expect(reopened.hiddenSections(7), {'balance-card', 'day-2026-10-14'});
    expect(reopened.allHidden(8), isFalse);
    expect(reopened.hiddenSections(8), {'balance-card'});
    expect(reopened.allHidden(9), isFalse);
    expect(reopened.hiddenSections(9), isEmpty);
  });

  test('destapar también se recuerda', () async {
    useInMemoryPreferences();
    final storage = _storage();
    await storage.saveAllHidden(7, hidden: true);
    await storage.saveAllHidden(7, hidden: false);
    await storage.saveHiddenSections(7, {'balance-card'});
    await storage.saveHiddenSections(7, {});

    final reopened = _storage();
    await reopened.load();
    expect(reopened.allHidden(7), isFalse);
    expect(reopened.hiddenSections(7), isEmpty);
  });

  test(
    'valores de otro tipo o llaves ajenas no revientan ni se cuelan',
    () async {
      useInMemoryPreferences({
        'balances_hidden_7': 'si',
        'balances_hidden_x': true,
        'hidden_sections_7': 3,
        'theme_mode': 'dark',
      });
      final storage = _storage();
      await storage.load();

      expect(storage.allHidden(7), isFalse);
      expect(storage.hiddenSections(7), isEmpty);
    },
  );

  test('si el almacenamiento falla, sigue valiendo en memoria', () async {
    SharedPreferencesAsyncPlatformSetter.use(_BrokenPreferences());
    final storage = _storage();
    await storage.load(); // no lanza
    await storage.saveAllHidden(7, hidden: true); // no lanza
    await storage.saveHiddenSections(7, {'balance-card'});

    expect(storage.allHidden(7), isTrue);
    expect(storage.hiddenSections(7), {'balance-card'});
  });
}
