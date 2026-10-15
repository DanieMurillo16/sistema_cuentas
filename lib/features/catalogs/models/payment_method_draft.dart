/// Crear o editar un medio de pago.
class PaymentMethodDraft {
  const PaymentMethodDraft({required this.name, required this.active, this.id});

  final int? id;
  final String name;
  final bool active;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id_medio': id,
    'nombre': name,
    'activo': active,
  };
}
