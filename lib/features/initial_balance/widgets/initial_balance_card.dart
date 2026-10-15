import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/initial_balance/widgets/initial_balance_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_badge.dart';

/// La invitación de la primera vez en Inicio: registrar con cuánto se empieza.
class InitialBalanceCard extends StatelessWidget {
  const InitialBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CatalogBadge(
                  icon: Icons.savings_outlined,
                  color: AppColors.accent,
                ),
                const SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  child: Text(
                    '¿Con cuánto cuentas hoy?',
                    style: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(
              'Registra lo que tienes en Nequi, Bancolombia, efectivo… o un solo '
              'valor, y todo queda organizado desde el primer día.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            FilledButton.icon(
              onPressed: () => showInitialBalanceDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Registrar saldo inicial'),
            ),
          ],
        ),
      ),
    );
  }
}
