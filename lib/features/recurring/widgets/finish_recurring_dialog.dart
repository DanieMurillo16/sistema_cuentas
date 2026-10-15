import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/services/app_toast.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';
import 'package:sistema_cuentas/features/recurring/providers/finish_recurring_provider.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';
import 'package:sistema_cuentas/features/recurring/widgets/finish_recurring_fields.dart';
import 'package:sistema_cuentas/shared/widgets/app_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_actions.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_header.dart';

Future<void> showFinishRecurringDialog(
  BuildContext context,
  RecurringPayment payment,
) => showDialog<void>(
  context: context,
  builder: (_) => FinishRecurringDialog(payment: payment),
);

/// Finalizar un pago recurrente: fecha, motivo y, si aplica, el capital. Es
/// irreversible, así que el botón es rojo y el texto lo dice.
class FinishRecurringDialog extends ConsumerStatefulWidget {
  const FinishRecurringDialog({super.key, required this.payment});

  final RecurringPayment payment;

  @override
  ConsumerState<FinishRecurringDialog> createState() =>
      _FinishRecurringDialogState();
}

class _FinishRecurringDialogState extends ConsumerState<FinishRecurringDialog> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  final _capital = TextEditingController();
  var _endDate = dateOnly(DateTime.now());
  PaymentMethod? _method;

  @override
  void initState() {
    super.initState();
    ref.listenManual(finishRecurringProvider, (previous, next) {
      if (previous?.isLoading != true) return;
      if (next.hasError) {
        AppToast.error(userErrorMessage(next.error));
      } else if (!next.isLoading) {
        AppToast.success('Pago recurrente finalizado');
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _note.dispose();
    _capital.dispose();
    super.dispose();
  }

  void _confirm() {
    final invalidDate = RecurringRules.validateEndDate(
      _endDate,
      today: DateTime.now(),
      start: widget.payment.startDate,
    );
    if (invalidDate != null) {
      AppToast.warning(invalidDate);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(finishRecurringProvider.notifier)
        .finish(
          RecurringRules.buildFinishDraft(
            recurringId: widget.payment.id,
            endDate: _endDate,
            closingNote: _note.text,
            capitalText: _capital.text,
            method: _method,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(
      finishRecurringProvider.select((s) => s.isLoading),
    );
    return PopScope(
      canPop: !loading,
      child: AppDialog(
        header: DialogHeader(
          icon: Icons.flag_outlined,
          color: Theme.of(context).colorScheme.error,
          title: 'Finalizar',
          subtitle: formatDisplayText(widget.payment.description),
          closeEnabled: !loading,
          onClose: () => Navigator.of(context).pop(),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'No se puede deshacer: los meses pendientes quedan omitidos.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: DesignTokens.spaceMd),
              FinishRecurringFields(
                payment: widget.payment,
                note: _note,
                capital: _capital,
                endDate: _endDate,
                method: _method,
                readOnly: loading,
                onDateChanged: (date) => setState(() => _endDate = date),
                onMethodChanged: (method) => setState(() => _method = method),
              ),
            ],
          ),
        ),
        actions: DialogActions(
          confirmLabel: 'Finalizar',
          confirmIcon: Icons.flag_outlined,
          destructive: true,
          isLoading: loading,
          onConfirm: _confirm,
        ),
      ),
    );
  }
}
