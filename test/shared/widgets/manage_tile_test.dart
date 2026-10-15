import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_badge.dart';
import 'package:sistema_cuentas/shared/widgets/manage_tile.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/pump_at_sizes.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  ),
);

CatalogBadge _badge(WidgetTester tester) =>
    tester.widget<CatalogBadge>(find.byType(CatalogBadge));

void main() {
  group('CatalogBadge', () {
    testWidgets('mide el avatar por defecto y pinta el icono con su color', (
      tester,
    ) async {
      await _pump(
        tester,
        const CatalogBadge(icon: Icons.home_rounded, color: Color(0xFFFB923C)),
      );

      expect(
        tester.getSize(find.byType(CatalogBadge)),
        const Size.square(DesignTokens.avatarSize),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.home_rounded));
      expect(icon.color, const Color(0xFFFB923C));
      expect(
        icon.size,
        DesignTokens.avatarSize * DesignTokens.visualBadgeRatio,
      );
    });

    testWidgets('el fondo es el mismo color, tenue', (tester) async {
      await _pump(
        tester,
        const CatalogBadge(icon: Icons.home_rounded, color: Color(0xFFFB923C)),
      );

      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(CatalogBadge),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (box.decoration as BoxDecoration).color,
        const Color(0xFFFB923C).withValues(alpha: DesignTokens.tintFill),
      );
    });

    testWidgets('el tamaño es parametrizable y el icono lo acompaña', (
      tester,
    ) async {
      await _pump(
        tester,
        CatalogBadge(
          icon: Icons.home_rounded,
          color: AppColors.accent,
          size: DesignTokens.visualPreviewSize,
        ),
      );

      expect(
        tester.getSize(find.byType(CatalogBadge)),
        const Size.square(DesignTokens.visualPreviewSize),
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.home_rounded)).size,
        DesignTokens.visualPreviewSize * DesignTokens.visualBadgeRatio,
      );
    });
  });

  group('ManageTile', () {
    testWidgets('usa el icono y el color (tint) que recibe', (tester) async {
      await _pump(
        tester,
        const ManageTile(
          title: 'Combustible',
          icon: Icons.local_gas_station_rounded,
          tint: Color(0xFFFB923C),
        ),
      );

      expect(_badge(tester).icon, Icons.local_gas_station_rounded);
      expect(_badge(tester).color, const Color(0xFFFB923C));
    });

    testWidgets('sin tint usa el acento', (tester) async {
      await _pump(
        tester,
        const ManageTile(title: 'Oscar', icon: Icons.person_outline_rounded),
      );

      expect(_badge(tester).color, AppColors.accent);
    });

    testWidgets('inactiva: se ve apagada aunque tenga color, y lo dice', (
      tester,
    ) async {
      await _pump(
        tester,
        const ManageTile(
          title: 'Vieja',
          icon: Icons.home_rounded,
          tint: Color(0xFFFB923C),
          inactive: true,
        ),
      );

      expect(_badge(tester).color, AppColors.muted);
      expect(_badge(tester).icon, Icons.home_rounded);
      expect(find.text('Inactivo'), findsOneWidget);
    });

    testWidgets('el título lleva inicial mayúscula', (tester) async {
      await _pump(
        tester,
        const ManageTile(title: 'nequi', icon: Icons.home_rounded),
      );

      expect(find.text('Nequi'), findsOneWidget);
    });

    testWidgets('tocar la fila avisa', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        ManageTile(
          title: 'Oscar',
          icon: Icons.home_rounded,
          onTap: () => taps++,
        ),
      );

      await tester.tap(find.byType(ManageTile));
      expect(taps, 1);
    });
  });

  group(
    'ManageTile: sin desbordes (320/390/800/1300 × teclado × texto 1.5)',
    () {
      testWidgets('nombre de 40+ caracteres, detalle largo, icono y color', (
        tester,
      ) async {
        expect(longCatalogName.length, greaterThan(40));
        await expectNoOverflow(
          tester,
          ListView(
            children: [
              ManageTile(
                title: longCatalogName,
                subtitle: longDescription,
                icon: Icons.local_gas_station_rounded,
                tint: const Color(0xFFFB923C),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
              ManageTile(
                title: longCatalogName,
                icon: Icons.person_outline_rounded,
                inactive: true,
                tint: const Color(0xFF818CF8),
              ),
              const ManageTile(title: 'Sin color', icon: Icons.home_rounded),
            ],
          ),
        );
      });
    },
  );
}
