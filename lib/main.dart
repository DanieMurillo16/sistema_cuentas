import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sistema_cuentas/core/services/hidden_prefs_storage.dart';
import 'package:sistema_cuentas/core/services/theme_storage.dart';
import 'package:sistema_cuentas/shared/providers/theme_mode_provider.dart';

// Sin reintentos automáticos: un error (p. ej. sin red al arrancar) se muestra
// y la persona decide con «Intentar nuevamente», en vez de repetir peticiones.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // El tema guardado se lee antes de pintar: sin destello del tema equivocado.
  final theme = await ThemeStorage(SharedPreferencesAsync()).read();
  // Igual con las cifras tapadas: ya leídas, no se ven un instante al abrir.
  final hiddenPrefs = HiddenPrefsStorage(SharedPreferencesAsync.new);
  await hiddenPrefs.load();
  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        initialThemeModeProvider.overrideWithValue(theme),
        hiddenPrefsStorageProvider.overrideWithValue(hiddenPrefs),
      ],
      child: const App(),
    ),
  );
}
