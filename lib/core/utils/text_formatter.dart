/// Presenta textos con inicial mayúscula sin alterar los datos guardados.
String formatDisplayText(String value) {
  final text = value.trim();
  if (text.isEmpty) return text;
  final first = String.fromCharCode(text.runes.first);
  return '${first.toUpperCase()}${text.substring(first.length)}';
}

String displayInitial(String value) {
  final text = formatDisplayText(value);
  return text.isEmpty ? '?' : String.fromCharCode(text.runes.first);
}
