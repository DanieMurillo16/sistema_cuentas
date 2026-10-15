import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sistema_cuentas/core/services/theme_storage.dart';

import '../../support/in_memory_preferences.dart';

ThemeStorage _storage() => ThemeStorage(SharedPreferencesAsync());

void main() {
  group('read', () {
    test('sin nada guardado: automático', () async {
      useInMemoryPreferences();
      expect(await _storage().read(), ThemeMode.system);
    });

    test('cada valor guardado se lee igual', () async {
      for (final mode in ThemeMode.values) {
        useInMemoryPreferences({'theme_mode': mode.name});
        expect(await _storage().read(), mode, reason: mode.name);
      }
    });

    test('valor inválido, vacío o de otro tipo de dato: automático', () async {
      for (final raw in ['', 'oscuro', 'DARK', 'Light', 'null', ' dark', '1']) {
        useInMemoryPreferences({'theme_mode': raw});
        expect(await _storage().read(), ThemeMode.system, reason: '«$raw»');
      }
    });

    test(
      'una preferencia con el mismo nombre pero de otro tipo no revienta',
      () async {
        useInMemoryPreferences({'theme_mode': 3});
        expect(await _storage().read(), ThemeMode.system);
      },
    );
  });

  group('save', () {
    test('guarda el nombre del modo bajo «theme_mode»', () async {
      final store = useInMemoryPreferences();

      await _storage().save(ThemeMode.dark);

      final prefs = SharedPreferencesAsync();
      expect(await prefs.getString('theme_mode'), 'dark');
      expect(store, isNotNull);
    });

    test('ida y vuelta con los tres modos', () async {
      useInMemoryPreferences();
      final storage = _storage();

      for (final mode in [
        ThemeMode.light,
        ThemeMode.dark,
        ThemeMode.system,
        ThemeMode.dark,
      ]) {
        await storage.save(mode);
        expect(await storage.read(), mode);
      }
    });

    test('guardar uno reemplaza al anterior', () async {
      useInMemoryPreferences({'theme_mode': 'light'});
      final storage = _storage();

      await storage.save(ThemeMode.dark);

      expect(await storage.read(), ThemeMode.dark);
    });

    test('no toca otras preferencias (por ejemplo el token)', () async {
      useInMemoryPreferences({'auth_token': 'abc'});

      await _storage().save(ThemeMode.light);

      expect(await SharedPreferencesAsync().getString('auth_token'), 'abc');
    });
  });

  group('tolera preferencias que fallan', () {
    test('si leer lanza: automático, sin excepción', () async {
      SharedPreferencesAsyncPlatformSetter.use(ThrowingPreferences());

      expect(await _storage().read(), ThemeMode.system);
    });

    test(
      'si guardar lanza: no lanza (el tema ya cambió en pantalla)',
      () async {
        SharedPreferencesAsyncPlatformSetter.use(ThrowingPreferences());

        await expectLater(_storage().save(ThemeMode.dark), completes);
      },
    );
  });
}
