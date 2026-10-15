import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/services/hidden_prefs_storage.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// Las cifras sueltas que se taparon con su propio ojo (la tarjeta de balance,
/// el total de un día…), cada una por separado. El ojo de la cabecera
/// ([balancesHiddenProvider]) tapa todo; estos solo tapan lo suyo.
final hiddenSectionsProvider =
    NotifierProvider<HiddenSectionsNotifier, Set<String>>(
      HiddenSectionsNotifier.new,
    );

class HiddenSectionsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // Cada cuenta tiene lo suyo; sin sesión, todo visible.
    final userId = ref.watch(sessionUserIdProvider);
    if (userId == null) return const {};
    return ref.read(hiddenPrefsStorageProvider).hiddenSections(userId);
  }

  void toggle(String section) {
    state = state.contains(section)
        ? ({...state}..remove(section))
        : {...state, section};
    final userId = ref.read(sessionUserIdProvider);
    if (userId == null) return;
    ref.read(hiddenPrefsStorageProvider).saveHiddenSections(userId, state);
  }
}

/// Los nombres de las secciones que se pueden tapar por separado.
abstract final class HiddenSections {
  static const balanceCard = 'balance-card';

  /// El total de un día del historial.
  static String day(DateTime date) => 'day-${apiDate(date)}';
}

/// ¿Está tapada esta sección? Sí si se tapó ella sola o si están tapadas todas.
final sectionHiddenProvider = Provider.autoDispose.family<bool, String>(
  (ref, section) =>
      ref.watch(balancesHiddenProvider) ||
      ref.watch(hiddenSectionsProvider.select((s) => s.contains(section))),
);
