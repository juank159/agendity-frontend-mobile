import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_changes.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';

/// Servicio de una cita tal como lo devuelve el backend (2.29).
Map<String, dynamic> backendService({
  String id = 'svc-1',
  String name = 'Corte',
  Object? duration = 45,
  Object? price = '50000.00',
  Object? appointmentPrice = '45000.00',
  String? color = '#ff0000',
}) =>
    {
      'id': id,
      'ownerId': 'owner-1',
      'name': name,
      'description': null,
      'price': price,
      'priceType': 'Precio fijo',
      'duration': duration,
      'categoryId': 'cat-1',
      'color': color,
      'isActive': true,
      if (appointmentPrice != null) 'appointment_price': appointmentPrice,
    };

/// Respuesta real de `GET /appointments` (una cita, con relaciones).
Map<String, dynamic> backendAppointment({
  String id = 'apt-1',
  String date = '2026-11-03T10:00:00.000-05:00',
  String status = 'PENDING',
  String paymentStatus = 'PENDING',
  Object? total = '45000',
  List<Map<String, dynamic>>? services,
  bool reminderSent = false,
  String? phone = '3001234567',
  String? timeZone = 'America/Bogota',
  String? source,
}) =>
    {
      'id': id,
      'ownerId': 'owner-1',
      'professionalId': 'pro-1',
      'date': date,
      // Zona guardada en la cita (backend 6.03).
      if (timeZone != null) 'timezone': timeZone,
      if (source != null) 'source': source,
      'status': status,
      'payment_status': paymentStatus,
      'total_price': total,
      'notes': 'Sin prisa',
      'cancellation_reason': null,
      'created_at': '2026-10-28T08:00:00.000-05:00',
      'updated_at': '2026-10-28T08:00:00.000-05:00',
      'reminderSent': reminderSent,
      'reminderSentAt': reminderSent ? '2026-11-02T09:00:00.000-05:00' : null,
      'sendReminder': true,
      'client': {
        'id': 'cli-1',
        'name': 'Ana',
        'lastname': 'Pérez',
        'email': null,
        'phone': phone,
        'countryCode': '+57',
      },
      'professional': {
        'id': 'pro-1',
        'name': 'Laura',
        'lastname': 'Gómez',
        'email': 'laura@example.com',
      },
      'services': services ?? [backendService()],
    };

