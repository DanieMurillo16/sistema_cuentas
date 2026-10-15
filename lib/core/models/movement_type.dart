/// Ingreso (me pagan) o gasto (yo pago). Lo usan movimientos, categorías y
/// pagos recurrentes, por eso vive en `core/models`.
enum MovementType {
  income('INGRESO', 'income'),
  expense('GASTO', 'expense');

  const MovementType(this.apiValue, this.routeName);

  /// Valor que usa la API (`tipo`).
  final String apiValue;

  /// Valor que se usa en la ruta (`/movements/income`).
  final String routeName;

  bool get isIncome => this == income;

  /// Lanza `FormatException` (que `parseApi` traduce a un error en español) si
  /// el servidor manda un tipo ausente o desconocido.
  static MovementType fromApi(Object? raw) => values.firstWhere(
    (type) => type.apiValue == raw,
    orElse: () => throw FormatException('Tipo de movimiento inválido: $raw'),
  );

  static MovementType? tryFromRoute(String? raw) {
    for (final type in values) {
      if (type.routeName == raw) return type;
    }
    return null;
  }
}
