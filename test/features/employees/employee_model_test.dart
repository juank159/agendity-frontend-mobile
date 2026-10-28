import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/employees/data/models/employee_input_model.dart';
import 'package:login_signup/features/employees/data/models/employee_model.dart';
import 'package:login_signup/features/employees/data/models/employee_restoration_model.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/features/employees/domain/entities/work_hours.dart';

/// Empleado como lo devuelve `GET /auth/employees` (usuario sin secretos +
/// `roles`, `isOwner`, `services` y `schedule` ya transformados).
Map<String, dynamic> backendEmployee({
  String id = 'emp-1',
  bool isActive = true,
  bool verified = true,
  bool isOwner = false,
  String? deletedAt,
  String? deletionReason,
}) =>
    {
      'id': id,
      'name': 'Laura',
      'lastname': 'Gómez',
      'email': 'laura@example.com',
      'phone': '3001234567',
      'image': null,
      'isActive': isActive,
      'is_google_account': false,
      'tenant_id': 'owner-1',
      'is_email_verified': verified,
      'deletedAt': deletedAt,
      'deletionReason': deletionReason,
      'deletedBy': null,
      'created_at': '2026-10-01T09:00:00.000-05:00',
      'updated_at': '2026-10-01T09:00:00.000-05:00',
      'roles': [
        {'name': isOwner ? 'Owner' : 'Employee'}
      ],
      'isOwner': isOwner,
      'isDeleted': deletedAt != null,
      'services': [
        {
          'id': 'svc-1',
          'name': 'Corte',
          'commissionPercentage': '40.00',
          'customPrice': '35000.00',
          'originalPrice': '30000.00',
          'isActive': true,
        },
        {
          'id': 'svc-2',
          'name': 'Barba',
          'commissionPercentage': 0,
          'customPrice': null,
          'originalPrice': '15000.00',
          'isActive': true,
        },
      ],
      'schedule': {
        'monday': {'start': '09:00:00', 'end': '18:00:00'},
        'saturday': {'start': '08:00', 'end': '12:30'},
      },
      // Relaciones crudas que el backend también deja en la respuesta.
      'schedules': [
        {'day_of_week': 1, 'start_time': '09:00:00', 'end_time': '18:00:00'}
      ],
    };

/// Empleado de `GET /auth/employees/deleted`: relaciones crudas, sin
/// `services` ni `schedule` transformados.
Map<String, dynamic> backendDeletedEmployee() => {
      'id': 'emp-9',
      'name': 'Pedro',
      'lastname': 'Ruiz',
      'email': 'pedro@example.com',
      'phone': '3109998877',
      'isActive': false,
      'is_email_verified': true,
      'deletedAt': '2026-10-20T15:30:00.000-05:00',
      'deletionReason': 'Renuncia',
      'roles': [
        {'name': 'Employee'}
      ],
      'isDeleted': true,
      'userServices': [
        {
          'userId': 'emp-9',
          'serviceId': 'svc-1',
          'commissionPercentage': '25.50',
          'customPrice': null,
          'isActive': true,
          'service': {'id': 'svc-1', 'name': 'Corte'},
        }
      ],
      'schedules': [
        {'day_of_week': 2, 'start_time': '10:00:00', 'end_time': '19:00:00'},
        {'day_of_week': 9, 'start_time': '10:00:00', 'end_time': '19:00:00'},
      ],
    };

