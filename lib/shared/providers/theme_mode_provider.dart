import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/services/theme_storage.dart';

/// El tema guardado al abrir la app (se lee antes del primer cuadro, en
/// `main`); así no hay un destello del tema equivocado.
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

/// El tema que eligió la persona: claro, oscuro o automático (el del teléfono).
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(initialThemeModeProvider);

  /// Cambia el tema ya y lo recuerda en este dispositivo.
  Future<void> set(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await ref.read(themeStorageProvider).save(mode);
  }
}

/// El brillo que tiene el teléfono ahora; cambia solo si la persona cambia el
/// modo oscuro del sistema con la app abierta.
final platformBrightnessProvider =
    NotifierProvider<PlatformBrightnessNotifier, Brightness>(
      PlatformBrightnessNotifier.new,
    );

class PlatformBrightnessNotifier extends Notifier<Brightness>
    with WidgetsBindingObserver {
  @override
  Brightness build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void didChangePlatformBrightness() {
    state = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }
}

/// Claro u oscuro, ya resuelto: el elegido o, en automático, el del teléfono.
final effectiveBrightnessProvider = Provider<Brightness>((ref) {
  return switch (ref.watch(themeModeProvider)) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => ref.watch(platformBrightnessProvider),
  };
});
