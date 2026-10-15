import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto opcional del formulario (descripción, nota): largo máximo
/// exacto, sin contador y de solo lectura mientras se guarda.
class MovementTextField extends StatelessWidget {
  const MovementTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.maxLength,
    required this.readOnly,
    this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int maxLength;
  final bool readOnly;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      minLines: 1,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
      ),
    );
  }
}
