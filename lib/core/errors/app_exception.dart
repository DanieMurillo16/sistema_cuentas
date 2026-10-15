import 'package:flutter_riverpod/misc.dart' show ProviderException;

sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;
}

final class ApiException extends AppException {
  const ApiException(super.message, {super.code, super.statusCode});
}

final class NetworkException extends AppException {
  const NetworkException(super.message);
}

final class ConfigurationException extends AppException {
  const ConfigurationException(super.message);
}

final class UnexpectedException extends AppException {
  const UnexpectedException(super.message);
}

String userErrorMessage(Object? error) {
  // Riverpod 3 envuelve lo que lanza un provider del que otro depende (p. ej.
  // un `ConfigurationException` al crear el cliente HTTP): se destapa para no
  // perder el mensaje en español.
  if (error is ProviderException) return userErrorMessage(error.exception);
  if (error is AppException) return error.message;
  return 'Ocurrió un error inesperado. Intenta nuevamente.';
}
