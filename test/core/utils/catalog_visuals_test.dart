import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/utils/catalog_visuals.dart';

void main() {
  const fallbackIcon = Icons.help_outline;
  const fallbackColor = Color(0xFF123456);

  group('catálogo de iconos', () {
    test('hay iconos y sus llaves no se repiten', () {
      final keys = CatalogVisuals.icons.map((i) => i.key).toList();
      expect(keys, isNotEmpty);
      expect(keys.toSet(), hasLength(keys.length));
    });

    test('toda llave cumple el contrato del servidor ^[a-z0-9_]{1,40}\$', () {
      final contract = RegExp(r'^[a-z0-9_]{1,40}$');
      for (final icon in CatalogVisuals.icons) {
        expect(contract.hasMatch(icon.key), isTrue, reason: icon.key);
      }
    });

    test('cada icono tiene etiqueta en español para mostrar y buscar', () {
      for (final icon in CatalogVisuals.icons) {
        expect(icon.label.trim(), isNotEmpty, reason: icon.key);
      }
    });

    test('incluye «otro», el comodín de la lista', () {
      expect(CatalogVisuals.option('otro'), isNotNull);
    });
  });

  group('paleta', () {
    test('30 colores, todos #RRGGBB, sin repetir', () {
      final contract = RegExp(r'^#[0-9A-Fa-f]{6}$');
      expect(CatalogVisuals.palette, hasLength(30));
      expect(CatalogVisuals.palette.toSet(), hasLength(30));
      for (final hex in CatalogVisuals.palette) {
        expect(contract.hasMatch(hex), isTrue, reason: hex);
      }
    });

    test('hexOf(colorFor(hex)) devuelve el mismo hex para toda la paleta', () {
      for (final hex in CatalogVisuals.palette) {
        final color = CatalogVisuals.colorFor(hex, fallback: fallbackColor);
        expect(CatalogVisuals.hexOf(color), hex.toUpperCase());
      }
    });
  });

  group('CatalogVisuals.iconFor', () {
    test('una llave conocida da su icono', () {
      expect(
        CatalogVisuals.iconFor('gasolina', fallback: fallbackIcon),
        Icons.local_gas_station_rounded,
      );
    });

    test('todas las llaves del catálogo resuelven a su propio icono', () {
      for (final icon in CatalogVisuals.icons) {
        expect(
          CatalogVisuals.iconFor(icon.key, fallback: fallbackIcon),
          icon.icon,
          reason: icon.key,
        );
      }
    });

    test('nula, vacía, desconocida o con otra capitalización: el respaldo', () {
      for (final key in [null, '', ' ', 'no_existe', 'GASOLINA', 'gasolina ']) {
        expect(
          CatalogVisuals.iconFor(key, fallback: fallbackIcon),
          fallbackIcon,
          reason: 'llave «$key»',
        );
      }
    });

    test('una llave con formato inválido no lanza', () {
      expect(
        () => CatalogVisuals.iconFor('¡raro!{}', fallback: fallbackIcon),
        returnsNormally,
      );
    });
  });

  group('CatalogVisuals.option', () {
    test('nula y desconocida: null', () {
      expect(CatalogVisuals.option(null), isNull);
      expect(CatalogVisuals.option('xyz'), isNull);
    });

    test('conocida: la opción con su llave', () {
      final option = CatalogVisuals.option('comida');
      expect(option, isNotNull);
      expect(option!.key, 'comida');
      expect(option.label, 'Comida');
    });
  });

  group('CatalogVisuals.colorFor', () {
    test('#RRGGBB válido: color opaco con esos canales', () {
      final color = CatalogVisuals.colorFor('#2DD4BF', fallback: fallbackColor);
      expect(color.toARGB32(), 0xFF2DD4BF);
    });

    test('acepta minúsculas', () {
      expect(
        CatalogVisuals.colorFor('#2dd4bf', fallback: fallbackColor).toARGB32(),
        0xFF2DD4BF,
      );
    });

    test('bordes válidos: negro y blanco', () {
      expect(
        CatalogVisuals.colorFor('#000000', fallback: fallbackColor).toARGB32(),
        0xFF000000,
      );
      expect(
        CatalogVisuals.colorFor('#FFFFFF', fallback: fallbackColor).toARGB32(),
        0xFFFFFFFF,
      );
    });

    test('inválidos o ausentes: el respaldo, sin fallar', () {
      final invalid = <String?>[
        null,
        '',
        '2DD4BF', // sin #
        '#2DD4B', // corto
        '#2DD4BFF', // largo
        '#GGGGGG', // no hex
        '#2DD4BF80', // con alfa: no es #RRGGBB
        'rojo',
        ' #2DD4BF', // con espacio
        '#2DD4BF ',
      ];
      for (final hex in invalid) {
        expect(
          CatalogVisuals.colorFor(hex, fallback: fallbackColor),
          fallbackColor,
          reason: 'hex «$hex»',
        );
      }
    });
  });

  group('CatalogVisuals.hexOf', () {
    test('mayúsculas y # delante', () {
      expect(CatalogVisuals.hexOf(const Color(0xFF2DD4BF)), '#2DD4BF');
    });

    test('rellena con ceros a la izquierda', () {
      expect(CatalogVisuals.hexOf(const Color(0xFF000001)), '#000001');
      expect(CatalogVisuals.hexOf(const Color(0xFF000000)), '#000000');
    });

    test('ignora el alfa', () {
      expect(CatalogVisuals.hexOf(const Color(0x802DD4BF)), '#2DD4BF');
    });

    test('el resultado cumple el contrato #RRGGBB del servidor', () {
      expect(
        RegExp(r'^#[0-9A-F]{6}$')
            .hasMatch(CatalogVisuals.hexOf(const Color(0xFFABCDEF))),
        isTrue,
      );
    });
  });

  group('CatalogIcon.matches', () {
    final gasolina = CatalogVisuals.option('gasolina')!;

    test('búsqueda vacía o de espacios: coincide con todo', () {
      expect(gasolina.matches(''), isTrue);
      expect(gasolina.matches('   '), isTrue);
    });

    test('por etiqueta, sin importar mayúsculas ni espacios de los bordes', () {
      expect(gasolina.matches('gasolina'), isTrue);
      expect(gasolina.matches('  GASOLINA '), isTrue);
      expect(gasolina.matches('gaso'), isTrue);
    });

    test('por términos relacionados', () {
      expect(gasolina.matches('combustible'), isTrue);
      expect(gasolina.matches('tanqueo'), isTrue);
    });

    test('lo que no se relaciona no coincide', () {
      expect(gasolina.matches('pizza'), isFalse);
      expect(gasolina.matches('zzzz'), isFalse);
    });

    test('un icono sin términos solo coincide por etiqueta', () {
      final moto = CatalogVisuals.option('moto')!;
      expect(moto.terms, isEmpty);
      expect(moto.matches('moto'), isTrue);
      expect(moto.matches('carro'), isFalse);
    });

    test('«gasolina» en el catálogo completo encuentra el icono esperado', () {
      final found = CatalogVisuals.icons.where((i) => i.matches('gasolina'));
      expect(found.map((i) => i.key), contains('gasolina'));
    });

    test('una búsqueda sin sentido no encuentra ninguno', () {
      expect(CatalogVisuals.icons.where((i) => i.matches('xqzwv')), isEmpty);
    });
  });

  group('CatalogVisuals.readable', () {
    const yellow = Color(0xFFFACC15); // muy claro
    const navy = Color(0xFF1E3A8A); // ya oscuro

    test('tema oscuro: el color tal cual', () {
      AppColors.apply(Brightness.dark);
      for (final hex in CatalogVisuals.palette) {
        final color = CatalogVisuals.colorFor(hex, fallback: fallbackColor);
        expect(CatalogVisuals.readable(color), color, reason: hex);
      }
    });

    test('tema claro: un color oscuro no cambia', () {
      AppColors.apply(Brightness.light);
      expect(CatalogVisuals.readable(navy), navy);
    });

    test('tema claro: un color claro se oscurece a luminosidad 0,4', () {
      AppColors.apply(Brightness.light);

      final result = CatalogVisuals.readable(yellow);

      expect(HSLColor.fromColor(result).lightness, closeTo(0.4, 0.01));
      expect(result.computeLuminance(), lessThan(yellow.computeLuminance()));
    });

    test('tema claro: conserva el tono y la saturación', () {
      AppColors.apply(Brightness.light);
      final before = HSLColor.fromColor(yellow);

      final after = HSLColor.fromColor(CatalogVisuals.readable(yellow));

      expect(after.hue, closeTo(before.hue, 1.5));
      expect(after.saturation, closeTo(before.saturation, 0.02));
    });

    test('tema claro: toda la paleta queda con luminosidad ≤ 0,4', () {
      AppColors.apply(Brightness.light);
      for (final hex in CatalogVisuals.palette) {
        final color = CatalogVisuals.colorFor(hex, fallback: fallbackColor);
        expect(
          HSLColor.fromColor(CatalogVisuals.readable(color)).lightness,
          lessThanOrEqualTo(0.4 + 0.01),
          reason: hex,
        );
      }
    });

    test('tema claro: es idempotente (oscurecer dos veces no cambia)', () {
      AppColors.apply(Brightness.light);
      final once = CatalogVisuals.readable(yellow);

      expect(CatalogVisuals.readable(once), once);
    });

    test('blanco y negro no revientan', () {
      AppColors.apply(Brightness.light);
      expect(
        HSLColor.fromColor(CatalogVisuals.readable(const Color(0xFFFFFFFF)))
            .lightness,
        closeTo(0.4, 0.01),
      );
      expect(
        CatalogVisuals.readable(const Color(0xFF000000)),
        const Color(0xFF000000),
      );
    });
  });
}
