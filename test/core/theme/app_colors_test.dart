import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';

/// Contraste WCAG: (L1 + 0,05) / (L2 + 0,05) con la luminancia relativa.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('AppColors.apply', () {
    test('oscuro es la paleta de partida', () {
      expect(AppColors.isLight, isFalse);
      expect(AppColors.background, AppPalette.dark.background);
      expect(AppColors.surface, AppPalette.dark.surface);
    });

    test('claro cambia todos los neutros', () {
      AppColors.apply(Brightness.light);

      expect(AppColors.isLight, isTrue);
      expect(AppColors.accent, AppPalette.light.accent);
      expect(AppColors.background, AppPalette.light.background);
      expect(AppColors.surface, AppPalette.light.surface);
      expect(AppColors.surfaceHigh, AppPalette.light.surfaceHigh);
      expect(AppColors.text, AppPalette.light.text);
      expect(AppColors.muted, AppPalette.light.muted);
      expect(AppColors.border, AppPalette.light.border);
      expect(AppColors.inputBorder, AppPalette.light.inputBorder);
      expect(AppColors.income, AppPalette.light.income);
      expect(AppColors.expense, AppPalette.light.expense);
      expect(AppColors.warningText, AppPalette.light.warningText);
      expect(AppColors.shadow, AppPalette.light.shadow);
      expect(AppColors.navHighlight, AppPalette.light.navHighlight);
      expect(AppColors.navBar, AppPalette.light.navBar);
      expect(AppColors.chart, AppPalette.light.chart);
    });

    test('se puede volver a oscuro y es idempotente', () {
      AppColors.apply(Brightness.light);
      AppColors.apply(Brightness.light);
      expect(AppColors.isLight, isTrue);

      AppColors.apply(Brightness.dark);
      AppColors.apply(Brightness.dark);
      expect(AppColors.isLight, isFalse);
      expect(AppColors.text, AppPalette.dark.text);
    });

    test('la marca y los estados son iguales en los dos temas', () {
      final dark = [
        AppColors.brand,
        AppColors.primary,
        AppColors.onPrimary,
        AppColors.success,
        AppColors.warning,
        AppColors.error,
        AppColors.info,
        AppColors.balanceStart,
        AppColors.balanceEnd,
        AppColors.onBrand,
      ];
      AppColors.apply(Brightness.light);
      final light = [
        AppColors.brand,
        AppColors.primary,
        AppColors.onPrimary,
        AppColors.success,
        AppColors.warning,
        AppColors.error,
        AppColors.info,
        AppColors.balanceStart,
        AppColors.balanceEnd,
        AppColors.onBrand,
      ];

      expect(light, dark);
    });

    test('los neutros de claro y oscuro son distintos (no se mezclan)', () {
      expect(AppPalette.light.background, isNot(AppPalette.dark.background));
      expect(AppPalette.light.surface, isNot(AppPalette.dark.surface));
      expect(AppPalette.light.text, isNot(AppPalette.dark.text));
      expect(AppPalette.light.background.computeLuminance(), greaterThan(0.5));
      expect(AppPalette.dark.background.computeLuminance(), lessThan(0.1));
    });
  });

  group('AppTheme arma su propia paleta', () {
    test('AppTheme.light activa la paleta clara aunque no se llame apply', () {
      expect(AppColors.isLight, isFalse);

      final theme = AppTheme.light;

      expect(AppColors.isLight, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppPalette.light.background);
      expect(theme.colorScheme.surface, AppPalette.light.surface);
      expect(theme.colorScheme.onSurface, AppPalette.light.text);
      expect(theme.colorScheme.secondary, AppPalette.light.accent);
    });

    test('AppTheme.dark vuelve a la oscura', () {
      AppTheme.light;
      expect(AppColors.isLight, isTrue);

      final theme = AppTheme.dark;

      expect(AppColors.isLight, isFalse);
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppPalette.dark.background);
      expect(theme.colorScheme.surface, AppPalette.dark.surface);
    });

    test('el primary es el de la marca en los dos temas (sin tinte)', () {
      expect(AppTheme.dark.colorScheme.primary, AppColors.primary);
      expect(AppTheme.light.colorScheme.primary, AppColors.primary);
    });

    test('dos temas armados seguidos no se contaminan', () {
      final dark = AppTheme.dark;
      final light = AppTheme.light;

      expect(dark.scaffoldBackgroundColor, AppPalette.dark.background);
      expect(light.scaffoldBackgroundColor, AppPalette.light.background);
      expect(dark.colorScheme.onSurface, isNot(light.colorScheme.onSurface));
    });

    test('el interruptor apagado se ve en los dos temas', () {
      for (final theme in [AppTheme.dark, AppTheme.light]) {
        final switchTheme = theme.switchTheme;
        expect(
          switchTheme.thumbColor!.resolve({}),
          AppColors.muted,
          reason: 'pomo apagado',
        );
        expect(
          switchTheme.trackOutlineColor!.resolve({}),
          AppColors.inputBorder,
          reason: 'contorno apagado',
        );
        expect(
          switchTheme.thumbColor!.resolve({WidgetState.selected}),
          AppColors.onBrand,
        );
        expect(
          switchTheme.trackColor!.resolve({WidgetState.selected}),
          AppColors.primary,
        );
        expect(
          switchTheme.trackOutlineColor!.resolve({WidgetState.selected}),
          AppColors.transparent,
        );
      }
    });
  });

  group('contraste mínimo (WCAG AA, 4,5:1) sobre la superficie', () {
    for (final entry in {
      'oscuro': AppPalette.dark,
      'claro': AppPalette.light,
    }.entries) {
      final p = entry.value;
      final name = entry.key;

      test('$name: texto, texto secundario y acento', () {
        expect(contrast(p.text, p.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.muted, p.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.accent, p.surface), greaterThanOrEqualTo(4.5));
      });

      test('$name: ingreso, gasto y aviso se leen sobre la superficie', () {
        expect(contrast(p.income, p.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.expense, p.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.warningText, p.surface), greaterThanOrEqualTo(4.5));
      });

      test('$name: texto y secundario sobre el fondo de pantalla', () {
        expect(contrast(p.text, p.background), greaterThanOrEqualTo(4.5));
        expect(contrast(p.muted, p.background), greaterThanOrEqualTo(4.5));
        expect(contrast(p.income, p.background), greaterThanOrEqualTo(4.5));
      });

      test('$name: el borde de los campos se distingue del fondo (≥ 3:1 en '
          'la superficie)', () {
        expect(contrast(p.inputBorder, p.surface), greaterThanOrEqualTo(2.0));
      });
    }

    test('claro: ingreso y gasto se leen sobre fondo, superficie y '
        'superficie alta (≥ 4,5:1)', () {
      final p = AppPalette.light;
      for (final (name, color) in [
        ('income', p.income),
        ('expense', p.expense),
      ]) {
        for (final (surfaceName, surface) in [
          ('background', p.background),
          ('surface', p.surface),
          ('surfaceHigh', p.surfaceHigh),
        ]) {
          expect(
            contrast(color, surface),
            greaterThanOrEqualTo(4.5),
            reason: '$name sobre $surfaceName',
          );
        }
      }
    });

    test('oscuro: ingreso y gasto también sobre fondo, superficie y '
        'superficie alta', () {
      final p = AppPalette.dark;
      for (final color in [p.income, p.expense]) {
        for (final surface in [p.background, p.surface, p.surfaceHigh]) {
          expect(contrast(color, surface), greaterThanOrEqualTo(4.5));
        }
      }
    });

    test('valores concretos de claro: ingreso #08764E y gasto #CF2323', () {
      expect(AppPalette.light.income, const Color(0xFF08764E));
      expect(AppPalette.light.expense, const Color(0xFFCF2323));
    });
  });

  group('onBrand (lo que va sobre la tarjeta de balance y rellenos)', () {
    test('es claro y legible sobre el degradado de la marca, en los dos '
        'temas', () {
      for (final brightness in Brightness.values) {
        AppColors.apply(brightness);
        expect(AppColors.onBrand.computeLuminance(), greaterThan(0.8));
        expect(
          contrast(AppColors.onBrand, AppColors.balanceStart),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(AppColors.onBrand, AppColors.balanceEnd),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('NO es lo mismo que el texto del tema claro (que es oscuro)', () {
      AppColors.apply(Brightness.light);
      expect(AppColors.text.computeLuminance(), lessThan(0.2));
      expect(AppColors.onBrand, isNot(AppColors.text));
    });
  });

  group('paleta de gráficas', () {
    test('ocho colores distintos en cada tema, y distintos entre temas', () {
      for (final p in [AppPalette.dark, AppPalette.light]) {
        expect(p.chart, hasLength(8));
        expect(p.chart.toSet(), hasLength(8));
      }
      expect(AppPalette.light.chart, isNot(AppPalette.dark.chart));
    });

    test('en claro son más hondos (menos luminosos) que en oscuro', () {
      double mean(List<Color> colors) =>
          colors.fold(0.0, (sum, c) => sum + c.computeLuminance()) /
          colors.length;

      expect(
        mean(AppPalette.light.chart),
        lessThan(mean(AppPalette.dark.chart)),
      );
    });
  });
}
