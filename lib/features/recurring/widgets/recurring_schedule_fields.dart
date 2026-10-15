import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_pickers.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_pair.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_pick_card.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_option.dart';

/// Cada cuántos meses y desde cuándo: dos tarjetas en pareja. La primera abre
/// su selector desde abajo; la segunda, el calendario.
class RecurringScheduleFields extends StatelessWidget {
  const RecurringScheduleFields({
    super.key,
    required this.everyMonths,
    required this.startDate,
    required this.onEveryMonthsChanged,
    required this.onStartDateChanged,
    required this.enabled,
  });

  final int everyMonths;
  final DateTime startDate;
  final ValueChanged<int?> onEveryMonthsChanged;
  final ValueChanged<DateTime> onStartDateChanged;
  final bool enabled;

  Future<void> _pickDate(BuildContext context) async {
    final last = DateTime(DateTime.now().year + 2);
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate.isAfter(last) ? last : startDate,
      firstDate: DateTime(2000),
      lastDate: last,
    );
    if (picked != null) onStartDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormPair(
      minWidth: DesignTokens.formDatePairMinWidth,
      equalHeight: true,
      first: CatalogPickCard(
        label: 'Se repite',
        placeholderIcon: Icons.event_repeat_rounded,
        selected: cadenceOption(everyMonths),
        onTap: () async {
          if (!enabled) return;
          final picked = await pickCadence(context, selected: everyMonths);
          if (picked != null) onEveryMonthsChanged(picked);
        },
      ),
      second: CatalogPickCard(
        label: 'Desde',
        placeholderIcon: Icons.calendar_today_outlined,
        selected: CatalogPickerOption<DateTime>(
          value: startDate,
          label: formatDate(startDate),
          icon: Icons.calendar_today_outlined,
          color: AppColors.accent,
        ),
        onTap: () {
          if (enabled) _pickDate(context);
        },
      ),
    );
  }
}
