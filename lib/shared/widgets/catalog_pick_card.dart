import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_pick_card_body.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_option.dart';

/// Tarjeta de un formulario que abre un selector (categoría, medio de pago,
/// contacto…). Vacía muestra [placeholder] («Elegir»); con algo elegido, su icono y nombre. Si [validator]
/// devuelve un texto, lo muestra debajo.
class CatalogPickCard extends StatelessWidget {
  const CatalogPickCard({
    super.key,
    required this.label,
    required this.placeholderIcon,
    required this.selected,
    required this.onTap,
    this.validator,
    this.placeholder = 'Elegir',
    this.onClear,
  });

  final String label;
  final IconData placeholderIcon;
  final CatalogPickerOption<Object>? selected;
  final VoidCallback onTap;
  final String? Function()? validator;
  final String placeholder;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    // La llave por elección vuelve a validar al elegir: el error se va solo.
    return FormField<Object>(
      key: ValueKey(selected?.label),
      validator: (_) => validator?.call(),
      builder: (field) => Semantics(
        button: true,
        onTap: onTap,
        label: selected == null
            ? label
            : '$label, ${formatDisplayText(selected!.label)}',
        excludeSemantics: true,
        child: CatalogPickCardBody(
          label: label,
          placeholderIcon: placeholderIcon,
          selected: selected,
          errorText: field.errorText,
          onTap: onTap,
          placeholder: placeholder,
          onClear: onClear,
        ),
      ),
    );
  }
}
