import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/shared/utils/search_options.dart';
import 'package:sistema_cuentas/shared/widgets/search_dropdown_menu.dart';

class AppSearchDropdown<T extends Object> extends StatefulWidget {
  const AppSearchDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.validator,
    this.showSearchIcon = true,
    this.onCleared,
  });
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;
  final bool showSearchIcon;

  /// Si se pasa y hay algo elegido, aparece una «×» para quitarlo (un filtro
  /// opcional: sin elegir = todas).
  final VoidCallback? onCleared;

  @override
  State<AppSearchDropdown<T>> createState() => _AppSearchDropdownState<T>();
}

class _AppSearchDropdownState<T extends Object>
    extends State<AppSearchDropdown<T>> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _fieldKey = GlobalKey<FormFieldState<T>>();

  String get _selectedLabel => widget.value == null
      ? ''
      : formatDisplayText(widget.itemLabel(widget.value!));

  @override
  void initState() {
    super.initState();
    _controller.text = _selectedLabel;
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AppSearchDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.value == null
        ? ''
        : formatDisplayText(oldWidget.itemLabel(oldWidget.value!));
    if (previous != _selectedLabel) _controller.text = _selectedLabel;
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) {
      // Recalcular las sugerencias también al reabrir con la misma selección.
      _controller.clear();
      _controller.value = TextEditingValue(
        text: _selectedLabel,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: _selectedLabel.length,
        ),
      );
    } else {
      // La búsqueda es visual; solo seleccionar una opción cambia el dato.
      _controller.text = _selectedLabel;
    }
  }

  void _select(T item) {
    _fieldKey.currentState?.didChange(item);
    widget.onChanged(item);
    _focus.unfocus();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => FormField<T>(
        key: _fieldKey,
        initialValue: widget.value,
        validator: (_) => widget.validator?.call(widget.value),
        builder: (field) => RawAutocomplete<T>(
          textEditingController: _controller,
          focusNode: _focus,
          displayStringForOption: (item) =>
              formatDisplayText(widget.itemLabel(item)),
          optionsBuilder: (text) => searchOptions(
            widget.items,
            widget.itemLabel,
            text.text == _selectedLabel ? '' : text.text,
          ),
          onSelected: _select,
          optionsViewBuilder: (context, select, options) =>
              SearchDropdownMenu<T>(
                width: constraints.maxWidth,
                options: options.toList(),
                itemLabel: widget.itemLabel,
                onSelected: select,
              ),
          fieldViewBuilder: (context, controller, focus, submit) => TextField(
            controller: controller,
            focusNode: focus,
            onSubmitted: (_) => submit(),
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: field.errorText,
              prefixIcon: widget.showSearchIcon
                  ? const Icon(Icons.search_rounded)
                  : null,
              suffixIcon: widget.onCleared != null && widget.value != null
                  ? IconButton(
                      tooltip: 'Quitar',
                      onPressed: widget.onCleared,
                      icon: const Icon(Icons.close_rounded),
                    )
                  : IconButton(
                      tooltip: 'Buscar opciones',
                      onPressed: () {
                        if (focus.hasFocus) {
                          focus.unfocus();
                        } else {
                          focus.requestFocus();
                        }
                      },
                      icon: const Icon(Icons.expand_more_rounded),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
