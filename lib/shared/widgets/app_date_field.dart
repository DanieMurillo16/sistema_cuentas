import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';

/// Campo de fecha: se ve como los demás campos y al tocarlo abre el
/// calendario. El rango elegible lo decide quien lo usa (una regla de negocio).
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.date,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final DateTime date;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final initial = date.isAfter(lastDate)
        ? lastDate
        : (date.isBefore(firstDate) ? firstDate : date);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: ${formatLongDate(date)}. Toca para cambiarla',
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? () => _pick(context) : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(formatDate(date)),
        ),
      ),
    );
  }
}
