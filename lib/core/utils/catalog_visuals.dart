import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';

/// Un icono que se puede elegir para una categoría o un contacto. La [key] es
/// lo que guarda el servidor (no conoce la lista); [terms] sirven para buscar.
class CatalogIcon {
  const CatalogIcon(this.key, this.icon, this.label, [this.terms = '']);

  final String key;
  final IconData icon;
  final String label;
  final String terms;

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return '$label $terms'.toLowerCase().contains(needle);
  }
}

/// Iconos y colores que se pueden elegir, y cómo se leen los que guardó el
/// servidor. Un icono o color desconocido (de otra versión de la app) se
/// ignora: la fila vuelve a su aspecto por defecto, nunca falla.
abstract final class CatalogVisuals {
  static const icons = <CatalogIcon>[
    CatalogIcon(
      'comida',
      Icons.restaurant_rounded,
      'Comida',
      'restaurante almuerzo cena',
    ),
    CatalogIcon(
      'comida_rapida',
      Icons.fastfood_rounded,
      'Comida rápida',
      'hamburguesa pizza domicilio',
    ),
    CatalogIcon(
      'mercado',
      Icons.shopping_cart_rounded,
      'Mercado',
      'supermercado compras',
    ),
    CatalogIcon(
      'tienda',
      Icons.local_grocery_store_rounded,
      'Tienda',
      'abarrotes',
    ),
    CatalogIcon('cafe', Icons.local_cafe_rounded, 'Café', 'desayuno tinto'),
    CatalogIcon('bar', Icons.local_bar_rounded, 'Bar', 'licor cerveza fiesta'),
    CatalogIcon(
      'transporte',
      Icons.directions_bus_rounded,
      'Transporte',
      'bus metro pasaje',
    ),
    CatalogIcon(
      'gasolina',
      Icons.local_gas_station_rounded,
      'Gasolina',
      'combustible tanqueo',
    ),
    CatalogIcon(
      'carro',
      Icons.directions_car_rounded,
      'Carro',
      'vehículo parqueadero peaje',
    ),
    CatalogIcon('taxi', Icons.local_taxi_rounded, 'Taxi', 'uber'),
    CatalogIcon('moto', Icons.two_wheeler_rounded, 'Moto'),
    CatalogIcon('bicicleta', Icons.directions_bike_rounded, 'Bicicleta'),
    CatalogIcon('casa', Icons.home_rounded, 'Casa', 'hogar vivienda'),
    CatalogIcon(
      'arriendo',
      Icons.apartment_rounded,
      'Arriendo',
      'alquiler edificio',
    ),
    CatalogIcon('luz', Icons.bolt_rounded, 'Luz', 'energía servicios públicos'),
    CatalogIcon('agua', Icons.water_drop_rounded, 'Agua', 'acueducto'),
    CatalogIcon('internet', Icons.wifi_rounded, 'Internet', 'wifi'),
    CatalogIcon(
      'celular',
      Icons.smartphone_rounded,
      'Celular',
      'teléfono plan datos minutos',
    ),
    CatalogIcon(
      'reparaciones',
      Icons.build_rounded,
      'Reparaciones',
      'arreglos mantenimiento',
    ),
    CatalogIcon('aseo', Icons.cleaning_services_rounded, 'Aseo', 'limpieza'),
    CatalogIcon(
      'lavanderia',
      Icons.local_laundry_service_rounded,
      'Lavandería',
      'lavadero ropa',
    ),
    CatalogIcon('salud', Icons.medical_services_rounded, 'Salud', 'médico eps'),
    CatalogIcon(
      'farmacia',
      Icons.local_pharmacy_rounded,
      'Farmacia',
      'medicinas droguería',
    ),
    CatalogIcon(
      'hospital',
      Icons.local_hospital_rounded,
      'Hospital',
      'urgencias clínica',
    ),
    CatalogIcon(
      'deporte',
      Icons.fitness_center_rounded,
      'Deporte',
      'gimnasio gym',
    ),
    CatalogIcon(
      'belleza',
      Icons.content_cut_rounded,
      'Belleza',
      'peluquería barbería',
    ),
    CatalogIcon('ropa', Icons.checkroom_rounded, 'Ropa', 'vestuario zapatos'),
    CatalogIcon(
      'educacion',
      Icons.school_rounded,
      'Educación',
      'colegio universidad curso',
    ),
    CatalogIcon('libros', Icons.menu_book_rounded, 'Libros', 'lectura'),
    CatalogIcon('hijos', Icons.child_care_rounded, 'Hijos', 'niños bebé'),
    CatalogIcon(
      'mascotas',
      Icons.pets_rounded,
      'Mascotas',
      'perro gato veterinario',
    ),
    CatalogIcon(
      'cine',
      Icons.movie_rounded,
      'Cine',
      'películas entretenimiento',
    ),
    CatalogIcon('musica', Icons.music_note_rounded, 'Música', 'spotify'),
    CatalogIcon(
      'suscripcion',
      Icons.subscriptions_rounded,
      'Suscripción',
      'netflix streaming',
    ),
    CatalogIcon(
      'juegos',
      Icons.sports_esports_rounded,
      'Juegos',
      'videojuegos',
    ),
    CatalogIcon('viajes', Icons.flight_rounded, 'Viajes', 'vuelo vacaciones'),
    CatalogIcon('hotel', Icons.hotel_rounded, 'Hotel', 'hospedaje'),
    CatalogIcon('playa', Icons.beach_access_rounded, 'Paseo', 'playa descanso'),
    CatalogIcon(
      'regalo',
      Icons.card_giftcard_rounded,
      'Regalo',
      'detalle cumpleaños',
    ),
    CatalogIcon(
      'donacion',
      Icons.volunteer_activism_rounded,
      'Donación',
      'ayuda',
    ),
    CatalogIcon('seguro', Icons.shield_rounded, 'Seguro', 'póliza soat'),
    CatalogIcon(
      'impuestos',
      Icons.receipt_long_rounded,
      'Impuestos',
      'factura predial',
    ),
    CatalogIcon(
      'envios',
      Icons.local_shipping_rounded,
      'Envíos',
      'mensajería domicilio',
    ),
    CatalogIcon(
      'banco',
      Icons.account_balance_rounded,
      'Banco',
      'bancolombia cuenta',
    ),
    CatalogIcon(
      'tarjeta',
      Icons.credit_card_rounded,
      'Tarjeta',
      'crédito cuota',
    ),
    CatalogIcon(
      'billetera',
      Icons.account_balance_wallet_rounded,
      'Billetera',
      'nequi daviplata',
    ),
    CatalogIcon(
      'efectivo',
      Icons.payments_rounded,
      'Efectivo',
      'dinero billetes',
    ),
    CatalogIcon('ahorro', Icons.savings_rounded, 'Ahorro', 'alcancía'),
    CatalogIcon(
      'inversion',
      Icons.trending_up_rounded,
      'Inversión',
      'rendimientos capital intereses',
    ),
    CatalogIcon(
      'prestamo',
      Icons.handshake_rounded,
      'Préstamo',
      'deuda acuerdo',
    ),
    CatalogIcon(
      'cambio',
      Icons.currency_exchange_rounded,
      'Cambio',
      'dólares divisas',
    ),
    CatalogIcon(
      'trabajo',
      Icons.work_rounded,
      'Trabajo',
      'salario sueldo nómina',
    ),
    CatalogIcon(
      'software',
      Icons.code_rounded,
      'Software',
      'desarrollo programación',
    ),
    CatalogIcon(
      'computador',
      Icons.laptop_mac_rounded,
      'Computador',
      'freelance',
    ),
    CatalogIcon(
      'negocio',
      Icons.storefront_rounded,
      'Negocio',
      'local comercio',
    ),
    CatalogIcon('venta', Icons.sell_rounded, 'Venta', 'cobro'),
    CatalogIcon('caja', Icons.point_of_sale_rounded, 'Caja', 'ventas diarias'),
    CatalogIcon('bono', Icons.emoji_events_rounded, 'Bono', 'premio comisión'),
    CatalogIcon(
      'favorito',
      Icons.favorite_rounded,
      'Favorito',
      'pareja familia',
    ),
    CatalogIcon('persona', Icons.person_rounded, 'Persona', 'contacto amigo'),
    CatalogIcon('grupo', Icons.group_rounded, 'Grupo', 'equipo amigos'),
    CatalogIcon(
      'familia',
      Icons.family_restroom_rounded,
      'Familia',
      'padres hermanos',
    ),
    CatalogIcon(
      'empresa',
      Icons.business_rounded,
      'Empresa',
      'compañía cliente',
    ),
    CatalogIcon('estrella', Icons.star_rounded, 'Estrella', 'importante'),
    CatalogIcon('otro', Icons.category_rounded, 'Otro', 'varios general'),
  ];