void main() {
  group('EmployeeModel.fromJson', () {
    test('GET /auth/employees: decimales en texto, horas a HH:mm', () {
      final employee = EmployeeModel.fromJson(backendEmployee()).toEntity();

      expect(employee.id, 'emp-1');
      expect(employee.fullName, 'Laura Gómez');
      expect(employee.isEmailVerified, true);
      expect(employee.isOwner, false);
      expect(employee.roles.single.name, 'Employee');
      expect(employee.serviceIds, ['svc-1', 'svc-2']);
      expect(
        employee.serviceAssignments['svc-1'],
        const ServiceAssignment(
          serviceId: 'svc-1',
          serviceName: 'Corte',
          commissionPercentage: 40,
          customPrice: 35000,
        ),
      );
      expect(employee.serviceAssignments['svc-2']!.customPrice, isNull);
      // `schedule` (transformado) gana a `schedules` (crudo).
      expect(employee.schedule, {
        'monday': const WorkHours(start: '09:00', end: '18:00'),
        'saturday': const WorkHours(start: '08:00', end: '12:30'),
      });
      expect(employee.isDeleted, false);
      expect(employee.status, EmployeeStatus.active);
      expect(employee.canBeScheduled, true);
    });

    test('el Owner sale por isOwner o por su rol', () {
      expect(EmployeeModel.fromJson(backendEmployee(isOwner: true)).isOwner,
          true);
      final json = backendEmployee(isOwner: true)..remove('isOwner');
      expect(EmployeeModel.fromJson(json).isOwner, true);
    });

    test('GET /auth/employees/deleted: userServices y schedules crudos', () {
      final employee =
          EmployeeModel.fromJson(backendDeletedEmployee()).toEntity();

      expect(employee.isDeleted, true);
      expect(employee.deletedAt,
          BusinessTimeZone.toWallClock(DateTime.utc(2026, 10, 20, 20, 30)));
      expect(employee.deletionReason, 'Renuncia');
      expect(employee.status, EmployeeStatus.deleted);
      expect(employee.canBeScheduled, false);
      expect(employee.serviceAssignments['svc-1']!.serviceName, 'Corte');
      expect(employee.serviceAssignments['svc-1']!.commissionPercentage, 25.5);
      // day_of_week fuera de 1..7 se ignora.
      expect(employee.schedule,
          {'tuesday': const WorkHours(start: '10:00', end: '19:00')});
    });

    test('respuesta mínima (alta, cambio de estado): sin servicios ni nulls',
        () {
      final employee = EmployeeModel.fromJson({
        'id': 'emp-2',
        'name': 'Ana',
        'lastname': 'Díaz',
        'email': 'ana@example.com',
        'phone': null,
        'roles': [
          {'name': 'Employee'}
        ],
      }).toEntity();

      expect(employee.phone, '');
      expect(employee.isActive, false);
      expect(employee.isEmailVerified, false);
      expect(employee.serviceAssignments, isEmpty);
      expect(employee.schedule, isEmpty);
    });
  });

  group('EmployeeEntity', () {
    EmployeeEntity entity({bool active = false, bool verified = false}) =>
        EmployeeModel.fromJson(
                backendEmployee(isActive: active, verified: verified))
            .toEntity();

    test('nace inactivo y sin verificar → pendiente de verificación', () {
      final employee = entity();
      expect(employee.status, EmployeeStatus.pendingVerification);
      expect(employee.needsEmailVerification, true);
      expect(employee.canBeScheduled, false);
    });

    test('verificado y desactivado → inactivo', () {
      expect(entity(verified: true).status, EmployeeStatus.inactive);
    });

    test('el Owner sin verificar no queda pendiente', () {
      final owner = EmployeeModel.fromJson(
              backendEmployee(isOwner: true, verified: false, isActive: true))
          .toEntity();
      expect(owner.needsEmailVerification, false);
      expect(owner.status, EmployeeStatus.active);
    });

    test('markDeleted y markRestored', () {
      final at = DateTime.utc(2026, 10, 27);
      final deleted =
          entity(active: true, verified: true).markDeleted(at: at, reason: 'x');
      expect(deleted.isActive, false);
      expect(deleted.deletedAt, at);
      expect(deleted.status, EmployeeStatus.deleted);

      final restored = deleted.markRestored(isActive: false);
      expect(restored.deletedAt, isNull);
      expect(restored.deletionReason, isNull);
      expect(restored.status, EmployeeStatus.inactive);
    });

    test('igualdad por contenido (mapas y listas)', () {
      expect(entity(), entity());
      expect(entity().hashCode, entity().hashCode);
      expect(entity(), isNot(entity(verified: true)));
    });
  });

  group('EmployeeInputModel', () {
    const input = EmployeeInput(
      name: 'Laura',
      lastname: 'Gómez',
      email: 'laura@example.com',
      phone: '3001234567',
      password: 'Secreta1!',
      services: {
        'svc-1': ServiceAssignment(
            serviceId: 'svc-1', commissionPercentage: 40, customPrice: 35000),
        'svc-2': ServiceAssignment(serviceId: 'svc-2'),
      },
      schedule: {'monday': WorkHours(start: '09:00', end: '18:00')},
    );

    test('alta: solo campos del DTO, con contraseña', () {
      final json = EmployeeInputModel.fromEntity(input).toCreateJson();
      expect(json.keys.toSet(), {
        'name',
        'lastname',
        'email',
        'phone',
        'password',
        'services',
        'schedule',
      });
      expect(json['services'], [
        {'serviceId': 'svc-1', 'commissionPercentage': 40.0, 'customPrice': 35000.0},
        {'serviceId': 'svc-2', 'commissionPercentage': 0.0},
      ]);
      expect(json['schedule'], {
        'monday': {'start': '09:00', 'end': '18:00'}
      });
    });

    test('edición: la contraseña solo si se cambia', () {
      final withoutPassword = EmployeeInput(
        name: input.name,
        lastname: input.lastname,
        email: input.email,
        phone: input.phone,
      );
      expect(
          EmployeeInputModel.fromEntity(withoutPassword)
              .toUpdateJson()
              .containsKey('password'),
          false);
      expect(EmployeeInputModel.fromEntity(input).toUpdateJson()['password'],
          'Secreta1!');
    });
  });

  test('EmployeeRestorationModel', () {
    final restoration = EmployeeRestorationModel.fromJson({
      'message': 'Empleado restaurado. Debe verificar su email para activarse',
      'id': 'emp-9',
      'isActive': false,
      'restoredAt': '2026-10-27T10:00:00.000-05:00',
    }, fallbackId: 'x')
        .toEntity();
    expect(restoration.employeeId, 'emp-9');
    expect(restoration.needsEmailVerification, true);

    expect(
        EmployeeRestorationModel.fromJson(const {}, fallbackId: 'emp-3')
            .employeeId,
        'emp-3');
  });

  test('WorkHours.normalize y isValid', () {
    expect(WorkHours.normalize(' 09:00:00 '), '09:00');
    expect(WorkHours.normalize('9:00'), '9:00');
    expect(const WorkHours(start: '09:00', end: '18:00').isValid, true);
    expect(const WorkHours(start: '18:00', end: '09:00').isValid, false);
    expect(const WorkHours(start: '9:00', end: '18:00').isValid, false);
  });
}
