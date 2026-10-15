import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// ¿La sesión tiene este permiso (`modulo.accion`)? Esconder no es impedir: el
/// servidor también lo valida.
final hasPermissionProvider = Provider.family<bool, String>(
  (ref, code) => ref.watch(
    sessionProvider.select((s) => s.value?.hasPermission(code) ?? false),
  ),
);
