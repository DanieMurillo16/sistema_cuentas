import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/shared/widgets/app_date_range_field.dart';

final _range = DateTimeRange(
  start: DateTime(2026, 10),
  end: DateTime(2026, 10, 31),
);

Future<void> _pump(
  WidgetTester tester, {
  required ValueChanged<DateTimeRange> onChanged,
  DateTimeRange? range,
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AppDateRangeField(
            label: 'Fechas',
            range: range ?? _range,
            firstDate: DateTime(2000),
            lastDate: DateTime(2027, 12, 31),
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra la etiqueta y el rango «dd/mm/aaaa – dd/mm/aaaa»', (
    tester,
  ) async {
    await _pump(tester, onChanged: (_) {});
    expect(find.text('Fechas'), findsOneWidget);
    expect(find.text('01/10/2026 – 31/10/2026'), findsOneWidget);
    expect(find.byIcon(Icons.date_range_outlined), findsOneWidget);
  });

  testWidgets('la voz dice la etiqueta, el rango y que se puede cambiar', (
    tester,
  ) async {
    await _pump(tester, onChanged: (_) {});
    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(
        'Fechas: 01/10/2026 – 31/10/2026. Toca para cambiarlo',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('al tocarlo abre el calendario con el rango actual', (
    tester,
  ) async {
    await _pump(tester, onChanged: (_) {});
    await tester.tap(find.byIcon(Icons.date_range_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    final dialog = tester.widget<DateRangePickerDialog>(
      find.byType(DateRangePickerDialog),
    );
    expect(dialog.initialDateRange, _range);
    expect(dialog.firstDate, DateTime(2000));
    expect(dialog.lastDate, DateTime(2027, 12, 31));
  });

  testWidgets('elegir días y guardar avisa con el rango nuevo', (tester) async {
    final received = <DateTimeRange>[];
    await _pump(tester, onChanged: received.add);

    await tester.tap(find.byIcon(Icons.date_range_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('20').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(received, hasLength(1));
    expect(received.single.start, DateTime(2026, 10, 10));
    expect(received.single.end, DateTime(2026, 10, 20));
    expect(find.byType(DateRangePickerDialog), findsNothing);
  });

  testWidgets('cerrar el calendario sin guardar no avisa', (tester) async {
    final received = <DateTimeRange>[];
    await _pump(tester, onChanged: received.add);

    await tester.tap(find.byIcon(Icons.date_range_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();

    expect(received, isEmpty);
    expect(find.byType(DateRangePickerDialog), findsNothing);
  });

  testWidgets('no desborda a 320 px con texto 1.5', (tester) async {
    await _pump(tester, onChanged: (_) {}, width: 320, textScale: 1.5);
    expect(tester.takeException(), isNull);
    expect(find.text('01/10/2026 – 31/10/2026'), findsOneWidget);
  });
}
