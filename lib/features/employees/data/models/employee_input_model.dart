import 'package:login_signup/features/employees/domain/entities/employee_input.dart';

/// Cuerpo de `POST /auth/register/employee` (`CreateEmployeeWithDetailsDto`) y
/// de `PATCH /auth/employee/:id` (`UpdateEmployeeDto`). El backend rechaza
/// cualquier campo que no esté en el DTO (`forbidNonWhitelisted`).
class EmployeeInputModel {
  final EmployeeInput input;

  const EmployeeInputModel._(this.input);

  factory EmployeeInputModel.fromEntity(EmployeeInput input) =>
      EmployeeInputModel._(input);

  /// Alta: con contraseña.
  Map<String, dynamic> toCreateJson() => {
        ..._common(),
        'password': input.password ?? '',
      };

  /// Edición: la contraseña solo si se cambia.
  Map<String, dynamic> toUpdateJson() => {
        ..._common(),
        if (input.hasPassword) 'password': input.password,
      };

  Map<String, dynamic> _common() => {
        'name': input.name,
        'lastname': input.lastname,
        'email': input.email,
        'phone': input.phone,
        if (input.commissionPercentage != null)
          'commission_percentage': input.commissionPercentage,
        'services': [
          for (final service in input.services.values)
            {
              'serviceId': service.serviceId,
              // 8.02: sin excepción no se envía (si no, un 0 % taparía la
              // comisión general).
              if (service.commissionPercentage != null)
                'commissionPercentage': service.commissionPercentage,
              if (service.customPrice != null)
                'customPrice': service.customPrice,
              if (!service.isActive) 'isActive': false,
            },
        ],
        'schedule': {
          for (final entry in input.schedule.entries)
            entry.key: {'start': entry.value.start, 'end': entry.value.end},
        },
      };
}
