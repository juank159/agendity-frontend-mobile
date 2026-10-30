import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/features/employees/data/models/employee_input_model.dart';
import 'package:login_signup/features/employees/data/models/employee_model.dart';
import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/features/employees/domain/usecases/employee_rules.dart';

import 'employee_model_test.dart' show backendEmployee;

/// Comisión general + excepción por servicio (D-16, 8.02) y servicios que
/// hace un profesional (7.03).
void main() {
  group('lectura', () {
    test('comisión general y excepción null = usa la general', () {
      final employee = EmployeeModel.fromJson({
        ...backendEmployee(),
        'commission_percentage': '30.00',
        'services': [
          {'id': 'svc-1', 'name': 'Cejas', 'commissionPercentage': null},
          {'id': 'svc-2', 'name': 'Pestañas', 'commissionPercentage': 0},
          {'id': 'svc-3', 'name': 'Tinte', 'commissionPercentage': '45.5'},
        ],
      }).toEntity();

      expect(employee.commissionPercentage, 30);
      final services = employee.serviceAssignments;
      expect(services['svc-1']!.commissionPercentage, isNull);
      expect(services['svc-1']!.hasCommissionException, false);
      expect(services['svc-2']!.commissionPercentage, 0,
          reason: '0 es un 0 % de verdad');
      expect(employee.commissionFor('svc-1'), 30);
      expect(employee.commissionFor('svc-2'), 0);
      expect(employee.commissionFor('svc-3'), 45.5);
      expect(employee.commissionFor('otro'), 30);
    });

    test('sin commission_percentage (respuesta vieja): 0', () {
      expect(EmployeeModel.fromJson(backendEmployee()).toEntity()
          .commissionPercentage, 0);
    });
  });

  group('envío', () {
    EmployeeInput input({double? general, Map<String, ServiceAssignment>? s}) =>
        EmployeeInput(
          name: 'Laura',
          lastname: 'Gómez',
          email: 'laura@example.com',
          phone: '3001234567',
          password: 'Secreta1!',
          commissionPercentage: general,
          services: s ??
              const {
                'svc-1': ServiceAssignment(serviceId: 'svc-1'),
                'svc-2': ServiceAssignment(
                    serviceId: 'svc-2', commissionPercentage: 0),
              },
          schedule: const {'monday': WorkHours(start: '09:00', end: '18:00')},
        );

    test('general si se indica; excepción solo si la hay (0 incluido)', () {
      final json = EmployeeInputModel.fromEntity(input(general: 30))
          .toCreateJson();
      expect(json['commission_percentage'], 30);
      expect(json['services'], [
        {'serviceId': 'svc-1'},
        {'serviceId': 'svc-2', 'commissionPercentage': 0.0},
      ]);
    });

    test('sin general no se envía (al editar no la cambia)', () {
      final json = EmployeeInputModel.fromEntity(input()).toUpdateJson();
      expect(json.containsKey('commission_percentage'), false);
    });

    test('asignación inactiva se conserva inactiva', () {
      final json = EmployeeInputModel.fromEntity(input(s: const {
        'svc-1': ServiceAssignment(serviceId: 'svc-1', isActive: false),
      })).toCreateJson();
      expect(json['services'], [
        {'serviceId': 'svc-1', 'isActive': false},
      ]);
    });

    test('reglas: 0–100 % con hasta 2 decimales', () {
      expect(EmployeeRules.isValidCommission(null), true);
      expect(EmployeeRules.isValidCommission(0), true);
      expect(EmployeeRules.isValidCommission(33.33), true);
      expect(EmployeeRules.isValidCommission(100), true);
      expect(EmployeeRules.isValidCommission(100.01), false);
      expect(EmployeeRules.isValidCommission(-1), false);
      expect(EmployeeRules.isValidCommission(12.345), false);
      expect(
          EmployeeRules.check(input(general: 150), requirePassword: true),
          contains(EmployeeRules.commissionInvalid));
      expect(
          EmployeeRules.check(
              input(s: const {
                'svc-1': ServiceAssignment(
                    serviceId: 'svc-1', commissionPercentage: 120)
              }),
              requirePassword: true),
          contains(EmployeeRules.commissionInvalid));
      expect(EmployeeRules.check(input(general: 30), requirePassword: true),
          isEmpty);
    });

    test('normalize conserva la general', () {
      expect(EmployeeRules.normalize(input(general: 25)).commissionPercentage,
          25);
    });
  });

  group('servicios que hace (7.03)', () {
    test('empleado: asignados y activos; Owner: todos', () {
      final employee = EmployeeModel.fromJson({
        ...backendEmployee(),
        'services': [
          {'id': 'svc-1', 'name': 'Cejas', 'isActive': true},
          {'id': 'svc-2', 'name': 'Pestañas', 'isActive': false},
        ],
      }).toEntity();
      expect(employee.offersService('svc-1'), true);
      expect(employee.offersService('svc-2'), false, reason: 'inactiva');
      expect(employee.offersService('svc-3'), false, reason: 'no asignada');
      expect(employee.offersAll(['svc-1']), true);
      expect(employee.offersAll(['svc-1', 'svc-3']), false);

      final owner =
          EmployeeModel.fromJson(backendEmployee(isOwner: true)).toEntity();
      expect(owner.offersService('cualquiera'), true);
    });
  });
}
