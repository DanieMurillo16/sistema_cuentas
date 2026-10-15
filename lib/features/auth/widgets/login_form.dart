import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/services/app_toast.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/auth/providers/login_provider.dart';
import 'package:sistema_cuentas/features/auth/utils/auth_rules.dart';
import 'package:sistema_cuentas/features/auth/widgets/login_password_field.dart';
import 'package:sistema_cuentas/features/auth/widgets/login_submit_button.dart';

/// Usuario, contraseña y botón. El error del servidor llega como aviso.
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  // Estado efímero y visual: permitido con setState.
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(loginProvider.notifier)
        .signIn(username: _username.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(loginProvider.select((s) => s.isLoading));
    ref.listen(loginProvider, (previous, next) {
      if (next.hasError && previous?.isLoading == true) {
        AppToast.error(userErrorMessage(next.error));
      }
    });

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _username,
              readOnly: loading,
              autofillHints: const [AutofillHints.username],
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: AuthRules.usernameMaxLength,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              decoration: const InputDecoration(
                labelText: 'Usuario',
                counterText: '',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: AuthRules.validateUsername,
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            LoginPasswordField(
              controller: _password,
              enabled: !loading,
              onSubmitted: _submit,
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            LoginSubmitButton(loading: loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