void main() {
  group('AppointmentModel.fromJson', () {
    test('respuesta real → entidad completa', () {
      final entity = AppointmentModel.fromJson(backendAppointment(
        services: [
          backendService(),
          backendService(
              id: 'svc-2',
              name: 'Barba',
              duration: null,
              price: 20000,
              appointmentPrice: '0.00',
              color: null),
        ],
      )).toEntity();

      expect(entity.id, 'apt-1');
      expect(entity.client,
          const AppointmentClient(
              id: 'cli-1', name: 'Ana', lastname: 'Pérez', phone: '3001234567'));
      expect(entity.clientName, 'Ana Pérez');
      expect(entity.professionalId, 'pro-1');
      expect(entity.professionalName, 'Laura Gómez');
      expect(entity.startTime,
          BusinessTimeZone.toWallClock(DateTime.parse('2026-11-03T15:00:00.000Z')));
      // 45 min + servicio sin duración (30, como el backend).
      expect(entity.duration, const Duration(minutes: 75));
      expect(entity.services, const [
        AppointmentServiceLine(
            serviceId: 'svc-1',
            name: 'Corte',
            durationMinutes: 45,
            color: '#ff0000',
            price: 45000,
            currentPrice: 50000),
        AppointmentServiceLine(
            serviceId: 'svc-2',
            name: 'Barba',
            durationMinutes: 30,
            price: 0,
            currentPrice: 20000),
      ]);
      expect(entity.serviceIds, ['svc-1', 'svc-2']);
      expect(entity.serviceNames, ['Corte', 'Barba']);
      expect(entity.status, AppointmentStatus.PENDING);
      expect(entity.paymentStatus, AppointmentPaymentStatus.PENDING);
      expect(entity.totalPrice, 45000);
      expect(entity.notes, 'Sin prisa');
      expect(entity.reminderSent, false);
      expect(entity.reminderSentAt, isNull);
      expect(entity.createdAt,
          BusinessTimeZone.toWallClock(DateTime.parse('2026-10-28T13:00:00.000Z')));
    });

    test('precio en la cita (2.29): sin appointment_price usa el price', () {
      final line = AppointmentModel.fromJson(backendAppointment(services: [
        backendService(appointmentPrice: null, price: '50000.00'),
      ])).toEntity().services.single;
      expect(line.price, 50000);
    });

    test('CONFIRMED + PARTIAL, recordatorio enviado y cliente sin teléfono', () {
      final entity = AppointmentModel.fromJson(backendAppointment(
        status: 'CONFIRMED',
        paymentStatus: 'PARTIAL',
        reminderSent: true,
        phone: null,
      )).toEntity();
      expect(entity.status, AppointmentStatus.CONFIRMED);
      expect(entity.paymentStatus, AppointmentPaymentStatus.PARTIAL);
      expect(entity.reminderSent, true);
      expect(entity.reminderSentAt,
          BusinessTimeZone.toWallClock(DateTime.parse('2026-11-02T14:00:00.000Z')));
      expect(entity.client.phone, isNull);
    });

    test('estados desconocidos → PENDING; total numérico o ausente', () {
      final json = backendAppointment(status: 'raro', paymentStatus: 'otro')
        ..['total_price'] = 30000;
      final entity = AppointmentModel.fromJson(json).toEntity();
      expect(entity.status, AppointmentStatus.PENDING);
      expect(entity.paymentStatus, AppointmentPaymentStatus.PENDING);
      expect(entity.totalPrice, 30000);
      expect(
          AppointmentModel.fromJson(backendAppointment()..remove('total_price'))
              .totalPrice,
          0);
    });

    test('sin id o sin fecha → FormatException', () {
      expect(() => AppointmentModel.fromJson(backendAppointment()..remove('id')),
          throwsFormatException);
      expect(
          () => AppointmentModel.fromJson(backendAppointment()..remove('date')),
          throwsFormatException);
    });
  });

  group('cuerpos de petición', () {
    test('POST: sin owner_id ni precio; fecha en UTC con Z', () {
      final json = NewAppointmentModel.toJson(NewAppointment(
        clientId: 'cli-1',
        professionalId: 'pro-1',
        serviceIds: const ['svc-1', 'svc-2'],
        start: DateTime.utc(2026, 11, 3, 15),
      ));
      expect(json, {
        'client_id': 'cli-1',
        'professional_id': 'pro-1',
        'service_ids': ['svc-1', 'svc-2'],
        'date': '2026-11-03T15:00:00.000Z',
      });
    });

    test('PATCH: solo los campos que cambian', () {
      expect(
          AppointmentChangesModel.toJson(const AppointmentChanges(notes: '')),
          {'notes': ''});
      expect(
          AppointmentChangesModel.toJson(AppointmentChanges(
              professionalId: 'pro-2', start: DateTime.utc(2026, 11, 4, 15))),
          {'professional_id': 'pro-2', 'date': '2026-11-04T15:00:00.000Z'});
    });

    test('send-reminder → ManualReminder', () {
      final reminder = ManualReminderModel.fromJson({
        'appointmentId': 'apt-1',
        'clientId': 'cli-1',
        'phone': '3001234567',
        'message': 'Hola Ana',
        'whatsappUrl': 'https://wa.me/573001234567?text=Hola%20Ana',
      });
      expect(reminder.phone, '3001234567');
      expect(reminder.whatsappUrl, startsWith('https://wa.me/57'));
    });
  });

  group('origen y "ya empezó" (9.01, 7.03)', () {
    tearDown(() => BusinessTimeZone.clock = DateTime.now);

    test('source WEB/APP; sin el campo o desconocido, APP', () {
      AppointmentEntity read(String? source) =>
          AppointmentModel.fromJson(backendAppointment(source: source))
              .toEntity();
      expect(read('WEB').source, AppointmentSource.WEB);
      expect(read('WEB').isWebBooking, true);
      expect(read(' app ').source, AppointmentSource.APP);
      expect(read(null).source, AppointmentSource.APP);
      expect(read('KIOSKO').source, AppointmentSource.APP);
    });

    test('canCompleteAt: pendiente o confirmada y ya empezada', () {
      final appointment = AppointmentModel.fromJson(
              backendAppointment(date: '2026-11-03T10:00:00.000-05:00'))
          .toEntity();
      expect(appointment.canCompleteAt(DateTime(2026, 11, 3, 9, 59)), false);
      expect(appointment.canCompleteAt(DateTime(2026, 11, 3, 10)), true);
      expect(appointment.hasStartedAt(DateTime(2026, 11, 3, 11)), true);
      final cancelled = AppointmentModel.fromJson(backendAppointment(
              date: '2026-11-03T10:00:00.000-05:00', status: 'CANCELLED'))
          .toEntity();
      expect(cancelled.canCompleteAt(DateTime(2026, 11, 3, 11)), false);
    });
  });
}
