import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';

/// El motivo del cierre: obligatorio, para que el historial cuente qué pasó.
class FinishNoteField extends StatelessWidget {
  const FinishNoteField({
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
      maxLines: 3,
      minLines: 2,
      textCapitalization: TextCapitalization.sentences,
      inputFormatters: [
        LengthLimitingTextInputFormatter(RecurringRules.closingNoteMaxLength),
      ],
      decoration: const InputDecoration(
        labelText: 'Motivo del cierre',
        hintText: 'Ej.: me devolvió el capital',
      ),
      validator: RecurringRules.validateClosingNote,
    );
  }
}
