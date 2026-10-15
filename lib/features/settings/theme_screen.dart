import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/settings/utils/theme_options.dart';
import 'package:sistema_cuentas/features/settings/widgets/theme_option_tile.dart';
import 'package:sistema_cuentas/shared/providers/theme_mode_provider.dart';
import 'package:sistema_cuentas/shared/widgets/app_sub_screen_bar.dart';

/// Ajustes → Tema: claro, oscuro o automático. Se aplica al tocar y se recuerda
/// en este teléfono.
/// pantalla → themeModeProvider → ThemeStorage (preferencias del dispositivo)
class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: const AppSubScreenBar(
        title: 'Tema',
        fallbackPath: AppRoutes.settings,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DesignTokens.formMaxWidth,
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(DesignTokens.spaceMd),
              itemCount: themeOptions.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: DesignTokens.spaceSm),
              itemBuilder: (context, index) {
                final mode = themeOptions[index];
                return ThemeOptionTile(
                  key: ValueKey('theme-${mode.name}'),
                  mode: mode,
                  selected: mode == selected,
                  onTap: () => ref.read(themeModeProvider.notifier).set(mode),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
