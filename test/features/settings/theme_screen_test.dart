import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/services/theme_storage.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/features/settings/theme_screen.dart';
import 'package:sistema_cuentas/features/settings/utils/theme_options.dart';
import 'package:sistema_cuentas/features/settings/widgets/theme_option_tile.dart';
import 'package:sistema_cuentas/shared/providers/theme_mode_provider.dart';

import '../../support/expect_screen_no_overflow.dart';
import '../../support/fake_theme_storage.dart';
import '../../support/pump_screen_app.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeThemeStorage storage, {
  ThemeMode initial = ThemeMode.system,
  double width = 390,
  ThemeData? theme,
}) => pumpScreenApp(
  tester,
  screen: const ThemeScreen(),
  width: width,
  theme: theme,
  overrides: [
    themeStorageProvider.overrideWithValue(storage),
    initialThemeModeProvider.overrideWithValue(initial),
  ],
);

Finder _tile(String name) => find.byKey(ValueKey('theme-$name'));

bool _selected(WidgetTester tester, String name) =>
    tester.widget<ThemeOptionTile>(_tile(name)).selected;

double _borderWidth(WidgetTester tester, String name) {
  final card = tester.widget<Card>(
    find.descendant(of: _tile(name), matching: find.byType(Card)),
  );
  return (card.shape! as RoundedRectangleBorder).side.width;
}

Finder _check(String name) => find.descendant(
  of: _tile(name),
  matching: find.byIcon(Icons.check_circle_rounded),
);

