import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/features/catalogs/providers/save_catalog_providers.dart';
import 'package:sistema_cuentas/features/catalogs/utils/catalog_rules.dart';
import 'package:sistema_cuentas/shared/utils/listen_save.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_text_field.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_pair.dart';
import 'package:sistema_cuentas/shared/widgets/app_switch_tile.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_choice.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_field.dart';

Future<void> showContactDialog(BuildContext context, {Contact? contact}) =>
    showDialog<void>(
      context: context,
      builder: (_) => ContactDialog(contact: contact),
    );

/// Crear o editar un contacto: la persona con la que se tiene un acuerdo.
class ContactDialog extends ConsumerStatefulWidget {
  const ContactDialog({super.key, this.contact});

  final Contact? contact;

  @override
  ConsumerState<ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends ConsumerState<ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.contact?.name);
  late final _phone = TextEditingController(text: widget.contact?.phone);
  late final _note = TextEditingController(text: widget.contact?.note);
  late var _active = widget.contact?.active ?? true;
  late var _visual = CatalogVisualChoice(
    icon: widget.contact?.icon,
    color: widget.contact?.color,
  );
  var _visualChanged = false;

  /// El nombre que se ve al elegir su icono (puede no estar escrito aún).
  String _subject() =>
      _name.text.trim().isEmpty ? 'Nuevo contacto' : _name.text;

  void _onVisualChanged(CatalogVisualChoice choice) => setState(() {
    _visual = choice;
    _visualChanged = true;
  });

  bool get _editing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    listenSave(
      ref,
      saveContactProvider,
      successMessage: _editing ? 'Contacto actualizado' : 'Contacto creado',
      onSuccess: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(saveContactProvider.notifier)
        .save(
          CatalogRules.contactDraft(
            id: widget.contact?.id,
            name: _name.text,
            phone: _phone.text,
            note: _note.text,
            active: _active,
            icon: _visual.icon,
            color: _visual.color,
            visualChanged: _visualChanged,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(saveContactProvider.select((s) => s.isLoading));
    return AppFormDialog(
      icon: Icons.person_outline_rounded,
      title: _editing ? 'Editar contacto' : 'Nuevo contacto',
      formKey: _formKey,
      loading: loading,
      confirmLabel: 'Guardar',
      onConfirm: _confirm,
      children: [
        AppFormPair(
          first: TextFormField(
            controller: _name,
            readOnly: loading,
            maxLength: CatalogRules.contactNameMax,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              counterText: '',
            ),
            validator: CatalogRules.validateContactName,
          ),
          second: TextFormField(
            controller: _phone,
            readOnly: loading,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              LengthLimitingTextInputFormatter(CatalogRules.phoneMax),
            ],
            decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
            validator: CatalogRules.validatePhone,
          ),
        ),
        MovementTextField(
          controller: _note,
          readOnly: loading,
          label: 'Nota (opcional)',
          maxLines: 2,
          maxLength: CatalogRules.noteMax,
        ),
        CatalogVisualField(
          choice: _visual,
          subject: _subject,
          fallbackIcon: Icons.person_outline_rounded,
          enabled: !loading,
          onChanged: _onVisualChanged,
        ),
        if (_editing)
          AppSwitchTile(
            title: 'Activo',
            value: _active,
            onChanged: loading
                ? null
                : (value) => setState(() => _active = value),
          ),
      ],
    );
  }
}
