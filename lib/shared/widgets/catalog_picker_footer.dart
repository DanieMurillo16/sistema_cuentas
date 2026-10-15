import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Pie del selector: el botón «Nueva …» (si se puede crear) y el espacio de la
/// zona segura inferior.
class CatalogPickerFooter extends StatelessWidget {
  const CatalogPickerFooter({
    super.key,
    required this.createLabel,
    required this.onCreate,
  });

  final String createLabel;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onCreate != null) ...[
          const SizedBox(height: DesignTokens.spaceSm),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: Text(createLabel),
          ),
        ],
        SizedBox(
          height: MediaQuery.paddingOf(context).bottom + DesignTokens.spaceMd,
        ),
      ],
    );
  }
}
