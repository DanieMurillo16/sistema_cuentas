String formatCop(num value) {
  final grouped = _groupDigits(value.round().abs().toString());
  final sign = value < 0 ? '-' : '';
  return '$sign\$ $grouped';
}

/// Pesos desde centavos (lo que guardan los modelos): `$ 12.500`.
String formatCents(int cents) => formatCop(cents / 100);

/// Como [formatCopSigned], desde centavos (lo que guardan los modelos).
String formatCentsSigned(int cents) => formatCopSigned(cents / 100);

/// Con signo explícito: `+$ 400.000` (entra) o `-$ 75.000` (sale).
String formatCopSigned(num value) {
  final text = formatCop(value.abs());
  if (value > 0) return '+$text';
  if (value < 0) return '-$text';
  return text;
}

String formatCopInput(num? value) {
  if (value == null) return '';
  return _groupDigits(value.round().abs().toString());
}

double? parseCopInput(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  return digits.isEmpty ? null : double.tryParse(digits);
}

String normalizeCopInput(String value) {
  final parsed = parseCopInput(value);
  return parsed == null ? '' : parsed.round().toString();
}

String formatQuantity(num value) {
  final text = value.toStringAsFixed(3);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

String _groupDigits(String digits) {
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}
