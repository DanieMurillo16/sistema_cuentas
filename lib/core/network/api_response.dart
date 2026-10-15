import 'package:sistema_cuentas/core/errors/app_exception.dart';

class ApiResponse {
  const ApiResponse({required this.data, this.meta});

  factory ApiResponse.fromRaw(Object? raw) {
    if (raw is! Map) {
      throw const UnexpectedException(
        'El servidor devolvió una respuesta no válida.',
      );
    }

    final json = Map<String, dynamic>.from(raw);
    if (json['success'] != true) {
      throw ApiException(
        json['error']?.toString() ?? 'No fue posible completar la operación.',
        code: json['codigo']?.toString(),
      );
    }

    if (!json.containsKey('data')) {
      throw const UnexpectedException(
        'Faltan datos en la respuesta del servidor.',
      );
    }

    final meta = json['meta'];
    return ApiResponse(
      data: json['data'],
      meta: meta is Map ? Map<String, dynamic>.from(meta) : null,
    );
  }

  final Object? data;

  /// Datos de apoyo (totales del filtro, paginación) cuando el endpoint los da.
  final Map<String, dynamic>? meta;

  Map<String, dynamic> asMap() {
    if (data is! Map) {
      throw const UnexpectedException(
        'El servidor no devolvió el objeto esperado.',
      );
    }
    return Map<String, dynamic>.from(data! as Map);
  }

  List<dynamic> asList() {
    if (data is! List) {
      throw const UnexpectedException(
        'El servidor no devolvió la lista esperada.',
      );
    }
    return List<dynamic>.from(data! as List);
  }
}

/// Convierte datos del servidor en un modelo. Si faltan campos o llegan con
/// otro tipo, el error es uno propio en español y no un `TypeError` crudo.
T parseApi<T>(T Function() parse) {
  try {
    return parse();
  } on TypeError {
    throw const UnexpectedException('El servidor devolvió datos incompletos.');
  } on FormatException {
    throw const UnexpectedException('El servidor devolvió datos no válidos.');
  }
}
