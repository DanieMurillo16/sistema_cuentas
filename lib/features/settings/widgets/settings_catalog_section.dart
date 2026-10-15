import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/initial_balance/widgets/initial_balance_dialog.dart';
import 'package:sistema_cuentas/features/settings/widgets/settings_tile.dart';
import 'package:sistema_cuentas/shared/providers/permission_provider.dart';

/// Ajustes → Catálogos: categorías, medios de pago y contactos.
class SettingsCatalogSection extends ConsumerWidget {
  const SettingsCatalogSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canRegister = ref.watch(
      hasPermissionProvider(Permissions.registerMovements),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Catálogos', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: DesignTokens.spaceSm),
        SettingsTile(
          icon: Icons.sell_outlined,
          title: 'Categorías',
          subtitle: 'Cómo clasificas tus ingresos y gastos',
          onTap: () => context.push(AppRoutes.settingsCategories),
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        SettingsTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Medios de pago',
          subtitle: 'Nequi, Bancolombia, efectivo…',
          onTap: () => context.push(AppRoutes.settingsMethods),
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        SettingsTile(
          icon: Icons.contacts_outlined,
          title: 'Contactos',
          subtitle: 'Quién te paga y a quién le pagas',
          onTap: () => context.push(AppRoutes.settingsContacts),
        ),
        if (canRegister) ...[
          const SizedBox(height: DesignTokens.spaceSm),
          SettingsTile(
            icon: Icons.savings_outlined,
            title: 'Saldo inicial',
            subtitle: 'Con cuánto cuentas hoy, por medio de pago',
            onTap: () => showInitialBalanceDialog(context),
          ),
        ],
      ],
    );
  }
}