  /// Colores de la paleta, en `#RRGGBB` (lo que se guarda).
  static const palette = <String>[
    '#EF4444',
    '#F87171',
    '#F97316',
    '#FB923C',
    '#F59E0B',
    '#FACC15',
    '#EAB308',
    '#84CC16',
    '#22C55E',
    '#34D399',
    '#10B981',
    '#14B8A6',
    '#2DD4BF',
    '#06B6D4',
    '#38BDF8',
    '#0EA5E9',
    '#3B82F6',
    '#60A5FA',
    '#6366F1',
    '#818CF8',
    '#8B5CF6',
    '#C084FC',
    '#D946EF',
    '#F472B6',
    '#EC4899',
    '#F43F5E',
    '#A16207',
    '#78716C',
    '#64748B',
    '#94A3B8',
  ];

  static final _byKey = {for (final icon in icons) icon.key: icon};
  static final _hex = RegExp(r'^#[0-9a-fA-F]{6}$');

  static CatalogIcon? option(String? key) => key == null ? null : _byKey[key];

  /// El icono guardado, o [fallback] si no hay o no se conoce.
  static IconData iconFor(String? key, {required IconData fallback}) =>
      option(key)?.icon ?? fallback;

  /// El color guardado (`#RRGGBB`), o [fallback] si no hay o es inválido.
  static Color colorFor(String? hex, {required Color fallback}) {
    if (hex == null || !_hex.hasMatch(hex)) return fallback;
    return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
  }

  /// El color tal cual en el tema oscuro; en el claro, más hondo para que un
  /// amarillo o un lima se lean sobre su propio tinte.
  static Color readable(Color color) {
    if (!AppColors.isLight) return color;
    final hsl = HSLColor.fromColor(color);
    return hsl.lightness <= 0.4 ? color : hsl.withLightness(0.4).toColor();
  }

  /// El `#RRGGBB` de un color de la paleta.
  static String hexOf(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
