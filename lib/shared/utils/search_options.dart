Iterable<T> searchOptions<T>(
  List<T> items,
  String Function(T) label,
  String query,
) {
  final search = normalizeSearch(query);
  return items.where((item) => normalizeSearch(label(item)).contains(search));
}

String normalizeSearch(String value) {
  var result = value.trim().toLowerCase();
  const accents = ['á', 'é', 'í', 'ó', 'ú', 'ü'];
  const letters = ['a', 'e', 'i', 'o', 'u', 'u'];
  for (var index = 0; index < accents.length; index++) {
    result = result.replaceAll(accents[index], letters[index]);
  }
  return result;
}
