import 'package:flutter/widgets.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/app_loading_card.dart';

/// Velo con mensaje para cargas que **cambian la pantalla entera** (cambiar de
/// sucursal, de mes, de negocio). La pantalla de abajo se conserva y el velo se
/// retira con un fundido cuando ya está lista.
///
/// ```dart
/// AppLoadingVeil.show('Cambiando de sucursal...');
/// await ref.read(branchProvider.notifier).switchTo(id);
/// await AppLoadingVeil.closeAfterPaint();
/// AppToast.success('Sucursal cambiada');
/// ```
abstract final class AppLoadingVeil {
  static void show(String message) {
    SmartDialog.showLoading(builder: (_) => AppLoadingCard(message: message));
  }

  /// Lo cierra **dos cuadros después** de que la pantalla se repintó con los
  /// datos nuevos: cerrarlo en el mismo cuadro hace coincidir su salida con el
  /// trabajo pesado y se ve como un tirón.
  static Future<void> closeAfterPaint() async {
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    await SmartDialog.dismiss(status: SmartStatus.loading);
  }
}
