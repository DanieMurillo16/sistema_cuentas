import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:sistema_cuentas/core/config/app_config.dart';
import 'package:sistema_cuentas/core/router/app_router.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/shared/providers/theme_mode_provider.dart';
import 'package:sistema_cuentas/shared/widgets/dismiss_keyboard.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Los colores salen de `AppColors`: se activa la paleta antes de armar el
    // tema y la app se reconstruye entera al cambiarla (por eso la `key`).
    final brightness = ref.watch(effectiveBrightnessProvider);
    AppColors.apply(brightness);
    return MaterialApp.router(
      key: ValueKey(brightness),
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
      // El overlay donde AppToast dibuja los avisos: va por encima de cualquier
      // diálogo. Y dentro de él, DismissKeyboard cierra el teclado al tocar
      // fuera de un campo en cualquier pantalla o diálogo.
      builder: FlutterSmartDialog.init(
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          // Los iconos de la barra de estado y de navegación siguen al tema de
          // la app, no al del teléfono.
          value: _overlayStyle(brightness),
          child: DismissKeyboard(child: child ?? const SizedBox.shrink()),
        ),
      ),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }

  static SystemUiOverlayStyle _overlayStyle(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      // iOS: el brillo del FONDO de la barra (claro = iconos oscuros).
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
    );
  }
}
