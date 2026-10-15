import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Una petición que llegó al adaptador falso.
class RecordedRequest {
  RecordedRequest(this.options, this.body);

  final RequestOptions options;
  final Object? body;

  String get path => options.path;
  String get method => options.method;
  String? get authorization => options.headers['Authorization'] as String?;
}

/// Adaptador de Dio que responde con lo que le programes. Sin red real.
class FakeApiAdapter implements HttpClientAdapter {
  FakeApiAdapter(this._handler);

  /// Responde [body] (JSON) con [status].
  FakeApiAdapter.json(Object? body, {int status = 200})
    : _handler = ((_) async => jsonResponse(body, status));

  /// Falla como si no hubiera conexión.
  FakeApiAdapter.connectionError()
    : _handler = ((options) async => throw DioException.connectionError(
        requestOptions: options,
        reason: 'sin red',
      ));

  final Future<ResponseBody> Function(RequestOptions options) _handler;
  final requests = <RecordedRequest>[];

  static ResponseBody jsonResponse(Object? body, int status) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(RecordedRequest(options, options.data));
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