void main() {
  group('opciones', () {
    testWidgets(
      'Claro, Oscuro y Automático, en ese orden, con su descripción',
      (tester) async {
        await _pump(tester, FakeThemeStorage());

        expect(find.byType(ThemeOptionTile), findsNWidgets(3));
        final tops = [
          for (final name in ['light', 'dark', 'system'])
            tester.getTopLeft(_tile(name)).dy,
        ];
        expect(tops, [...tops]..sort());
        expect(find.text('Claro'), findsOneWidget);
        expect(find.text('Oscuro'), findsOneWidget);
        expect(find.text('Automático'), findsOneWidget);
        expect(
          find.text('Fondo blanco, para ambientes con luz'),
          findsOneWidget,
        );
        expect(find.text('Fondo oscuro, más suave de noche'), findsOneWidget);
        expect(find.text('Sigue el modo del teléfono'), findsOneWidget);
      },
    );

    testWidgets('cada una con su icono', (tester) async {
      await _pump(tester, FakeThemeStorage());

      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
      expect(find.byIcon(Icons.smartphone_rounded), findsOneWidget);
    });

    testWidgets('la barra se llama «Tema» y «Atrás» vuelve', (tester) async {
      await _pump(tester, FakeThemeStorage());
      expect(find.widgetWithText(AppBar, 'Tema'), findsOneWidget);

      await tester.tap(find.byTooltip('Atrás'));
      await tester.pumpAndSettle();

      expect(find.byType(ThemeScreen), findsNothing);
      expect(find.text(previousScreenText), findsOneWidget);
    });

    test('themeOptions y las etiquetas del modo', () {
      expect(themeOptions, [ThemeMode.light, ThemeMode.dark, ThemeMode.system]);
      expect(
        [for (final m in themeOptions) m.label],
        ['Claro', 'Oscuro', 'Automático'],
      );
    });
  });

  group('la elegida', () {
    testWidgets('por defecto Automático: visto, borde grueso y las otras sin '
        'visto', (tester) async {
      await _pump(tester, FakeThemeStorage());

      expect(_selected(tester, 'system'), isTrue);
      expect(_selected(tester, 'light'), isFalse);
      expect(_selected(tester, 'dark'), isFalse);
      expect(_check('system'), findsOneWidget);
      expect(_check('light'), findsNothing);
      expect(_check('dark'), findsNothing);
      expect(_borderWidth(tester, 'system'), 2);
      expect(_borderWidth(tester, 'light'), 1);
    });

    for (final mode in ThemeMode.values) {
      testWidgets('si ya estaba guardado ${mode.name}, esa sale marcada', (
        tester,
      ) async {
        await _pump(tester, FakeThemeStorage(mode), initial: mode);

        for (final other in ThemeMode.values) {
          expect(_selected(tester, other.name), other == mode);
          expect(_check(other.name).evaluate().length, other == mode ? 1 : 0);
        }
      });
    }

    testWidgets('el borde de la elegida es de acento y el de las demás tenue', (
      tester,
    ) async {
      await _pump(tester, FakeThemeStorage());

      Color border(String name) {
        final card = tester.widget<Card>(
          find.descendant(of: _tile(name), matching: find.byType(Card)),
        );
        return (card.shape! as RoundedRectangleBorder).side.color;
      }

      expect(border('system'), AppColors.accent);
      expect(border('light'), AppColors.border);
    });
  });

  group('tocar', () {
    testWidgets('Claro: cambia al instante, mueve el visto y lo guarda', (
      tester,
    ) async {
      final storage = FakeThemeStorage();
      final container = await _pump(tester, storage);

      await tester.tap(_tile('light'));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(storage.saved, [ThemeMode.light]);
      expect(_selected(tester, 'light'), isTrue);
      expect(_selected(tester, 'system'), isFalse);
      expect(_check('light'), findsOneWidget);
      expect(_check('system'), findsNothing);
    });

    testWidgets('Oscuro y luego Automático: se guardan en orden', (
      tester,
    ) async {
      final storage = FakeThemeStorage();
      final container = await _pump(tester, storage);

      await tester.tap(_tile('dark'));
      await tester.pumpAndSettle();
      await tester.tap(_tile('system'));
      await tester.pumpAndSettle();

      expect(storage.saved, [ThemeMode.dark, ThemeMode.system]);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    testWidgets('tocar la que ya está elegida no vuelve a guardar', (
      tester,
    ) async {
      final storage = FakeThemeStorage();
      await _pump(tester, storage);

      await tester.tap(_tile('system'));
      await tester.pumpAndSettle();

      expect(storage.saved, isEmpty);
      expect(_selected(tester, 'system'), isTrue);
    });

    testWidgets('tocar el icono o la descripción también elige', (
      tester,
    ) async {
      final storage = FakeThemeStorage();
      await _pump(tester, storage);

      await tester.tap(find.text('Fondo oscuro, más suave de noche'));
      await tester.pumpAndSettle();

      expect(storage.saved, [ThemeMode.dark]);
    });

    testWidgets('si no se puede guardar, igual cambia en pantalla', (
      tester,
    ) async {
      final container = await _pump(tester, _FailingThemeStorage());

      await tester.tap(_tile('dark'));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(_selected(tester, 'dark'), isTrue);
    });
  });

  group('semántica', () {
    testWidgets('cada opción es un botón con su nombre y su descripción', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, FakeThemeStorage());

      final light = tester.getSemantics(_tile('light'));
      expect(light.label, 'Claro. Fondo blanco, para ambientes con luz');
      expect(light.flagsCollection.isButton, isTrue);
      expect(
        tester.getSemantics(_tile('system')).label,
        'Automático. Sigue el modo del teléfono',
      );
      handle.dispose();
    });

    testWidgets('solo la elegida va marcada como seleccionada', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        FakeThemeStorage(ThemeMode.dark),
        initial: ThemeMode.dark,
      );

      expect(
        tester.getSemantics(_tile('dark')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(_tile('light')).flagsCollection.isSelected,
        Tristate.isFalse,
      );
      handle.dispose();
    });

    testWidgets('al elegir otra, la marca de selección se mueve', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, FakeThemeStorage());

      await tester.tap(_tile('light'));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(_tile('light')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(_tile('system')).flagsCollection.isSelected,
        Tristate.isFalse,
      );
      handle.dispose();
    });
  });

  group('sin desbordes (320/390/800/1300 × teclado × texto 1.5)', () {
    testWidgets('tema oscuro', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const ThemeScreen(),
        overrides: () => [
          themeStorageProvider.overrideWithValue(FakeThemeStorage()),
        ],
      );
    });

    testWidgets('tema claro', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const ThemeScreen(),
        theme: AppTheme.light,
        overrides: () => [
          themeStorageProvider.overrideWithValue(FakeThemeStorage()),
          initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        ],
      );
    });
  });
}

class _FailingThemeStorage extends FakeThemeStorage {
  @override
  Future<void> save(ThemeMode mode) async {
    // Como el real: si no puede guardar, no lanza.
  }
}
