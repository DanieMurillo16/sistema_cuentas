/// Dinero de la API (`"12500.00"`, texto) → centavos enteros. Nunca `as double`:
/// así sumar muchos importes no acumula error de punto flotante.
int moneyToCents(Object? raw) {
  final text = raw?.toString().trim() ?? '';
  final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,2}))?$').firstMatch(text);
  if (match == null) throw FormatException('Importe inválido: $text');
  final sign = match.group(1) == '-' ? -1 : 1;
  final whole = int.parse(match.group(2)!);
  final cents = int.parse((match.group(3) ?? '').padRight(2, '0'));
  return sign * (whole * 100 + cents);
}

/// Centavos → pesos para mostrar con los formateadores de `currency_formatter`.
double centsToPesos(int cents) => cents / 100;

/// Entero que puede llegar como número o como texto.
int asInt(Object? raw) => raw is num ? raw.toInt() : int.parse(raw.toString());

/// Texto opcional: vacío o ausente es `null`.
String? asOptionalText(Object? raw) {
  final text = raw?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}
