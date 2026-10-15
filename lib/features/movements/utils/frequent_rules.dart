/// Cuáles son las opciones «frecuentes» del selector (reglas puras).
abstract final class FrequentRules {
  /// Cuántas se muestran como máximo.
  static const limit = 4;

  /// Los [limit] ids más repetidos en [ids], el más usado primero. Con igual
  /// uso, el que apareció antes (el movimiento más reciente de la lista).
  static List<int> topIds(
    Iterable<int> ids, {
    int limit = FrequentRules.limit,
  }) {
    final counts = <int, int>{};
    for (final id in ids) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final ordered = counts.keys.toList();
    // `sort` de Dart no es estable: el desempate por posición se hace aparte.
    final firstSeen = {for (final (i, id) in ordered.indexed) id: i};
    ordered.sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : firstSeen[a]!.compareTo(firstSeen[b]!);
    });
    return ordered.take(limit).toList();
  }
}
