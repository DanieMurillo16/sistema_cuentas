import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/models/category_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method_draft.dart';

/// Reglas puras de los catálogos (categorías, medios de pago y contactos).
abstract final class CatalogRules {
  static const categoryNameMax = 60;
  static const methodNameMax = 50;
  static const contactNameMax = 100;
  static const phoneMin = 5;
  static const phoneMax = 20;
  static const noteMax = 255;

  static String? _name(
    String? value, {
    required int max,
    required String what,
  }) {
    final text = (value ?? '').trim();
    if (text.length < 2) return 'Escribe el nombre $what (mínimo 2 letras).';
    if (text.length > max) return 'Máximo $max caracteres.';
    return null;
  }

  static String? validateCategoryName(String? value) =>
      _name(value, max: categoryNameMax, what: 'de la categoría');

  static String? validateMethodName(String? value) =>
      _name(value, max: methodNameMax, what: 'del medio de pago');

  static String? validateContactName(String? value) =>
      _name(value, max: contactNameMax, what: 'del contacto');

  /// Opcional: vacío es válido; si hay algo, solo dígitos y ( ) - y espacios.
  static String? validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (!RegExp(r'^[0-9()\- +]+$').hasMatch(text)) {
      return 'Solo números, espacios, + ( ) y -.';
    }
    if (text.length < phoneMin || text.length > phoneMax) {
      return 'Entre $phoneMin y $phoneMax caracteres.';
    }
    return null;
  }

  static CategoryDraft categoryDraft({
    int? id,
    required MovementType type,
    required String name,
    required bool isCapital,
    required bool active,
    String? icon,
    String? color,
    bool visualChanged = false,
  }) => CategoryDraft(
    id: id,
    type: type,
    name: name.trim(),
    isCapital: isCapital,
    active: active,
    icon: icon,
    color: color,
    visualChanged: visualChanged,
  );

  static PaymentMethodDraft methodDraft({
    int? id,
    required String name,
    required bool active,
  }) => PaymentMethodDraft(id: id, name: name.trim(), active: active);

  static ContactDraft contactDraft({
    int? id,
    required String name,
    required String phone,
    required String note,
    required bool active,
    String? icon,
    String? color,
    bool visualChanged = false,
  }) {
    final trimmedPhone = phone.trim();
    final trimmedNote = note.trim();
    return ContactDraft(
      id: id,
      name: name.trim(),
      active: active,
      phone: trimmedPhone.isEmpty ? null : trimmedPhone,
      note: trimmedNote.isEmpty ? null : trimmedNote,
      icon: icon,
      color: color,
      visualChanged: visualChanged,
    );
  }
}
