import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Transforma el dato de un `AsyncValue` **sin perderlo** mientras recarga o
/// si el refresco falla. `whenData` devuelve cargando/error sin valor en esos
/// casos y la lista se vaciaba un instante; `.value` sí conserva el último dato.
///
/// Ojo: el resultado es siempre `AsyncData` si hay dato, así que **no** conserva
/// «está recargando» ni «falló». Para una pantalla que debe mostrar esos
/// estados, derivar con un `AsyncNotifier` que espere al provider de origen
/// (ver `filteredMovementsProvider`).
AsyncValue<R> mapKeepingData<T, R>(AsyncValue<T> source, R Function(T) map) {
  if (source.hasValue) return AsyncData(map(source.requireValue));
  if (source.hasError) {
    return AsyncError<R>(source.error!, source.stackTrace ?? StackTrace.empty);
  }
  return AsyncLoading<R>();
}
