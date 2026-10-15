import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/core/utils/catalog_visuals.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_color_grid.dart';

Future<void> _pump(WidgetTester tester, String? selected, {ThemeData? theme}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.dark,
      home: Scaffold(
        body: CatalogColorGrid(selectedHex: selected, onSelected: (_) {}),
      ),
    ),
  );
}

Color _checkColor(WidgetTester tester) =>
    tester.widget<Icon>(find.byIcon(Icons.check_rounded)).color!;

Finder _cell(String hex) => find.byKey(ValueKey('catalog-color-$hex'));

void main() {
  testWidgets('sin elección no hay visto', (tester) async {
    await _pump(tester, null);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('solo el elegido lleva visto', (tester) async {
    final hex = CatalogVisuals.palette[3];
    await _pump(tester, hex);

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(
      find.descendant(
        of: _cell(hex),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
  });

  double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (la > lb ? la + 0.05 : lb + 0.05) /
        (la > lb ? lb + 0.05 : la + 0.05);
  }

  for (final theme in ['oscuro', 'claro']) {
    testWidgets('tema $theme: visto oscuro (brand) sobre un color claro', (
      tester,
    ) async {
      await _pump(
        tester,
        '#FACC15',
        theme: theme == 'claro' ? AppTheme.light : AppTheme.dark,
      );

      expect(_checkColor(tester), AppColors.brand);
    });

    testWidgets('tema $theme: visto claro (onBrand) sobre un color oscuro', (
      tester,
    ) async {
      await _pump(
        tester,
        '#64748B',
        theme: theme == 'claro' ? AppTheme.light : AppTheme.dark,
      );

      expect(
        ratio(const Color(0xFF64748B), AppColors.onBrand),
        greaterThan(ratio(const Color(0xFF64748B), AppColors.brand)),
        reason: 'onBrand es la mejor opción sobre este gris azulado',
      );
      expect(_checkColor(tester), AppColors.onBrand);
    });
  }

  testWidgets('en cada color de la paleta el visto es el de MAYOR contraste', (
    tester,
  ) async {
    for (final hex in CatalogVisuals.palette) {
      await _pump(tester, hex);
      final fill = CatalogVisuals.colorFor(hex, fallback: Colors.white);
      final best =
          ratio(fill, AppColors.brand) >= ratio(fill, AppColors.onBrand)
          ? AppColors.brand
          : AppColors.onBrand;

      expect(_checkColor(tester), best, reason: hex);
    }
  });

  testWidgets('el visto se distingue del color elegido (≥ 3:1) en TODA la '
      'paleta', (tester) async {
    for (final hex in CatalogVisuals.palette) {
      await _pump(tester, hex);
      final fill = CatalogVisuals.colorFor(hex, fallback: Colors.white);

      expect(
        ratio(fill, _checkColor(tester)),
        greaterThanOrEqualTo(3.0),
        reason: hex,
      );
    }
  });

  testWidgets('los cuatro tonos medios que antes fallaban dan ≥ 3:1 y '
      'eligen el visto oscuro', (tester) async {
    for (final hex in ['#F87171', '#F97316', '#0EA5E9', '#818CF8']) {
      await _pump(tester, hex);
      final fill = CatalogVisuals.colorFor(hex, fallback: Colors.white);

      expect(_checkColor(tester), AppColors.brand, reason: hex);
      expect(
        ratio(fill, _checkColor(tester)),
        greaterThanOrEqualTo(3.0),
        reason: hex,
      );
    }
  });
}
