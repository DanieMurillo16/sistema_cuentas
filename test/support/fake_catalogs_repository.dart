import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/category_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';

/// Repositorio de catálogos falso.
class FakeCatalogsRepository implements CatalogsRepository {
  FakeCatalogsRepository({
    this.onCategories,
    this.onMethods,
    this.onContacts,
    this.onSaveCategory,
    this.onSaveMethod,
    this.onSaveContact,
    this.onDeleteCategory,
  });

  Future<List<Category>> Function()? onCategories;
  Future<List<PaymentMethod>> Function()? onMethods;
  Future<List<Contact>> Function()? onContacts;
  Future<Category> Function(CategoryDraft draft)? onSaveCategory;
  Future<PaymentMethod> Function(PaymentMethodDraft draft)? onSaveMethod;
  Future<Contact> Function(ContactDraft draft)? onSaveContact;
  Future<void> Function(int id)? onDeleteCategory;

  int categoriesCalls = 0;
  int methodsCalls = 0;
  int contactsCalls = 0;

  /// Lo que se mandó a guardar, en orden.
  final savedCategories = <CategoryDraft>[];
  final savedMethods = <PaymentMethodDraft>[];
  final savedContacts = <ContactDraft>[];

  /// Los ids de categoría que se mandaron eliminar, en orden.
  final deletedCategories = <int>[];

  @override
  Future<List<Category>> categories() async {
    categoriesCalls++;
    return onCategories == null ? const [] : onCategories!();
  }

  @override
  Future<List<PaymentMethod>> paymentMethods() async {
    methodsCalls++;
    return onMethods == null ? const [] : onMethods!();
  }

  @override
  Future<List<Contact>> contacts() async {
    contactsCalls++;
    return onContacts == null ? const [] : onContacts!();
  }

  @override
  Future<Category> saveCategory(CategoryDraft draft) {
    savedCategories.add(draft);
    return onSaveCategory!(draft);
  }

  @override
  Future<void> deleteCategory(int id) async {
    deletedCategories.add(id);
    await onDeleteCategory?.call(id);
  }

  @override
  Future<PaymentMethod> savePaymentMethod(PaymentMethodDraft draft) {
    savedMethods.add(draft);
    return onSaveMethod!(draft);
  }

  @override
  Future<Contact> saveContact(ContactDraft draft) {
    savedContacts.add(draft);
    return onSaveContact!(draft);
  }
}
