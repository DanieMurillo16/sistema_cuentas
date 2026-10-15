import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sistema_cuentas/core/services/hidden_prefs_storage.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/providers/hidden_sections_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../../support/in_memory_preferences.dart';

/// Un «arranque» de la app: lee lo guardado y arma el contenedor con la cuenta
/// [userId] ya en sesión.
Future<ProviderContainer> _launch(int? userId) async {
  final storage = HiddenPrefsStorage(SharedPreferencesAsync.new);
  await storage.load();
  final container = ProviderContainer(
    overrides: [
      hiddenPrefsStorageProvider.overrideWithValue(storage),
      sessionUserIdProvider.overrideWithValue(userId),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('el ojo de la cabecera sigue tapado al cerrar y abrir la app', () async {
    useInMemoryPreferences();
    final first = await _launch(7);
    expect(first.read(balancesHiddenProvider), isFalse);
    first.read(balancesHiddenProvider.notifier).toggle();
    await Future<void>.delayed(Duration.zero);

    final second = await _launch(7);
    expect(second.read(balancesHiddenProvider), isTrue);

    second.read(balancesHiddenProvider.notifier).toggle(); // destapa
    await Future<void>.delayed(Duration.zero);
    expect((await _launch(7)).read(balancesHiddenProvider), isFalse);
  });

  test(
    'las secciones tapadas (balance, total de un día) se recuerdan',
    () async {
      useInMemoryPreferences();
      final first = await _launch(7);
      first.read(hiddenSectionsProvider.notifier)
        ..toggle(HiddenSections.balanceCard)
        ..toggle('day-2026-10-14');
      await Future<void>.delayed(Duration.zero);

      final second = await _launch(7);
      expect(second.read(hiddenSectionsProvider), {
        HiddenSections.balanceCard,
        'day-2026-10-14',
      });
      expect(
        second.read(sectionHiddenProvider(HiddenSections.balanceCard)),
        isTrue,
      );
    },
  );

  test('otra cuenta del mismo teléfono empieza con todo visible', () async {
    useInMemoryPreferences();
    final first = await _launch(7);
    first.read(balancesHiddenProvider.notifier).toggle();
    first
        .read(hiddenSectionsProvider.notifier)
        .toggle(HiddenSections.balanceCard);
    await Future<void>.delayed(Duration.zero);

    final other = await _launch(8);
    expect(other.read(balancesHiddenProvider), isFalse);
    expect(other.read(hiddenSectionsProvider), isEmpty);
  });

  test('sin sesión todo está visible y tapar no guarda nada', () async {
    final store = useInMemoryPreferences();
    final container = await _launch(null);

    expect(container.read(balancesHiddenProvider), isFalse);
    container.read(balancesHiddenProvider.notifier).toggle();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(balancesHiddenProvider), isTrue);
    expect(store, isNotNull);
    expect((await _launch(null)).read(balancesHiddenProvider), isFalse);
  });
}
