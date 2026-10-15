import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/services/app_toast.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/providers/pay_due_provider.dart';
import 'package:sistema_cuentas/features/dues/utils/dues_rules.dart';
import 'package:sistema_cuentas/features/dues/widgets/pay_due_fields.dart';
import 'package:sistema_cuentas/shared/widgets/app_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_actions.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_header.dart';

Future<void> showPayDueDialog(BuildContext context, Due due) =>
    showDialog<void>(
      context: context,
      builder: (_) => PayDueDialog(due: due),
    );

/// Registrar un pago o abono de un vencimiento. Solo guarda lo que se va
/// escribiendo; armar el envío es de `DuesRules` y guardar de `payDueProvider`.
class PayDueDialog extends ConsumerStatefulWidget {
  const PayDueDialog({super.key, required this.due});

  final Due due;

  @override
  ConsumerState<PayDueDialog> createState() => _PayDueDialogState();
}

class _PayDueDialogState extends ConsumerState<PayDueDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: formatCopInput(centsToPesos(widget.due.balanceCents)),
  );
  final _note = TextEditingController();
  var _date = dateOnly(DateTime.now());
  PaymentMethod? _method;

  @override
  void initState() {
    super.initState();
    ref.listenManual(payDueProvider, (previous, next) {
      if (previous?.isLoading != true) return;
      if (next.hasError) {
        AppToast.error(userErrorMessage(next.error));
      } else if (!next.isLoading) {
        AppToast.success(
          widget.due.isIncome ? 'Cobro registrado' : 'Pago registrado',
        );
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _confirm() {
    final missing = DuesRules.validatePaymentMethod(_method);
    if (!_formKey.currentState!.validate() || missing != null) return;
    ref
        .read(payDueProvider.notifier)
        .pay(
          DuesRules.buildDraft(
            due: widget.due,
            amountText: _amount.text,
            date: _date,
            method: _method!,
            note: _note.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(payDueProvider.select((s) => s.isLoading));
    final due = widget.due;
    return PopScope(
      canPop: !loading,
      child: AppDialog(
        header: DialogHeader(
          icon: due.isIncome
              ? Icons.south_west_rounded
              : Icons.north_east_rounded,
          color: due.isIncome ? AppColors.income : AppColors.expense,
          title: DuesRules.confirmLabel(due),
          subtitle: DuesRules.payDialogSubtitle(due),
          closeEnabled: !loading,
          onClose: () => Navigator.of(context).pop(),
        ),
        content: Form(
          key: _formKey,
          child: PayDueFields(
            due: due,
            amount: _amount,
            note: _note,
            date: _date,
            method: _method,
            readOnly: loading,
            onDateChanged: (date) => setState(() => _date = date),
            onMethodChanged: (method) => setState(() => _method = method),
          ),
        ),
        actions: DialogActions(
          confirmLabel: DuesRules.confirmLabel(due),
          confirmIcon: Icons.check_rounded,
          isLoading: loading,
          onConfirm: _confirm,
        ),
      ),
    );
  }
}
