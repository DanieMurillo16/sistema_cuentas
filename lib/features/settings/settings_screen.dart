import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/settings/widgets/logout_button.dart';
import 'package:sistema_cuentas/features/settings/widgets/settings_catalog_section.dart';
import 'package:sistema_cuentas/features/settings/widgets/settings_data_section.dart';
import 'package:sistema_cuentas/features/settings/widgets/settings_profile_card.dart';
import 'package:sistema_cuentas/features/settings/widgets/settings_tile.dart';
import 'package:sistema_cuentas/features/settings/utils/theme_options.dart';
import 'package:sistema_cuentas/shared/providers/permission_provider.dart';
import 'package:sistema_cuentas/shared/providers/theme_mode_provider.dart';

/// Ajustes: la cuenta, los catálogos (categorías, medios de pago, contactos),
/// los usuarios (solo administrador), «Eliminar datos» (empezar de cero) y
/// cerrar sesión.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(hasPermissionProvider(Permissions.manageUsers));
    final textTheme = Theme.of(context).textTheme;
    final list = ListView(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spaceMd,
        DesignTokens.spaceMd,
        DesignTokens.spaceMd,
        MediaQuery.paddingOf(context).bottom + DesignTokens.spaceXl,
      ),
      children: [
        const SettingsProfileCard(),
        const SizedBox(height: DesignTokens.spaceLg),
        Text('Apariencia', style: textTheme.titleSmall),
        const SizedBox(height: DesignTokens.spaceSm),
        SettingsTile(
          icon: Icons.brightness_6_outlined,
          title: 'Tema',
          subtitle: ref.watch(themeModeProvider).label,
          onTap: () => context.push(AppRoutes.settingsTheme),
        ),
        const SizedBox(height: DesignTokens.spaceLg),
        const SettingsCatalogSection(),
        if (isAdmin) ...[
          const SizedBox(height: DesignTokens.spaceLg),
          Text('Administración', style: textTheme.titleSmall),
          const SizedBox(height: DesignTokens.spaceSm),
          SettingsTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Usuarios',
            subtitle: 'Quién tiene acceso a la app',
            onTap: () => context.push(AppRoutes.settingsUsers),
          ),
        ],
        const SizedBox(height: DesignTokens.spaceLg),
        const SettingsDataSection(),
        const SizedBox(height: DesignTokens.spaceXl),
        const LogoutButton(),
      ],
    );
    // Sin tope de ancho las tarjetas se estirarían a 1200 px.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DesignTokens.formMaxWidth),
        child: list,
      ),
    );
  }
}
