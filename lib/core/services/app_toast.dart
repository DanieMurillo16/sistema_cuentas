import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:sistema_cuentas/core/services/app_toast_card.dart';

/// Avisos cortos sobre cualquier pantalla, **también encima de los diálogos**
/// (un `SnackBar` quedaba tapado por el velo del diálogo). Un solo lugar para
/// que el resto de la app no dependa de `flutter_smart_dialog` y todos se vean
/// igual:
///
/// - [success]: algo salió bien (verde).
/// - [error]: algo falló (rojo).
/// - [warning]: falta o está mal un dato, o hay que tener cuidado (naranja).
/// - [info]: aviso neutral (azul).
///
/// Requiere `FlutterSmartDialog.init()` en `MaterialApp.builder` (ver app.dart).
abstract final class AppToast {
  static const _successDuration = Duration(seconds: 2);
  static const _defaultDuration = Duration(seconds: 3);

  static void success(String message, {Duration? duration}) =>
      _show(message, ToastType.success, duration ?? _successDuration);

  static void error(String message, {Duration? duration}) =>
      _show(message, ToastType.error, duration ?? _defaultDuration);

  static void warning(String message, {Duration? duration}) =>
      _show(message, ToastType.warning, duration ?? _defaultDuration);

  static void info(String message, {Duration? duration}) =>
      _show(message, ToastType.info, duration ?? _defaultDuration);

  static void _show(String message, ToastType type, Duration duration) {
    SmartDialog.showToast(
      message,
      displayTime: duration,
      alignment: Alignment.bottomCenter,
      builder: (_) => AppToastCard(message: message, type: type),
    );
  }
}
