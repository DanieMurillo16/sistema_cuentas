import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/providers/save_catalog_providers.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/category_delete_button.dart';
import 'package:sistema_cuentas/features/catalogs/utils/catalog_rules.dart';
import 'package:sistema_cuentas/shared/utils/listen_save.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/app_switch_tile.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle_option.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_choice.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_field.dart';

/// [initialType] solo se usa al crear: el tipo con el que arranca el alta.
Future<void> showCategoryDialog(
  BuildContext context, {
  Category? category,
  MovementType? initialType,
}) => showDialog<void>(
  context: context,
  builder: (_) => CategoryDialog(category: category, initialType: initialType),
);

/// Crear o editar una categoría. El tipo (ingreso o gasto) solo se elige al
/// crear: después no cambia.
class CategoryDialog extends ConsumerStatefulWidget {
  const CategoryDialog({super.key, this.category, this.initialType});

  final Category? category;
  final MovementType? initialType;

  @override
  ConsumerState<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name);
  late var _type =
      widget.category?.type ?? widget.initialType ?? MovementType.expense;
  late var _isCapital = widget.category?.isCapital ?? false;
  late var _active = widget.category?.active ?? true;
  late var _visual = CatalogVisualChoice(
    icon: widget.category?.icon,
    color: widget.category?.color,
  );
  var _visualChanged = false;

  /// El nombre que se ve al elegir su icono (puede no estar escrito aún).
  String _subject() =>
      _name.text.trim().isEmpty ? 'Nueva categoría' : _name.text;

  void _onVisualChanged(CatalogVisualChoice choice) => setState(() {
    _visual = choice;
    _visualChanged = true;
  });

  bool get _editing => widget.category != null;

  @override
  void initState() {
    super.initState();
    listenSave(
      ref,
      saveCategoryProvider,
      successMessage: _editing ? 'Categoría actualizada' : 'Categoría creada',
      onSuccess: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
    listenSave(
      ref,
      deleteCategoryProvider,
      successMessage: 'Categoría eliminada',
      onSuccess: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(saveCategoryProvider.notifier)
        .save(
          CatalogRules.categoryDraft(
            id: widget.category?.id,
            type: _type,
            name: _name.text,
            isCapital: _isCapital,
            active: _active,
            icon: _visual.icon,
            color: _visual.color,
            visualChanged: _visualChanged,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(saveCategoryProvider.select((s) => s.isLoading));
    final deleting = ref.watch(
      deleteCategoryProvider.select((s) => s.isLoading),
    );
    final loading = saving || deleting;
    return AppFormDialog(
      icon: Icons.sell_outlined,
      title: _editing ? 'Editar categoría' : 'Nueva categoría',
      formKey: _formKey,
      loading: saving,
      locked: deleting,
      confirmLabel: 'Guardar',
      onConfirm: _confirm,
      secondaryAction: _editing
          ? CategoryDeleteButton(category: widget.category!, enabled: !loading)
          : null,
      children: [
        _TypeToggle(
          selected: _type,
          enabled: !_editing && !loading,
          onSelected: (value) => setState(() => _type = value),
        ),
        TextFormField(
          controller: _name,
          readOnly: loading,
          maxLength: CatalogRules.categoryNameMax,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            counterText: '',
          ),
          validator: CatalogRules.validateCategoryName,
        ),
        CatalogVisualField(
          choice: _visual,
          subject: _subject,
          fallbackIcon: _type.isIncome
              ? Icons.south_west_rounded
              : Icons.north_east_rounded,
          enabled: !loading,
          onChanged: _onVisualChanged,
        ),
        AppSwitchTile(
          title: 'Es de capital',
          subtitle: 'Se separa de lo operativo en el resumen',
          value: _isCapital,
          onChanged: loading
              ? null
              : (value) => setState(() => _isCapital = value),
        ),
        if (_editing)
          AppSwitchTile(
            title: 'Activa',
            value: _active,
            onChanged: loading
                ? null
                : (value) => setState(() => _active = value),
          ),
      ],
    );
  }
}

/// Ingreso o gasto: solo se elige al crear, después no cambia.
class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final MovementType selected;
  final bool enabled;
  final ValueChanged<MovementType> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppToggle<MovementType>(
      selected: selected,
      enabled: enabled,
      onSelected: onSelected,
      options: const [
        AppToggleOption(
          value: MovementType.income,
          label: 'Ingreso',
          color: AppColors.success,
        ),
        AppToggleOption(
          value: MovementType.expense,
          label: 'Gasto',
          color: AppColors.error,
        ),
      ],
    );
  }
}
