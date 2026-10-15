import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/features/auth/providers/splash_min_time_provider.dart';
import 'package:sistema_cuentas/app.dart';
import 'package:sistema_cuentas/core/services/theme_storage.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/features/home/home_screen.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_card.dart';
import 'package:sistema_cuentas/shared/providers/theme_mode_provider.dart';
import 'package:sistema_cuentas/shared/widgets/floating_pill_nav.dart';

import '../helpers/auth_fixtures.dart';
import '../helpers/movement_fixtures.dart';
import '../support/fake_auth_repository.dart';
import '../support/fake_theme_storage.dart';
import '../support/inicio_overrides.dart';

/// La app completa (router real + menú + Inicio) con la sesión abierta.
Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  ThemeMode initial = ThemeMode.system,
  FakeThemeStorage? storage,
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            storedToken: true,
            onFetchSession: () async => buildSession(),
          ),
        ),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        themeStorageProvider.overrideWithValue(storage ?? FakeThemeStorage()),
        initialThemeModeProvider.overrideWithValue(initial),
        ...dataOverrides(items: [buildMovement(id: 1, date: DateTime.now())]),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(App)));
}

ThemeData _theme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(HomeScreen)));

void main() {
  setUp(() {
    // Sin teléfono en modo oscuro salvo que la prueba lo pida.
  });

  group('App sigue el tema elegido', () {
    testWidgets('oscuro: fondo y superficies oscuros', (tester) async {
      await _pumpApp(tester, initial: ThemeMode.dark);

      expect(_theme(tester).brightness, Brightness.dark);
      expect(
        _theme(tester).scaffoldBackgroundColor,
        AppPalette.dark.background,
      );
      expect(_theme(tester).colorScheme.surface, AppPalette.dark.surface);
      expect(AppColors.isLight, isFalse);
    });

    testWidgets('claro: fondo y superficies claros', (tester) async {
      await _pumpApp(tester, initial: ThemeMode.light);

      expect(_theme(tester).brightness, Brightness.light);
      expect(
        _theme(tester).scaffoldBackgroundColor,
        AppPalette.light.background,
      );
      expect(_theme(tester).colorScheme.surface, AppPalette.light.surface);
      expect(AppColors.isLight, isTrue);
      expect(
        _theme(tester).scaffoldBackgroundColor.computeLuminance(),
        greaterThan(0.5),
      );
    });

    testWidgets('al elegir Claro en caliente, los colores cambian', (
      tester,
    ) async {
      final storage = FakeThemeStorage();
      final container = await _pumpApp(
        tester,
        initial: ThemeMode.dark,
        storage: storage,
      );
      final darkBackground = _theme(tester).scaffoldBackgroundColor;

      await container.read(themeModeProvider.notifier).set(ThemeMode.light);
      await tester.pumpAndSettle();

      expect(_theme(tester).scaffoldBackgroundColor, isNot(darkBackground));
      expect(
        _theme(tester).scaffoldBackgroundColor,
        AppPalette.light.background,
      );
      expect(_theme(tester).colorScheme.surface, AppPalette.light.surface);
      expect(storage.saved, [ThemeMode.light]);
    });

    testWidgets('y de vuelta a Oscuro', (tester) async {
      final container = await _pumpApp(tester, initial: ThemeMode.light);

      await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(
        _theme(tester).scaffoldBackgroundColor,
        AppPalette.dark.background,
      );
      expect(AppColors.isLight, isFalse);
    });

    testWidgets('el menú flotante y el fondo de la píldora cambian de color', (
      tester,
    ) async {
      final container = await _pumpApp(tester, initial: ThemeMode.dark);
      Color pillColor() => tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(FloatingPillNav),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.color)
          .whereType<Color>()
          .first;
      final before = pillColor();

      await container.read(themeModeProvider.notifier).set(ThemeMode.light);
      await tester.pumpAndSettle();

      expect(pillColor(), isNot(before));
    });

    testWidgets('la app sigue en la misma pantalla al cambiar de tema', (
      tester,
    ) async {
      final container = await _pumpApp(tester, initial: ThemeMode.dark);
      expect(find.byType(HomeScreen), findsOneWidget);

      await container.read(themeModeProvider.notifier).set(ThemeMode.light);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('automático sigue al teléfono', () {
    testWidgets('teléfono en oscuro → oscuro; en claro → claro', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _pumpApp(tester);
      expect(_theme(tester).brightness, Brightness.dark);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();

      expect(_theme(tester).brightness, Brightness.light);
      expect(
        _theme(tester).scaffoldBackgroundColor,
        AppPalette.light.background,
      );
    });

    testWidgets('con un tema fijo, el teléfono no lo mueve', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _pumpApp(tester, initial: ThemeMode.dark);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();

      expect(_theme(tester).brightness, Brightness.dark);
    });
  });

  group(
    'con tema claro, lo que va sobre la tarjeta de balance sigue claro',
    () {
      testWidgets('todos los textos de la tarjeta son claros (onBrand)', (
        tester,
      ) async {
        await _pumpApp(tester, initial: ThemeMode.light);

        final texts = tester.widgetList<Text>(
          find.descendant(
            of: find.byType(BalanceCard),
            matching: find.byType(Text),
          ),
        );
        expect(texts, isNotEmpty);
        for (final text in texts) {
          final color = text.style?.color;
          if (color == null) continue;
          expect(
            color.computeLuminance(),
            greaterThan(0.5),
            reason: '«${text.data}» usa $color sobre el degradado de la marca',
          );
        }
      });

      testWidgets('el balance y «Balance disponible» usan onBrand', (
        tester,
      ) async {
        await _pumpApp(tester, initial: ThemeMode.light);

        final title = tester.widget<Text>(find.text('Balance disponible'));
        expect(title.style!.color, AppColors.onBrandMuted);
        final number = tester.widget<Text>(
          find.descendant(
            of: find.byType(BalanceCard),
            matching: find.byWidgetPredicate(
              (w) => w is Text && w.style?.fontSize == 32,
            ),
          ),
        );
        expect(number.style!.color, AppColors.onBrand);
      });

      testWidgets('el degradado de la tarjeta es el mismo en claro y oscuro', (
        tester,
      ) async {
        BoxDecoration decoration() =>
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(BalanceCard),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;

        await _pumpApp(tester, initial: ThemeMode.dark);
        final dark = (decoration().gradient! as LinearGradient).colors;
        await _pumpApp(tester, initial: ThemeMode.light);
        final light = (decoration().gradient! as LinearGradient).colors;

        expect(light, dark);
      });
    },
  );

  group('barra de estado y de navegación del sistema', () {
    SystemUiOverlayStyle style(WidgetTester tester) => tester
        .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find
              .descendant(
                of: find.byType(MaterialApp),
                matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
              )
              .first,
        )
        .value;

    testWidgets('oscuro: iconos claros y barra de navegación del color de '
        'fondo', (tester) async {
      await _pumpApp(tester, initial: ThemeMode.dark);

      final value = style(tester);
      expect(value.statusBarIconBrightness, Brightness.light);
      expect(value.statusBarBrightness, Brightness.dark);
      expect(value.systemNavigationBarIconBrightness, Brightness.light);
      expect(value.systemNavigationBarColor, AppPalette.dark.background);
      expect(value.statusBarColor, AppColors.transparent);
    });

    testWidgets('claro: iconos oscuros y barra de navegación clara', (
      tester,
    ) async {
      await _pumpApp(tester, initial: ThemeMode.light);

      final value = style(tester);
      expect(value.statusBarIconBrightness, Brightness.dark);
      expect(value.statusBarBrightness, Brightness.light);
      expect(value.systemNavigationBarIconBrightness, Brightness.dark);
      expect(value.systemNavigationBarColor, AppPalette.light.background);
    });

    testWidgets('sigue al tema al cambiarlo en caliente, no al teléfono', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final container = await _pumpApp(tester, initial: ThemeMode.dark);
      expect(style(tester).statusBarIconBrightness, Brightness.light);

      await container.read(themeModeProvider.notifier).set(ThemeMode.light);
      await tester.pumpAndSettle();

      expect(style(tester).statusBarIconBrightness, Brightness.dark);
    });
  });

  group('la píldora del menú', () {
    BoxDecoration decoration(WidgetTester tester) => tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(FloatingPillNav),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.boxShadow != null && d.boxShadow!.isNotEmpty);

    testWidgets('lleva sombra del color del tema (oscuro y claro)', (
      tester,
    ) async {
      final container = await _pumpApp(tester, initial: ThemeMode.dark);
      expect(
        decoration(tester).boxShadow!.single.color,
        AppPalette.dark.shadow,
      );

      await container.read(themeModeProvider.notifier).set(ThemeMode.light);
      await tester.pumpAndSettle();

      expect(
        decoration(tester).boxShadow!.single.color,
        AppPalette.light.shadow,
      );
      expect(decoration(tester).color, AppPalette.light.navBar);
    });

    testWidgets('queda a floatingNavBottomGap (4) del borde inferior', (
      tester,
    ) async {
      await _pumpApp(tester);

      final pill = tester.getRect(find.byType(FloatingPillNav));
      expect(pill.bottom, 800 - DesignTokens.floatingNavBottomGap);
    });

    testWidgets('el hueco reservado (76) cubre la píldora más su separación', (
      tester,
    ) async {
      expect(DesignTokens.floatingNavBottomGap, 4);
      expect(DesignTokens.floatingNavFootprint, 76);
      expect(
        DesignTokens.floatingNavFootprint,
        greaterThanOrEqualTo(
          DesignTokens.floatingNavHeight +
              2 * DesignTokens.spaceXs +
              DesignTokens.floatingNavBottomGap,
        ),
      );
      await _pumpApp(tester);
      final pill = tester.getRect(find.byType(FloatingPillNav));
      final fab = tester.getRect(find.byType(FloatingActionButton));
      expect(fab.bottom, lessThanOrEqualTo(pill.top));
    });
  });

  group('sin desbordes en tema claro', () {
    testWidgets('la app completa a 390 px con texto 1.5', (tester) async {
      await _pumpApp(
        tester,
        initial: ThemeMode.light,
        width: 390,
        textScale: 1.5,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('la app completa a 320 px con texto 1.5', (tester) async {
      await _pumpApp(
        tester,
        initial: ThemeMode.light,
        width: 320,
        textScale: 1.5,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
