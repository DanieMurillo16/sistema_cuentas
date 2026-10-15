import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/settings/widgets/reset_data_dialog.dart';
import 'package:sistema_cuentas/features/settings/widgets/settings_tile.dart';

/// Ajustes → Mis datos: empezar de cero (borra todo lo de la persona, no su
/// usuario).
class SettingsDataSection extends StatelessWidget {
  const SettingsDataSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Mis datos', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: DesignTokens.spaceSm),
        SettingsTile(
          icon: Icons.delete_sweep_outlined,
          title: 'Eliminar datos',
          subtitle: 'Empezar desde cero; tu usuario se conserva',
          destructive: true,
          onTap: () => showResetDataDialog(context),
        ),
      ],
    );
  }
}
