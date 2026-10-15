import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/services/hidden_prefs_storage.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// Si las cifras están tapadas. Una sola preferencia para toda la app: tapar
/// en una pantalla las tapa en todas. Se recuerda en el dispositivo, por cuenta.
final balancesHiddenProvider = NotifierProvider<BalancesHiddenNotifier, bool>(
  BalancesHiddenNotifier.new,
);

class BalancesHiddenNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Cada cuenta tiene lo suyo; sin sesión, todo visible.
    final userId = ref.watch(sessionUserIdProvider);
    if (userId == null) return false;
    return ref.read(hiddenPrefsStorageProvider).allHidden(userId);
  }

  void toggle() {
    state = !state;
    final userId = ref.read(sessionUserIdProvider);
    if (userId == null) return;
    ref.read(hiddenPrefsStorageProvider).saveAllHidden(userId, hidden: state);
  }
}
