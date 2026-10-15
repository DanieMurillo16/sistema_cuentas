import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/services/theme_storage.dart';
import 'package:sistema_cuentas/shared/providers/theme_mode_provider.dart';

import '../../support/fake_theme_storage.dart';

ProviderContainer _container(
  FakeThemeStorage storage, {
  ThemeMode initial = ThemeMode.system,
}) {
  final container = ProviderContainer(
    overrides: [
      themeStorageProvider.overrideWithValue(storage),
      initialThemeModeProvider.overrideWithValue(initial),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('themeModeProvider', () {
    test('sin tema guardado empieza en automático', () {
      final container = ProviderContainer(
        overrides: [themeStorageProvider.overrideWithValue(FakeThemeStorage())],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('empieza con el tema que se leyó al abrir la app', () {
      for (final mode in ThemeMode.values) {
        expect(
          _container(
            FakeThemeStorage(mode),
            initial: mode,
          ).read(themeModeProvider),
          mode,
        );
      }
    });

    test('set cambia el tema y lo guarda', () async {
      final storage = FakeThemeStorage();
      final container = _container(storage);

      await container.read(themeModeProvider.notifier).set(ThemeMode.dark);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(storage.saved, [ThemeMode.dark]);
      expect(storage.stored, ThemeMode.dark);
    });

    test('el cambio se ve ANTES de que termine de guardar', () async {
      final storage = FakeThemeStorage();
      final container = _container(storage);

      final saving = container
          .read(themeModeProvider.notifier)
          .set(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.light);
      await saving;
    });

    test('elegir el que ya está no guarda otra vez', () async {
      final storage = FakeThemeStorage(ThemeMode.dark);
      final container = _container(storage, initial: ThemeMode.dark);

      await container.read(themeModeProvider.notifier).set(ThemeMode.dark);

      expect(storage.saved, isEmpty);
    });

    test('recorre los tres modos y guarda cada uno', () async {
      final storage = FakeThemeStorage();
      final container = _container(storage);
      final notifier = container.read(themeModeProvider.notifier);

      await notifier.set(ThemeMode.light);
      await notifier.set(ThemeMode.dark);
      await notifier.set(ThemeMode.system);

      expect(storage.saved, [
        ThemeMode.light,
        ThemeMode.dark,
        ThemeMode.system,
      ]);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('avisa a quien escucha en cada cambio', () async {
      final container = _container(FakeThemeStorage());
      final seen = <ThemeMode>[];
      container.listen(themeModeProvider, (_, next) => seen.add(next));

      await container.read(themeModeProvider.notifier).set(ThemeMode.light);
      await container.read(themeModeProvider.notifier).set(ThemeMode.dark);

      expect(seen, [ThemeMode.light, ThemeMode.dark]);
    });
  });

  group('effectiveBrightnessProvider', () {
    testWidgets('claro y oscuro mandan sobre el teléfono', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final container = _container(
        FakeThemeStorage(),
        initial: ThemeMode.light,
      );

      expect(container.read(effectiveBrightnessProvider), Brightness.light);

      await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pump();

      expect(container.read(effectiveBrightnessProvider), Brightness.dark);
    });

    testWidgets('automático sigue al teléfono', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final container = _container(FakeThemeStorage());
      expect(container.read(effectiveBrightnessProvider), Brightness.dark);

      final other = _container(FakeThemeStorage());
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      expect(other.read(platformBrightnessProvider), Brightness.light);
    });

    testWidgets('si el teléfono cambia con la app abierta, automático lo '
        'sigue', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final container = _container(FakeThemeStorage());
      expect(container.read(effectiveBrightnessProvider), Brightness.light);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pump();
      expect(container.read(effectiveBrightnessProvider), Brightness.dark);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pump();
      expect(container.read(effectiveBrightnessProvider), Brightness.light);
    });

    testWidgets('el cambio del teléfono no mueve un tema fijo', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final container = _container(
        FakeThemeStorage(ThemeMode.light),
        initial: ThemeMode.light,
      );
      final seen = <Brightness>[];
      container.listen(
        effectiveBrightnessProvider,
        (_, next) => seen.add(next),
      );

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pump();

      expect(container.read(effectiveBrightnessProvider), Brightness.light);
      expect(seen, isEmpty);
    });

    testWidgets('pasar de fijo a automático adopta el brillo del teléfono', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final container = _container(
        FakeThemeStorage(ThemeMode.light),
        initial: ThemeMode.light,
      );
      expect(container.read(effectiveBrightnessProvider), Brightness.light);

      await container.read(themeModeProvider.notifier).set(ThemeMode.system);

      expect(container.read(effectiveBrightnessProvider), Brightness.dark);
    });

    testWidgets('al soltar el provider se deja de observar la plataforma', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final container = ProviderContainer(
        overrides: [themeStorageProvider.overrideWithValue(FakeThemeStorage())],
      );
      container.read(platformBrightnessProvider);

      container.dispose();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
