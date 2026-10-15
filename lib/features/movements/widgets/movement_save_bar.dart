import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Pie del formulario: «Guardar y agregar otro» y el botón que registra. Con la
/// petición en curso el botón queda apagado y con progreso.
class MovementSaveBar extends StatelessWidget {
  const MovementSaveBar({
    super.key,
    required this.addAnother,
    required this.onAddAnotherChanged,
    required this.loading,
    required this.saveLabel,
    required this.onSave,
    this.saveKey,
  });

  final bool addAnother;
  final ValueChanged<bool> onAddAnotherChanged;
  final bool loading;

  /// Dice qué hace: «Registrar ingreso» / «Registrar gasto».
  final String saveLabel;
  final VoidCallback onSave;

  /// Para saber dónde está el botón en pantalla (de ahí sale la animación).
  final Key? saveKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceMd,
        DesignTokens.spaceSm,
        DesignTokens.spaceMd,
        DesignTokens.spaceMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Guardar y agregar otro',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            value: addAnother,
            onChanged: loading ? null : onAddAnotherChanged,
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          FilledButton(
            key: saveKey,
            onPressed: loading ? null : onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
            ),
            child: loading
                ? const SizedBox.square(
                    dimension: DesignTokens.progressSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'Guardando',
                    ),
                  )
                : Text(saveLabel),
          ),
        ],
      ),
    );
  }
}
