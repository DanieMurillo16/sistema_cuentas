import 'package:flutter/material.dart';
import 'package:sistema_cuentas/features/auth/utils/auth_rules.dart';

/// Campo de contraseña con el ojo para verla u ocultarla.
class LoginPasswordField extends StatefulWidget {
  const LoginPasswordField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  State<LoginPasswordField> createState() => _LoginPasswordFieldState();
}

class _LoginPasswordFieldState extends State<LoginPasswordField> {
  // Estado efímero y visual: permitido con setState.
  var _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: !widget.enabled,
      obscureText: _obscure,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => widget.onSubmitted(),
      maxLength: AuthRules.passwordMaxLength,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        counterText: '',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          ),
        ),
      ),
      validator: AuthRules.validatePassword,
    );
  }
}
