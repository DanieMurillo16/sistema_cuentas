import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/services/app_toast.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_body.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/features/recurring/providers/save_recurring_provider.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_amount_fields.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_catalog_fields.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_extra_fields.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_name_field.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_schedule_fields.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_submit_button.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_type_toggle.dart';

/// Formulario de un pago recurrente nuevo. Solo guarda lo que se va escribiendo
/// y eligiendo; armar el envío es de `RecurringRules` y guardar de
/// `saveRecurringProvider`.
class RecurringForm extends ConsumerStatefulWidget {
  const RecurringForm({super.key});

  @override
  ConsumerState<RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<RecurringForm> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _value = TextEditingController();
  final _day = TextEditingController();
  final _capital = TextEditingController();
  var _type = MovementType.income;
  var _everyMonths = 1;
  var _startDate = dateOnly(DateTime.now());
  Category? _category;
  Contact? _contact;

  @override
  void initState() {
    super.initState();
    ref.listenManual(saveRecurringProvider, (previous, next) {
      if (previous?.isLoading != true) return;
      if (next.hasError) {
        AppToast.error(userErrorMessage(next.error));
      } else if (!next.isLoading) {
        AppToast.success('Pago recurrente creado');
        if (mounted) {
          context.canPop() ? context.pop() : context.go(AppRoutes.recurring);
        }
      }
    });
  }

  @override
  void dispose() {
    for (final controller in [_description, _value, _day, _capital]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _changeType(MovementType type) => setState(() {
    _type = type;
    _category = null; // cada tipo tiene sus propias categorías
  });

  void _setEveryMonths(int? value) => setState(() => _everyMonths = value ?? 1);

  void _setStartDate(DateTime date) => setState(() => _startDate = date);

  void _setCategory(Category? value) => setState(() => _category = value);

  void _setContact(Contact? value) => setState(() => _contact = value);

  void _save() {
    final missing = RecurringRules.validateCategory(_category);
    if (missing != null) AppToast.warning(missing);
    if (!_formKey.currentState!.validate() || missing != null) return;
    ref
        .read(saveRecurringProvider.notifier)
        .save(
          RecurringRules.buildDraft(
            type: _type,
            description: _description.text,
            valueText: _value.text,
            dayText: _day.text,
            everyMonths: _everyMonths,
            startDate: _startDate,
            category: _category!,
            contact: _contact,
            capitalText: _capital.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(saveRecurringProvider.select((s) => s.isLoading));
    return PopScope(
      canPop: !loading,
      child: Column(
        children: [
          AppFormBody(
            formKey: _formKey,
            children: [
              RecurringTypeToggle(
                type: _type,
                onChanged: _changeType,
                enabled: !loading,
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              RecurringNameField(controller: _description, readOnly: loading),
              const SizedBox(height: DesignTokens.spaceMd),
              RecurringAmountFields(
                value: _value,
                day: _day,
                readOnly: loading,
              ),
              const SizedBox(height: DesignTokens.spaceMd),
              RecurringScheduleFields(
                everyMonths: _everyMonths,
                startDate: _startDate,
                enabled: !loading,
                onEveryMonthsChanged: _setEveryMonths,
                onStartDateChanged: _setStartDate,
              ),
              const SizedBox(height: DesignTokens.spaceMd),
              RecurringCatalogFields(
                type: _type,
                category: _category,
                contact: _contact,
                onCategoryChanged: _setCategory,
                onContactChanged: _setContact,
              ),
              const SizedBox(height: DesignTokens.spaceMd),
              RecurringExtraFields(capital: _capital, readOnly: loading),
            ],
          ),
          RecurringSubmitButton(loading: loading, onPressed: _save),
        ],
      ),
    );
  }
}
