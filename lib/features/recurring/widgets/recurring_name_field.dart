import 'package:flutter/material.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';

/// El nombre del acuerdo («Arriendo de Oscar», «Netflix»).
class RecurringNameField extends StatelessWidget {
  const RecurringNameField({
    super.key,
    required this.controller,
    required this.readOnly,
  });

  final TextEditingController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLength: RecurringRules.descriptionMaxLength,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Nombre',
        hintText: 'Ej.: Arriendo de Oscar, Netflix',
        counterText: '',
      ),
      validator: RecurringRules.validateDescription,
    );
  }
}
