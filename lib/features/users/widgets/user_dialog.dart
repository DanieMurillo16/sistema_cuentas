import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/users/providers/users_provider.dart';
import 'package:sistema_cuentas/features/users/utils/user_rules.dart';
import 'package:sistema_cuentas/features/users/widgets/user_password_field.dart';
import 'package:sistema_cuentas/shared/utils/listen_save.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/app_switch_tile.dart';

Future<void> showUserDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const UserDialog());

/// Dar de alta a otra persona: nombre, usuario, contraseña y si es administrador.
class UserDialog extends ConsumerStatefulWidget {
  const UserDialog({super.key});

  @override
  ConsumerState<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends ConsumerState<UserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  var _isAdmin = false;

  @override
  void initState() {
    super.initState();
    listenSave(
      ref,
      saveUserProvider,
      successMessage: 'Usuario creado',
      onSuccess: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(saveUserProvider.notifier)
        .save(
          UserRules.draft(
            name: _name.text,
            username: _username.text,
            password: _password.text,
            isAdmin: _isAdmin,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(saveUserProvider.select((s) => s.isLoading));
    return AppFormDialog(
      icon: Icons.person_add_alt_outlined,
      title: 'Nuevo usuario',
      subtitle: 'Cada persona ve solo lo suyo',
      formKey: _formKey,
      loading: loading,
      confirmLabel: 'Crear usuario',
      onConfirm: _confirm,
      children: [
        TextFormField(
          controller: _name,
          readOnly: loading,
          maxLength: UserRules.nameMax,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            counterText: '',
          ),
          validator: UserRules.validateName,
        ),
        // Cada uno en su fila: «Contraseña» con el ojo no cabe en media fila
        // de un teléfono y los dos campos quedaban a distinta altura.
        TextFormField(
          controller: _username,
          readOnly: loading,
          maxLength: UserRules.usernameMax,
          autocorrect: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._-]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Usuario',
            helperText: 'Minúsculas, números, punto, guion y guion bajo',
            helperMaxLines: 2,
            prefixIcon: Icon(Icons.alternate_email_rounded),
            counterText: '',
          ),
          validator: UserRules.validateUsername,
        ),
        UserPasswordField(controller: _password, readOnly: loading),
        AppSwitchTile(
          title: 'Administrador',
          subtitle: 'Puede dar de alta a otras personas',
          value: _isAdmin,
          onChanged: loading
              ? null
              : (value) => setState(() => _isAdmin = value),
        ),
      ],
    );
  }
}
