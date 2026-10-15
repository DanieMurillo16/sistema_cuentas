import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/network/api_client.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/category_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';

final catalogsRepositoryProvider = Provider<CatalogsRepository>(
  (ref) => CatalogsRepository(ref.watch(apiClientProvider)),
);

/// Única puerta a categorías y medios de pago.
class CatalogsRepository {
  const CatalogsRepository(this._api);

  final ApiClient _api;

  /// Todas, también las inactivas: Ajustes las edita y los selectores filtran
  /// las activas.
  Future<List<Category>> categories() async {
    final data = await _api.get(
      ApiEndpoints.categories,
      queryParameters: {'incluir_inactivas': 1},
    );
    return parseApi(
      () => [
        for (final item in data['categorias'] as List)
          Category.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }

  Future<List<PaymentMethod>> paymentMethods() async {
    final data = await _api.get(
      ApiEndpoints.paymentMethods,
      queryParameters: {'incluir_inactivos': 1},
    );
    return parseApi(
      () => [
        for (final item in data['medios_pago'] as List)
          PaymentMethod.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }

  Future<List<Contact>> contacts() async {
    final data = await _api.get(
      ApiEndpoints.contacts,
      queryParameters: {'incluir_inactivos': 1},
    );
    return parseApi(
      () => [
        for (final item in data['contactos'] as List)
          Contact.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }

  Future<Category> saveCategory(CategoryDraft draft) async {
    final data = await _api.post(
      ApiEndpoints.categorySave,
      data: draft.toJson(),
    );
    return parseApi(
      () => Category.fromJson(
        Map<String, dynamic>.from(data['categoria'] as Map),
      ),
    );
  }

  /// Elimina la categoría: lo ya registrado con ella se conserva, pero no se
  /// puede usar en nada nuevo. Quien la creó puede, sin permiso aparte.
  Future<void> deleteCategory(int id) async {
    await _api.post(ApiEndpoints.categoryDelete, data: {'id_categoria': id});
  }

  Future<PaymentMethod> savePaymentMethod(PaymentMethodDraft draft) async {
    final data = await _api.post(
      ApiEndpoints.paymentMethodSave,
      data: draft.toJson(),
    );
    return parseApi(
      () => PaymentMethod.fromJson(
        Map<String, dynamic>.from(data['medio_pago'] as Map),
      ),
    );
  }

  Future<Contact> saveContact(ContactDraft draft) async {
    final data = await _api.post(
      ApiEndpoints.contactSave,
      data: draft.toJson(),
    );
    return parseApi(
      () =>
          Contact.fromJson(Map<String, dynamic>.from(data['contacto'] as Map)),
    );
  }
}
