import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/features/services/data/models/category_model.dart';
import 'package:login_signup/features/services/data/models/service_model.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/entities/service_price_type.dart';

/// Categoría como la devuelve `GET /categories` (con sus servicios).
Map<String, dynamic> backendCategory({
  String id = 'cat-1',
  String name = 'Cejas',
  Object? description = 'Diseño de cejas',
  Object? isActive = true,
  List<Map<String, dynamic>>? services,
}) =>
    {
      'id': id,
      'ownerId': 'owner-1',
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': '2026-10-21T08:00:00.000-05:00',
      'updatedAt': '2026-10-21T08:00:00.000-05:00',
      if (services != null) 'services': services,
    };

/// Servicio como lo devuelve `GET /services` (decimal como texto y la
/// categoría anidada, sin `services`).
Map<String, dynamic> backendService({
  String id = 'srv-1',
  String name = 'Cejas en hilo',
  Object? price = '45000.00',
  Object? duration = 60,
  bool withCategory = true,
}) =>
    {
      'id': id,
      'ownerId': 'owner-1',
      'name': name,
      'description': null,
      'price': price,
      'priceType': 'Precio variable',
      'duration': duration,
      'categoryId': 'cat-1',
      'color': '#FF5733',
      'image': null,
      'onlineBooking': true,
      'deposit': 5000,
      'isActive': true,
      'createdAt': '2026-10-21T08:00:00.000-05:00',
      'updatedAt': '2026-10-21T08:00:00.000-05:00',
      if (withCategory) 'category': backendCategory(),
    };

void main() {
  group('CategoryModel', () {
    test('fromJson: GET /categories con servicios → serviceCount', () {
      final entity = CategoryModel.fromJson(backendCategory(services: [
        backendService(withCategory: false),
        backendService(id: 'srv-2', withCategory: false),
      ])).toEntity();
      expect(
          entity,
          const CategoryEntity(
            id: 'cat-1',
            name: 'Cejas',
            description: 'Diseño de cejas',
            serviceCount: 2,
          ));
      expect(entity.hasServices, true);
    });

    test('sin "services" (anidada en un servicio) → serviceCount null', () {
      final entity = CategoryModel.fromJson(backendCategory()).toEntity();
      expect(entity.serviceCount, isNull);
      expect(entity.hasServices, false);
    });

    test('lista vacía → 0; descripción null → ""; isActive false', () {
      final entity = CategoryModel.fromJson(
              backendCategory(description: null, isActive: false, services: []))
          .toEntity();
      expect(entity.serviceCount, 0);
      expect(entity.description, '');
      expect(entity.isActive, false);
    });

    test('toJson: solo name y description (CreateCategoryDto)', () {
      const entity = CategoryEntity(
          id: 'cat-1', name: 'Uñas', description: 'Manicure', isActive: false);
      expect(CategoryModel.fromEntity(entity).toJson(),
          {'name': 'Uñas', 'description': 'Manicure'});
    });

    test('fromEntity/toEntity conserva todo', () {
      const entity =
          CategoryEntity(id: 'c', name: 'n', description: 'd', serviceCount: 3);
      expect(CategoryModel.fromEntity(entity).toEntity(), entity);
    });
  });

  group('ServiceModel', () {
    test('fromJson: GET /services (precio decimal como texto, categoría)', () {
      final entity = ServiceModel.fromJson(backendService()).toEntity();
      expect(entity.id, 'srv-1');
      expect(entity.name, 'Cejas en hilo');
      expect(entity.description, '');
      expect(entity.price, 45000.0);
      expect(entity.priceType, ServicePriceType.variable);
      expect(entity.duration, 60);
      expect(entity.categoryId, 'cat-1');
      expect(entity.category!.name, 'Cejas');
      expect(entity.color, '#FF5733');
      expect(entity.image, isNull);
      expect(entity.onlineBooking, true);
      expect(entity.deposit, 5000);
      expect(entity.isActive, true);
    });

    test('números como texto o num; priceType desconocido → fijo', () {
      final json = backendService(price: 35.5, duration: '45')
        ..['priceType'] = 'otro'
        ..['deposit'] = '1000';
      final entity = ServiceModel.fromJson(json).toEntity();
      expect(entity.price, 35.5);
      expect(entity.duration, 45);
      expect(entity.deposit, 1000);
      expect(entity.priceType, ServicePriceType.fixed);
    });

    test('alta (POST): sin category; color null → color por defecto', () {
      final json = backendService(withCategory: false)..['color'] = null;
      final entity = ServiceModel.fromJson(json).toEntity();
      expect(entity.category, isNull);
      expect(entity.categoryId, 'cat-1');
      expect(entity.color, ServiceEntity.defaultColor);
    });

    test('sin categoryId plano: lo toma de la categoría anidada', () {
      final json = backendService()..remove('categoryId');
      expect(ServiceModel.fromJson(json).categoryId, 'cat-1');
    });

    test('toJson: CreateServiceDto sin id ni isActive; image solo si hay', () {
      const entity = ServiceEntity(
        id: 'srv-1',
        name: 'Corte',
        price: 30000,
        duration: 30,
        categoryId: 'cat-1',
        color: '#1c94f4',
        isActive: false,
      );
      expect(ServiceModel.fromEntity(entity).toJson(), {
        'name': 'Corte',
        'description': '',
        'price': 30000.0,
        'priceType': 'Precio fijo',
        'duration': 30,
        'categoryId': 'cat-1',
        'color': '#1c94f4',
        'onlineBooking': false,
        'deposit': 0,
      });
      expect(
          ServiceModel.fromEntity(entity.copyWith(image: 'https://x/y.png'))
              .toJson()['image'],
          'https://x/y.png');
    });

    test('fromEntity/toEntity conserva todo (con categoría)', () {
      final entity = ServiceModel.fromJson(backendService()).toEntity();
      expect(ServiceModel.fromEntity(entity).toEntity(), entity);
    });
  });

  group('ServicePriceType', () {
    test('toApi/fromApi con los textos del backend', () {
      expect(ServicePriceType.fixed.toApi(), 'Precio fijo');
      expect(ServicePriceType.fromApi(' precio VARIABLE '),
          ServicePriceType.variable);
      expect(ServicePriceType.fromApi(null), isNull);
    });
  });
}
