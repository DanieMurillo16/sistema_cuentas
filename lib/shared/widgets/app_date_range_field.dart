import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';

/// Campo de rango de fechas: se ve como los demás campos y al tocarlo abre el
/// calendario para elegir desde y hasta. El rango elegible lo decide quien lo
/// usa (una regla de negocio).
class AppDateRangeField extends StatelessWidget {
  const AppDateRangeField({
    super.key,
    required this.label,
    required this.range,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  final String label;
  final DateTimeRange range;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTimeRange> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: range,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final text = '${formatDate(range.start)} – ${formatDate(range.end)}';
    return Semantics(
      button: true,
      label: '$label: $text. Toca para cambiarlo',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _pick(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.date_range_outlined),
          ),
          child: Text(text),
        ),
      ),
    );
  }
}
