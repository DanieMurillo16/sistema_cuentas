import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/category_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact_draft.dart';
import 'package:sistema_cuentas/features/catalogs/utils/catalog_rules.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/recurring_fixtures.dart';

void main() {
  group('Category.fromJson: icono y color', () {
    test('los lee tal cual vienen', () {
      final c = Category.fromJson(
        categoryJson(icon: 'gasolina', color: '#FB923C'),
      );
      expect(c.icon, 'gasolina');
      expect(c.color, '#FB923C');
    });

    test('si el servidor no los manda (versión vieja): null, sin fallar', () {
      final c = Category.fromJson(categoryJson());
      expect(c.icon, isNull);
      expect(c.color, isNull);
    });

    test('null, vacíos o de espacios quedan en null', () {
      final c = Category.fromJson(
        categoryJson()
          ..['icono'] = null
          ..['color'] = '   ',
      );
      expect(c.icon, isNull);
      expect(c.color, isNull);
      expect(Category.fromJson(categoryJson()..['icono'] = '').icon, isNull);
    });

    test('un icono sin color (y al revés) se conserva por separado', () {
      final onlyIcon = Category.fromJson(categoryJson(icon: 'casa'));
      expect(onlyIcon.icon, 'casa');
      expect(onlyIcon.color, isNull);
      final onlyColor = Category.fromJson(categoryJson(color: '#34D399'));
      expect(onlyColor.icon, isNull);
      expect(onlyColor.color, '#34D399');
    });

    test(
      'valores desconocidos no rompen el modelo (se resuelven al pintar)',
      () {
        final c = Category.fromJson(
          categoryJson(icon: 'icono_del_futuro', color: 'no-es-hex'),
        );
        expect(c.icon, 'icono_del_futuro');
        expect(c.color, 'no-es-hex');
      },
    );
  });

  group('Contact.fromJson: icono y color', () {
    test('los lee tal cual vienen', () {
      final c = Contact.fromJson(
        contactJson(icon: 'persona', color: '#818CF8'),
      );
      expect(c.icon, 'persona');
      expect(c.color, '#818CF8');
    });

    test('si faltan: null', () {
      final c = Contact.fromJson(contactJson());
      expect(c.icon, isNull);
      expect(c.color, isNull);
    });

    test('vacíos o null: null', () {
      final c = Contact.fromJson(
        contactJson()
          ..['icono'] = ''
          ..['color'] = null,
      );
      expect(c.icon, isNull);
      expect(c.color, isNull);
    });
  });

  group('CategoryDraft.toJson: icono y color solo si visualChanged', () {
    CategoryDraft draft({
      String? icon,
      String? color,
      bool visualChanged = false,
      int? id,
    }) => CategoryDraft(
      id: id,
      type: MovementType.expense,
      name: 'Gasolina',
      isCapital: false,
      active: true,
      icon: icon,
      color: color,
      visualChanged: visualChanged,
    );

    test('sin tocar el selector NO manda icono ni color (aunque existan)', () {
      final json = draft(icon: 'gasolina', color: '#FB923C', id: 3).toJson();
      expect(json.containsKey('icono'), isFalse);
      expect(json.containsKey('color'), isFalse);
    });

    test('por defecto visualChanged es falso', () {
      expect(
        const CategoryDraft(
          type: MovementType.expense,
          name: 'x',
          isCapital: false,
          active: true,
        ).visualChanged,
        isFalse,
      );
    });

    test('al elegir manda ambos', () {
      final json = draft(
        icon: 'gasolina',
        color: '#FB923C',
        visualChanged: true,
      ).toJson();
      expect(json['icono'], 'gasolina');
      expect(json['color'], '#FB923C');
    });

    test('al quitar manda null en ambas llaves (no las omite)', () {
      final json = draft(visualChanged: true, id: 3).toJson();
      expect(json.containsKey('icono'), isTrue);
      expect(json.containsKey('color'), isTrue);
      expect(json['icono'], isNull);
      expect(json['color'], isNull);
    });

    test('solo el icono elegido: el color va como null (se quita)', () {
      final json = draft(icon: 'casa', visualChanged: true).toJson();
      expect(json['icono'], 'casa');
      expect(json.containsKey('color'), isTrue);
      expect(json['color'], isNull);
    });

    test('el resto del cuerpo no cambia por el selector', () {
      final json = draft(
        icon: 'casa',
        color: '#34D399',
        visualChanged: true,
      ).toJson();
      expect(json['tipo'], 'GASTO');
      expect(json['nombre'], 'Gasolina');
      expect(json['es_capital'], false);
      expect(json['activo'], true);
    });
  });

  group('ContactDraft.toJson: icono y color solo si visualChanged', () {
    test('sin tocar el selector: el cuerpo no lleva icono ni color', () {
      final json = const ContactDraft(
        id: 4,
        name: 'Oscar',
        active: true,
        icon: 'persona',
        color: '#818CF8',
      ).toJson();
      expect(json.containsKey('icono'), isFalse);
      expect(json.containsKey('color'), isFalse);
      expect(json, {'id_contacto': 4, 'nombre': 'Oscar', 'activo': true});
    });

    test('al elegir manda ambos junto con teléfono y nota', () {
      final json = const ContactDraft(
        name: 'Oscar',
        active: true,
        phone: '3001234567',
        note: 'paga el 7',
        icon: 'persona',
        color: '#818CF8',
        visualChanged: true,
      ).toJson();
      expect(json, {
        'nombre': 'Oscar',
        'activo': true,
        'telefono': '3001234567',
        'nota': 'paga el 7',
        'icono': 'persona',
        'color': '#818CF8',
      });
    });

    test('al quitar manda null en ambas llaves', () {
      final json = const ContactDraft(
        id: 4,
        name: 'Oscar',
        active: true,
        visualChanged: true,
      ).toJson();
      expect(json.containsKey('icono'), isTrue);
      expect(json.containsKey('color'), isTrue);
      expect(json['icono'], isNull);
      expect(json['color'], isNull);
    });
  });

  group('CatalogRules: pasa icono, color y visualChanged', () {
    test('categoryDraft sin selector: visualChanged falso y sin icono', () {
      final draft = CatalogRules.categoryDraft(
        type: MovementType.expense,
        name: ' Gasolina ',
        isCapital: false,
        active: true,
      );
      expect(draft.visualChanged, isFalse);
      expect(draft.icon, isNull);
      expect(draft.color, isNull);
      expect(draft.toJson().containsKey('icono'), isFalse);
    });

    test('categoryDraft con elección: los conserva y los manda', () {
      final draft = CatalogRules.categoryDraft(
        type: MovementType.expense,
        name: 'Gasolina',
        isCapital: false,
        active: true,
        icon: 'gasolina',
        color: '#FB923C',
        visualChanged: true,
      );
      expect(draft.icon, 'gasolina');
      expect(draft.color, '#FB923C');
      expect(draft.toJson()['icono'], 'gasolina');
      expect(draft.toJson()['color'], '#FB923C');
    });

    test('categoryDraft quitando: visualChanged con icono y color null', () {
      final draft = CatalogRules.categoryDraft(
        id: 3,
        type: MovementType.expense,
        name: 'Gasolina',
        isCapital: false,
        active: true,
        visualChanged: true,
      );
      expect(draft.toJson(), containsPair('icono', null));
      expect(draft.toJson(), containsPair('color', null));
    });

    test('contactDraft sin selector', () {
      final draft = CatalogRules.contactDraft(
        name: 'Oscar',
        phone: '',
        note: '',
        active: true,
      );
      expect(draft.visualChanged, isFalse);
      expect(draft.toJson().containsKey('icono'), isFalse);
    });

    test('contactDraft con elección', () {
      final draft = CatalogRules.contactDraft(
        name: 'Oscar',
        phone: '',
        note: '',
        active: true,
        icon: 'persona',
        color: '#818CF8',
        visualChanged: true,
      );
      expect(draft.icon, 'persona');
      expect(draft.color, '#818CF8');
      expect(draft.toJson()['icono'], 'persona');
    });

    test('contactDraft quitando manda null', () {
      final draft = CatalogRules.contactDraft(
        id: 4,
        name: 'Oscar',
        phone: '',
        note: '',
        active: true,
        visualChanged: true,
      );
      expect(draft.toJson(), containsPair('icono', null));
      expect(draft.toJson(), containsPair('color', null));
    });
  });
}
