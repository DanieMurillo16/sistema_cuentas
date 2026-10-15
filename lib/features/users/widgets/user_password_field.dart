import 'package:flutter/material.dart';
import 'package:sistema_cuentas/features/users/utils/user_rules.dart';

/// Contraseña de un usuario nuevo, con el ojo para verla u ocultarla.
class UserPasswordField extends StatefulWidget {
  const UserPasswordField({
    super.key,
    required this.controller,
    required this.readOnly,
  });

  final TextEditingController controller;
  final bool readOnly;

  @override
  State<UserPasswordField> createState() => _UserPasswordFieldState();
}

class _UserPasswordFieldState extends State<UserPasswordField> {
  // Estado efímero y visual: permitido con setState.
  var _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: widget.readOnly,
      obscureText: _obscure,
      maxLength: UserRules.passwordMax,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        helperText: 'Mínimo ${UserRules.passwordMin} caracteres',
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        counterText: '',
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Mostrar' : 'Ocultar',
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          ),
        ),
      ),
      validator: UserRules.validatePassword,
    );
  }
}
