import 'package:login_signup/core/utils/deep_equality.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/features/employees/domain/entities/work_hours.dart';

/// Datos del formulario para crear o editar un profesional.
///
/// Se envía completo: [services] y [schedule] sustituyen a los que tenga el
/// profesional (un horario vacío lo deja sin restricción de horario).
class EmployeeInput {
  final String name;
  final String lastname;
  final String email;
  final String phone;

  /// Obligatoria al crear; al editar, `null` o vacía = no se cambia.
  final String? password;

  final Map<String, ServiceAssignment> services;
  final Map<String, WorkHours> schedule;

  const EmployeeInput({
    required this.name,
    required this.lastname,
    required this.email,
    required this.phone,
    this.password,
    this.services = const {},
    this.schedule = const {},
  });

  bool get hasPassword => password != null && password!.isNotEmpty;

  EmployeeInput copyWith({
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? password,
    Map<String, ServiceAssignment>? services,
    Map<String, WorkHours>? schedule,
  }) =>
      EmployeeInput(
        name: name ?? this.name,
        lastname: lastname ?? this.lastname,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        password: password ?? this.password,
        services: services ?? this.services,
        schedule: schedule ?? this.schedule,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeInput &&
          other.name == name &&
          other.lastname == lastname &&
          other.email == email &&
          other.phone == phone &&
          other.password == password &&
          DeepEquality.maps(other.services, services) &&
          DeepEquality.maps(other.schedule, schedule);

  @override
  int get hashCode => Object.hash(name, lastname, email, phone, password,
      DeepEquality.mapHash(services), DeepEquality.mapHash(schedule));

  /// Sin la contraseña.
  @override
  String toString() => 'EmployeeInput($name $lastname, $email)';
}
