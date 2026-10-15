import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/services/app_toast.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/providers/payment_methods_provider.dart';
import 'package:sistema_cuentas/features/initial_balance/models/initial_balance_entry.dart';
import 'package:sistema_cuentas/features/initial_balance/providers/save_initial_balance_provider.dart';
import 'package:sistema_cuentas/features/initial_balance/utils/initial_balance_rules.dart';
import 'package:sistema_cuentas/features/initial_balance/widgets/initial_balance_method_fields.dart';
import 'package:sistema_cuentas/features/initial_balance/widgets/initial_balance_no_methods.dart';
import 'package:sistema_cuentas/features/initial_balance/widgets/initial_balance_single_fields.dart';
import 'package:sistema_cuentas/features/initial_balance/widgets/initial_balance_total.dart';
import 'package:sistema_cuentas/shared/utils/listen_save.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/app_retry_message.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle_option.dart';

Future<void> showInitialBalanceDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const InitialBalanceDialog(),
);

/// «¿Con cuánto cuentas hoy?»: el saldo con el que se empieza, repartido por
/// medio de pago (Nequi, Bancolombia, efectivo…) o en un solo valor. Solo guarda
/// lo que se escribe; armar los ingresos es de `InitialBalanceRules` y guardar de
/// `saveInitialBalanceProvider`.
class InitialBalanceDialog extends ConsumerStatefulWidget {
  const InitialBalanceDialog({super.key});

  @override
  ConsumerState<InitialBalanceDialog> createState() =>
      _InitialBalanceDialogState();
}

class _InitialBalanceDialogState extends ConsumerState<InitialBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <int, TextEditingController>{};
  final _single = TextEditingController();
  var _mode = InitialBalanceMode.byMethod;
  PaymentMethod? _singleMethod;

  @override
  void initState() {
    super.initState();
    listenSave(
      ref,
      saveInitialBalanceProvider,
      successMessage: 'Saldo inicial registrado',
      onSuccess: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _single.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  List<InitialBalanceEntry> _entries(List<PaymentMethod> methods) =>
      _mode == InitialBalanceMode.byMethod
      ? InitialBalanceRules.entriesByMethod(
          methods: methods,
          texts: {for (final e in _controllers.entries) e.key: e.value.text},
        )
      : InitialBalanceRules.entriesSingle(
          text: _single.text,
          method: _singleMethod,
        );

  void _confirm(List<PaymentMethod> methods) {
    if (!_formKey.currentState!.validate()) return;
    final entries = _entries(methods);
    if (entries.isEmpty) {
      AppToast.warning('Escribe al menos un valor.');
      return;
    }
    ref.read(saveInitialBalanceProvider.notifier).save(entries);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(
      saveInitialBalanceProvider.select((s) => s.isLoading),
    );
    final methods = ref.watch(activePaymentMethodsProvider);
    final list = methods.value ?? const <PaymentMethod>[];
    for (final method in list) {
      _controllers.putIfAbsent(method.id, TextEditingController.new);
    }
    return AppFormDialog(
      icon: Icons.savings_outlined,
      title: 'Saldo inicial',
      subtitle: '¿Con cuánto cuentas hoy?',
      formKey: _formKey,
      loading: loading,
      confirmLabel: 'Guardar saldo',
      onConfirm: () => _confirm(list),
      children: [
        AppToggle<InitialBalanceMode>(
          selected: _mode,
          enabled: !loading,
          onSelected: (mode) => setState(() => _mode = mode),
          options: [
            for (final mode in InitialBalanceMode.values)
              AppToggleOption(value: mode, label: mode.label),
          ],
        ),
        if (methods.hasError && !methods.hasValue)
          AppRetryMessage(
            text: userErrorMessage(methods.error),
            onRetry: () => ref.invalidate(paymentMethodsProvider),
          )
        else if (!methods.hasValue)
          const LinearProgressIndicator()
        else if (list.isEmpty)
          const InitialBalanceNoMethods()
        else if (_mode == InitialBalanceMode.byMethod)
          InitialBalanceMethodFields(
            methods: list,
            controllers: _controllers,
            readOnly: loading,
            onChanged: _refresh,
          )
        else
          InitialBalanceSingleFields(
            controller: _single,
            method: _singleMethod,
            readOnly: loading,
            onChanged: _refresh,
            onMethodChanged: (method) => setState(() => _singleMethod = method),
          ),
        InitialBalanceTotal(
          pesos: _mode == InitialBalanceMode.single
              ? InitialBalanceRules.pesosOf(_single.text)
              : InitialBalanceRules.totalPesos(_entries(list)),
        ),
      ],
    );
  }
}
