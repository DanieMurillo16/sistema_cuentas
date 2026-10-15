import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/services/app_toast.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/providers/fly_targets_provider.dart';
import 'package:sistema_cuentas/shared/widgets/amount_flight.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_body.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/movements/providers/save_movement_provider.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_form_rules.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_amount_section.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_catalog_fields.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_save_bar.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_text_field.dart';

/// Formulario de ingreso o gasto. Solo guarda el estado visual (lo que se va
/// escribiendo y eligiendo); armar el envío es de `MovementFormRules` y guardar
/// es de `saveMovementProvider`.
class MovementForm extends ConsumerStatefulWidget {
  const MovementForm({super.key, required this.type});

  final MovementType type;

  @override
  ConsumerState<MovementForm> createState() => _MovementFormState();
}

class _MovementFormState extends ConsumerState<MovementForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _amountFocus = FocusNode();
  final _description = TextEditingController();
  var _date = dateOnly(DateTime.now());
  Category? _category;
  PaymentMethod? _method;
  final _saveKey = GlobalKey();
  var _addAnother = false;
  var _lastAmountPesos = 0;

  @override
  void initState() {
    super.initState();
    // Éxito o error al terminar de guardar ("estaba cargando → terminó").
    ref.listenManual(saveMovementProvider, (previous, next) {
      if (previous?.isLoading != true) return;
      // En Riverpod 3 un AsyncError conserva el valor anterior (`hasValue`
      // sigue en true): el error se mira primero y excluye al éxito.
      if (next.hasError) {
        AppToast.error(userErrorMessage(next.error));
      } else if (!next.isLoading) {
        _onSaved();
      }
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _amountFocus.dispose();
    _description.dispose();
    super.dispose();
  }

  void _setDate(DateTime date) => setState(() => _date = date);

  void _setAddAnother(bool value) => setState(() => _addAnother = value);

  void _setCategory(Category? value) => setState(() => _category = value);

  void _setMethod(PaymentMethod? value) => setState(() => _method = value);

  void _save() {
    final invalidDate = MovementFormRules.validateDate(
      _date,
      today: DateTime.now(),
    );
    if (invalidDate != null) {
      AppToast.warning(invalidDate);
      return;
    }
    final missing =
        MovementFormRules.validateCategory(_category) ??
        MovementFormRules.validatePaymentMethod(_method);
    if (!_formKey.currentState!.validate() || missing != null) {
      if (missing != null) AppToast.warning(missing);
      return;
    }
    final draft = MovementFormRules.buildDraft(
      type: widget.type,
      amountText: _amount.text,
      date: _date,
      description: _description.text,
      category: _category!,
      method: _method!,
    );
    _lastAmountPesos = draft.amountPesos;
    FocusScope.of(context).unfocus(); // el teclado no tapa la animación
    ref.read(saveMovementProvider.notifier).save(draft);
  }

  void _onSaved() {
    AppToast.success(
      widget.type.isIncome ? 'Ingreso registrado' : 'Gasto registrado',
    );
    _flyToCard();
    if (!_addAnother) {
      Navigator.of(context).pop();
      return;
    }
    // Se conservan fecha, categoría y medio: lo habitual es registrar varios
    // seguidos con los mismos datos.
    _amount.clear();
    _description.clear();
  }

  /// El monto sale del botón y vuela hasta la tarjeta de Ingresos o de Gastos
  /// de Inicio, donde la cifra se suma sola al llegar el total nuevo.
  void _flyToCard() {
    final box = _saveKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final targets = ref.read(flyTargetsProvider);
    final income = widget.type.isIncome;
    playAmountFlight(
      context: context,
      from: box.localToGlobal(box.size.center(Offset.zero)),
      target: income ? targets.income : targets.expense,
      // Con las cifras tapadas el vuelo tampoco las muestra.
      text: ref.read(balancesHiddenProvider)
          ? AnimatedNumberText.mask
          : formatCopSigned(income ? _lastAmountPesos : -_lastAmountPesos),
      color: income ? AppColors.success : AppColors.error,
    );
  }

  String get _saveLabel =>
      widget.type.isIncome ? 'Registrar ingreso' : 'Registrar gasto';

  String get _descriptionHint =>
      widget.type.isIncome ? '¿De dónde proviene?' : '¿En qué fue?';

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(saveMovementProvider.select((s) => s.isLoading));
    return PopScope(
      canPop: !loading,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormBody(
            shrink: true,
            formKey: _formKey,
            children: [
              MovementAmountSection(
                controller: _amount,
                focusNode: _amountFocus,
                type: widget.type,
                date: _date,
                enabled: !loading,
                onDateChanged: _setDate,
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              MovementTextField(
                controller: _description,
                readOnly: loading,
                label: 'Descripción (opcional)',
                hint: _descriptionHint,
                maxLength: MovementFormRules.descriptionMaxLength,
              ),
              const SizedBox(height: DesignTokens.spaceMd),
              MovementCatalogFields(
                type: widget.type,
                category: _category,
                method: _method,
                onCategoryChanged: _setCategory,
                onMethodChanged: _setMethod,
              ),
            ],
          ),
          MovementSaveBar(
            addAnother: _addAnother,
            onAddAnotherChanged: _setAddAnother,
            loading: loading,
            saveLabel: _saveLabel,
            saveKey: _saveKey,
            onSave: _save,
          ),
        ],
      ),
    );
  }
}
