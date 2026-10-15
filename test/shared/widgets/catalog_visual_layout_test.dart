import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_badge.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_header.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_layout.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  ),
);

CatalogVisualHeader _header({
  String? subject,
  bool compact = false,
  bool showIcons = true,
  ValueChanged<bool>? onShowIcons,
}) => CatalogVisualHeader(
  icon: Icons.home_rounded,
  color: Colors.orange,
  subject: subject,
  compact: compact,
  showIcons: showIcons,
  onShowIcons: onShowIcons ?? (_) {},
);

void main() {
  group('CatalogVisualHeader', () {
    testWidgets('normal: título, nombre en acento, vista previa y conmutador', (
      tester,
    ) async {
      await _pump(tester, _header(subject: 'mercado'));

      expect(find.text('Icono y color'), findsOneWidget);
      final name = tester.widget<Text>(find.text('Mercado'));
      expect(name.style?.color, AppColors.accent);
      expect(name.maxLines, 2);
      expect(name.overflow, TextOverflow.ellipsis);
      expect(find.byType(CatalogBadge), findsOneWidget);
      expect(find.text('Icono'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
    });

    testWidgets('sin nombre o con nombre vacío: solo el título', (
      tester,
    ) async {
      for (final subject in [null, '']) {
        await _pump(tester, _header(subject: subject));

        expect(find.text('Icono y color'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is Text && w.style?.color == AppColors.accent,
          ),
          findsNothing,
        );
      }
    });

    testWidgets('compacto: solo el conmutador, ni título ni nombre ni vista '
        'previa', (tester) async {
      await _pump(tester, _header(subject: 'Salud', compact: true));

      expect(find.text('Icono y color'), findsNothing);
      expect(find.text('Salud'), findsNothing);
      expect(find.byType(CatalogBadge), findsNothing);
      expect(find.text('Icono'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
    });

    testWidgets('tocar «Color» avisa con false', (tester) async {
      bool? picked;
      await _pump(tester, _header(onShowIcons: (v) => picked = v));

      await tester.tap(find.text('Color'));

      expect(picked, isFalse);
    });
  });

  group('CatalogVisualLayout', () {
    Widget layout() => const CatalogVisualLayout(
      header: Text('encabezado'),
      body: ColoredBox(
        key: Key('cuerpo'),
        color: Colors.blue,
        child: Text('cuerpo'),
      ),
      actions: Text('pie'),
    );

    testWidgets('con alto de sobra: el cuerpo ocupa lo que queda', (
      tester,
    ) async {
      await _pump(tester, SizedBox(height: 500, child: layout()));

      expect(find.byType(SingleChildScrollView), findsNothing);
      final body = tester.getSize(find.byKey(const Key('cuerpo')));
      expect(body.height, greaterThan(300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('con muy poco alto (<180): cuerpo mínimo y todo se desplaza, '
        'sin desborde', (tester) async {
      await _pump(tester, SizedBox(height: 150, child: layout()));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final body = tester.getSize(find.byKey(const Key('cuerpo')));
      expect(body.height, 160);
      expect(tester.takeException(), isNull);
    });
  });
}
