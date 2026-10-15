String formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String apiDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String formatDateTime(DateTime value) =>
    '${formatDate(value)} ${formatTime(value)}';

String apiDateTime(DateTime value) =>
    '${apiDate(value)} ${formatTime(value)}:${value.second.toString().padLeft(2, '0')}';

const _monthAbbreviations = [
  'ENE',
  'FEB',
  'MAR',
  'ABR',
  'MAY',
  'JUN',
  'JUL',
  'AGO',
  'SEP',
  'OCT',
  'NOV',
  'DIC',
];

/// «OCT DE 2026»: el mes del selector de la cabecera.
String formatMonthYear(DateTime value) =>
    '${_monthAbbreviations[value.month - 1]} DE ${value.year}';

/// `AAAA-MM`: el `periodo` que la API recibe para un mes completo.
String apiPeriod(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  return '${value.year}-$month';
}

const _weekdays = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const _monthNames = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// `AAAA-MM-DD` (lo que manda la API) → fecha sin hora.
DateTime parseApiDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) throw FormatException('Fecha inválida: $value');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2].substring(0, 2)),
  );
}

/// `AAAA-MM-DD HH:MM:SS` (la hora de Colombia que manda la API) → fecha y
/// hora. `null` si falta o no se entiende: la hora es un extra, nunca un error.
DateTime? parseApiDateTime(Object? raw) {
  if (raw is! String || raw.trim().isEmpty) return null;
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?',
  ).firstMatch(raw.trim());
  if (match == null) return null;
  int part(int i) => int.parse(match.group(i) ?? '0');
  return DateTime(part(1), part(2), part(3), part(4), part(5), part(6));
}

/// La hora como se lee en Colombia: «3:45 p. m.».
String formatClock(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${value.hour < 12 ? 'a. m.' : 'p. m.'}';
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Último día del mes de [month].
DateTime lastDayOfMonth(DateTime month) =>
    DateTime(month.year, month.month + 1, 0);

/// «Hoy», «Ayer» o «Domingo, 11 Oct.» (encabezado de un día del historial).
String formatDayHeader(DateTime date, DateTime today) {
  final days = dateOnly(today).difference(dateOnly(date)).inDays;
  if (days == 0) return 'Hoy';
  if (days == 1) return 'Ayer';
  final month = _monthAbbreviations[date.month - 1];
  final abbreviation = '${month[0]}${month.substring(1).toLowerCase()}.';
  return '${_weekdays[date.weekday - 1]}, ${date.day} $abbreviation';
}

/// «martes, 13 de octubre de 2026» (la píldora de fecha del formulario).
String formatLongDate(DateTime date) =>
    '${_weekdays[date.weekday - 1].toLowerCase()}, ${date.day} de '
    '${_monthNames[date.month - 1]} de ${date.year}';

/// «7 oct.»: día y mes abreviado, para una fecha de vencimiento.
String formatShortDate(DateTime date) {
  final month = _monthAbbreviations[date.month - 1].toLowerCase();
  return '${date.day} $month.';
}

/// «Octubre 2026»: el mes de un vencimiento del historial.
String formatMonthName(DateTime date) {
  final name = _monthNames[date.month - 1];
  return '${name[0].toUpperCase()}${name.substring(1)} ${date.year}';
}

/// «Oct»: el mes en tres letras, para el eje de una gráfica.
String formatMonthShort(DateTime date) {
  final month = _monthAbbreviations[date.month - 1];
  return '${month[0]}${month.substring(1).toLowerCase()}';
}

/// Primer día del mes que está [offset] meses antes (o después, si es negativo)
/// del de [month].
DateTime monthsBefore(DateTime month, int offset) =>
    DateTime(month.year, month.month - offset);

/// «octubre de 2026»: el mes de una lista o un título.
String formatMonthLong(DateTime date) =>
    '${_monthNames[date.month - 1]} de ${date.year}';
