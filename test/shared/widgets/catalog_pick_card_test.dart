import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_pick_card.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_option.dart';

const _nequi = CatalogPickerOption<Object>(
  value: 'n',
  label: 'nequi',
  icon: Icons.account_balance_wallet_outlined,
  color: Colors.teal,
);

/// La tarjeta dentro de un `Form`, para poder validarla como lo hace el
/// formulario de movimientos.
class _Host extends StatelessWidget {
  const _Host({
    required this.formKey,
    required this.selected,
    required this.onTap,
    this.validator,
  });

  final GlobalKey<FormState> formKey;
  final CatalogPickerOption<Object>? selected;
  final VoidCallback onTap;
  final String? Function()? validator;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CatalogPickCard(
            label: 'Medio de pago',
            placeholderIcon: Icons.account_balance_wallet_outlined,
            selected: selected,
            onTap: onTap,
            validator: validator,
          ),
        ),
      ),
    ),
  );
}

Finder get _card => find.byType(CatalogPickCard);

void main() {
  final formKey = GlobalKey<FormState>();

  testWidgets('vacía: etiqueta, «Elegir» y el icono de relleno', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Host(formKey: formKey, selected: null, onTap: () {}),
    );

    expect(find.text('Medio de pago'), findsOneWidget);
    expect(find.text('Elegir'), findsOneWidget);
    expect(
      find.descendant(
        of: _card,
        matching: find.byIcon(Icons.account_balance_wallet_outlined),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
  });

  testWidgets('con valor: su nombre (con inicial mayúscula) y no «Elegir»', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Host(formKey: formKey, selected: _nequi, onTap: () {}),
    );

    expect(find.text('Nequi'), findsOneWidget);
    expect(find.text('nequi'), findsNothing);
    expect(find.text('Elegir'), findsNothing);
  });

  testWidgets('tocarla llama a onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _Host(formKey: formKey, selected: null, onTap: () => taps++),
    );

    await tester.tap(
      find.descendant(of: _card, matching: find.byType(InkWell)),
    );

    expect(taps, 1);
  });

  testWidgets(
    'error: aparece dentro de la tarjeta, bajo el valor, en rojo, y se va al elegir algo',
    (tester) async {
      String? rule(CatalogPickerOption<Object>? value) =>
          value == null ? 'Elige el medio de pago.' : null;
      Widget host(CatalogPickerOption<Object>? selected) => _Host(
        formKey: formKey,
        selected: selected,
        onTap: () {},
        validator: () => rule(selected),
      );

      await tester.pumpWidget(host(null));
      expect(find.text('Elige el medio de pago.'), findsNothing);

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      final error = find.text('Elige el medio de pago.');
      expect(error, findsOneWidget);
      expect(
        tester.getTopLeft(error).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.text('Elegir')).dy),
        reason: 'el mensaje va debajo del valor, dentro de la tarjeta',
      );
      expect(
        tester.getBottomLeft(error).dy,
        lessThanOrEqualTo(tester.getBottomLeft(find.byType(InkWell).first).dy),
      );
      expect(tester.widget<Text>(error).style?.color, AppColors.expense);

      await tester.pumpWidget(host(_nequi));
      expect(find.text('Elige el medio de pago.'), findsNothing);
      expect(formKey.currentState!.validate(), isTrue);
    },
  );

  testWidgets(
    'semántica: botón con su etiqueta (y el valor) y acción de tocar',
    (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _Host(formKey: formKey, selected: null, onTap: () => taps++),
      );

      final data = tester
          .getSemantics(find.bySemanticsLabel('Medio de pago'))
          .getSemanticsData();
      expect(data.label, 'Medio de pago');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      tester.semantics.tap(find.semantics.byLabel('Medio de pago'));
      expect(taps, 1);

      await tester.pumpWidget(
        _Host(formKey: formKey, selected: _nequi, onTap: () => taps++),
      );
      expect(find.bySemanticsLabel('Medio de pago, Nequi'), findsOneWidget);
      handle.dispose();
    },
  );
}
