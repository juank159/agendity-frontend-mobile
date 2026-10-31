import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/clients/data/models/client_model.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

/// Cliente como lo devuelve el backend (`Client`, fechas con el offset del
/// negocio; `GET /clients/:id` añade `appointments` y `reviews`).
Map<String, dynamic> backendClient({
  String id = 'cli-1',
  String name = 'Ana',
  String lastname = 'Pérez',
  Object? email = 'ana@correo.co',
  String phone = '3001234567',
  Object? birthday = '1990-05-10T00:00:00.000-05:00',
  bool isFromDevice = false,
}) =>
    {
      'id': id,
      'name': name,
      'lastname': lastname,
      'email': email,
      'phone': phone,
      'countryCode': '+57',
      'enableWhatsAppNotifications': true,
      'image': null,
      'address': 'Calle 1',
      'ownerId': 'owner-1',
      'isFromDevice': isFromDevice,
      'deviceContactId': null,
      'lastVisit': null,
      'isActive': true,
      'notes': 'Alérgica al tinte',
      'birthday': birthday,
      'showNotes': true,
      'created_at': '2026-10-21T08:00:00.000-05:00',
      'updated_at': '2026-10-21T08:00:00.000-05:00',
    };


void main() {
  group('ClientModel.fromJson', () {
    test('cliente completo → entidad (instantes locales, birthday = día)', () {
      final entity = ClientModel.fromJson({
        ...backendClient(),
        'appointments': [],
        'reviews': [],
      }).toEntity();
      expect(entity.id, 'cli-1');
      expect(entity.fullName, 'Ana Pérez');
      expect(entity.email, 'ana@correo.co');
      expect(entity.hasEmail, true);
      expect(entity.address, 'Calle 1');
      expect(entity.showNotes, true);
      expect(entity.birthday, DateTime(1990, 5, 10));
      expect(entity.createdAt, BusinessTimeZone.toWallClock(DateTime.utc(2026, 10, 21, 13)));
      expect(entity.createdAt!.isUtc, false);
    });

    test('sin email (null o vacío) → email null', () {
      for (final email in [null, '', '  ']) {
        final entity =
            ClientModel.fromJson(backendClient(email: email)).toEntity();
        expect(entity.email, isNull, reason: '$email');
        expect(entity.hasEmail, false);
      }
    });

    test('campos que faltan o vienen null → valores por defecto', () {
      final model = ClientModel.fromJson({'id': 'x', 'phone': 3001234567});
      expect(model.name, '');
      expect(model.lastname, '');
      expect(model.phone, '3001234567');
      expect(model.isActive, true);
      expect(model.isFromDevice, false);
      expect(model.showNotes, false);
      expect(model.birthday, isNull);
      expect(model.notes, isNull);
    });

    test('birthday con el offset del negocio no cambia de día en otra zona',
        () {
      final model = ClientModel.fromJson(
          backendClient(birthday: '1990-05-10T00:00:00.000-05:00'));
      expect(model.birthday, DateTime(1990, 5, 10));
      expect(
          ClientModel.fromJson(backendClient(birthday: '1990-05-10')).birthday,
          DateTime(1990, 5, 10));
    });
  });

  group('ClientModel.toJson (CreateClientDto)', () {
    const entity = ClientEntity(
      id: 'cli-1',
      name: 'Ana',
      lastname: 'Pérez',
      phone: '3001234567',
      isActive: false,
      isFromDevice: true,
    );

    test('solo campos del DTO; sin email → "" (el backend guarda null)', () {
      final json = ClientModel.fromEntity(entity).toJson();
      expect(json['email'], '');
      for (final key in ['id', 'ownerId', 'isActive', 'isFromDevice']) {
        expect(json.containsKey(key), false, reason: key);
      }
      expect(json.containsKey('image'), false);
      expect(json['notes'], isNull);
      expect(json['birthday'], isNull);
      expect(json.containsKey('notes'), true, reason: 'null borra al editar');
    });

    test('birthday como día yyyy-MM-dd', () {
      final json = ClientModel.fromEntity(
              entity.copyWith(birthday: DateTime(1990, 5, 3), email: 'a@b.co'))
          .toJson();
      expect(json['birthday'], '1990-05-03');
      expect(json['email'], 'a@b.co');
    });

    test('fromEntity/toEntity conserva la entidad', () {
      final full = entity.copyWith(
          email: 'a@b.co', birthday: DateTime(1990, 5, 3), notes: 'n');
      expect(ClientModel.fromEntity(full).toEntity(), full);
    });
  });
}
