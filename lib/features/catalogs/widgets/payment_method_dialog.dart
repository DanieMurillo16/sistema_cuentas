import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/providers/save_catalog_providers.dart';
import 'package:sistema_cuentas/features/catalogs/utils/catalog_rules.dart';
import 'package:sistema_cuentas/shared/utils/listen_save.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/app_switch_tile.dart';

Future<void> showPaymentMethodDialog(
  BuildContext context, {
  PaymentMethod? method,
}) => showDialog<void>(
  context: context,
  builder: (_) => PaymentMethodDialog(method: method),
);

/// Crear o editar un medio de pago (Nequi, Bancolombia, efectivo…).
class PaymentMethodDialog extends ConsumerStatefulWidget {
  const PaymentMethodDialog({super.key, this.method});

  final PaymentMethod? method;

  @override
  ConsumerState<PaymentMethodDialog> createState() =>
      _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends ConsumerState<PaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.method?.name);
  late var _active = widget.method?.active ?? true;

  bool get _editing => widget.method != null;

  @override
  void initState() {
    super.initState();
    listenSave(
      ref,
      savePaymentMethodProvider,
      successMessage: _editing ? 'Medio actualizado' : 'Medio creado',
      onSuccess: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(savePaymentMethodProvider.notifier)
        .save(
          CatalogRules.methodDraft(
            id: widget.method?.id,
            name: _name.text,
            active: _active,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(
      savePaymentMethodProvider.select((s) => s.isLoading),
    );
    return AppFormDialog(
      icon: Icons.account_balance_wallet_outlined,
      title: _editing ? 'Editar medio de pago' : 'Nuevo medio de pago',
      formKey: _formKey,
      loading: loading,
      confirmLabel: 'Guardar',
      onConfirm: _confirm,
      children: [
        TextFormField(
          controller: _name,
          readOnly: loading,
          maxLength: CatalogRules.methodNameMax,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej.: Nequi, Bancolombia, efectivo',
            counterText: '',
          ),
          validator: CatalogRules.validateMethodName,
        ),
        if (_editing)
          AppSwitchTile(
            title: 'Activo',
            value: _active,
            onChanged: loading
                ? null
                : (value) => setState(() => _active = value),
          ),
      ],
    );
  }
}
