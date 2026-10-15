import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/features/home/widgets/home_filter_header.dart';

Widget _host(Widget header) => ProviderScope(
  child: MaterialApp(
    home: Scaffold(body: CustomScrollView(slivers: [header])),
  ),
);

/// El fondo con el que se pinta el encabezado fijo.
Color _headerBackground(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(HomeFilterHeader),
            matching: find.byType(ColoredBox),
          )
          .first,
    )
    .color;

void main() {
  testWidgets(
    'si cambia el tema, el encabezado fijo se pinta con el fondo nuevo '
    '(el delegate compara también el color)',
    (tester) async {
      AppColors.apply(Brightness.dark);
      final dark = AppColors.background;
      // `HomeFilterHeader()` sin const: es una instancia nueva, así Flutter
      // reconstruye el sliver (como cuando la app vuelve a armar Inicio).
      // ignore: prefer_const_constructors
      await tester.pumpWidget(_host(HomeFilterHeader()));
      expect(_headerBackground(tester), dark);

      AppColors.apply(Brightness.light);
      final light = AppColors.background;
      expect(light, isNot(dark), reason: 'la paleta clara tiene otro fondo');
      // ignore: prefer_const_constructors
      await tester.pumpWidget(_host(HomeFilterHeader()));
      expect(_headerBackground(tester), light);

      AppColors.apply(Brightness.dark);
      // ignore: prefer_const_constructors
      await tester.pumpWidget(_host(HomeFilterHeader()));
      expect(_headerBackground(tester), dark);
    },
  );
}
