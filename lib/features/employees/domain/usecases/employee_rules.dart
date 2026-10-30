import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/common/entities/work_hours.dart';

/// Reglas de los datos de un profesional: las del DTO del backend
/// (`CreateAuthDto`, `AssignServiceDto`) más un horario coherente. Las usan
/// los use cases de alta, edición y verificación antes de llamar al backend,
/// para dar un mensaje claro en vez de un 400.
abstract final class EmployeeRules {
  static final _personName = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _phone = RegExp(r'^\d{10}$');
  static final _password =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]');
  static final _code = RegExp(r'^\d{6}$');

  static const nameInvalid =
      'El nombre debe tener entre 2 y 50 letras (solo letras y espacios)';
  static const lastnameInvalid =
      'El apellido debe tener entre 2 y 50 letras (solo letras y espacios)';
  static const emailInvalid = 'Debe ser un correo electrónico válido';
  static const phoneInvalid =
      'El teléfono debe contener exactamente 10 dígitos numéricos';
  static const passwordRequired = 'La contraseña es obligatoria';
  static const passwordWeak =
      'La contraseña debe tener mínimo 8 caracteres, con al menos: 1 mayúscula, '
      '1 minúscula, 1 número y 1 carácter especial (@\$!%*?&)';
  static const commissionInvalid = 'La comisión debe estar entre 0 y 100 %';
  static const customPriceInvalid = 'El precio propio no puede ser negativo';
  static const scheduleInvalid =
      'Cada día del horario necesita una hora de inicio anterior a la de fin '
      '(formato HH:mm)';
  static const codeInvalid = 'El código debe tener 6 dígitos';

  /// Recorta textos y deja el teléfono solo con dígitos (`+57 300-123 4567`
  /// → `3001234567`: el indicativo de Colombia se quita si sobra).
  static EmployeeInput normalize(EmployeeInput input) => EmployeeInput(
        name: _collapseSpaces(input.name),
        lastname: _collapseSpaces(input.lastname),
        email: input.email.trim(),
        phone: normalizePhone(input.phone),
        password: input.password,
        services: input.services,
        commissionPercentage: input.commissionPercentage,
        schedule: {
          for (final entry in input.schedule.entries)
            entry.key: WorkHours(
              start: WorkHours.normalize(entry.value.start),
              end: WorkHours.normalize(entry.value.end),
            ),
        },
      );

  static String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('57')) {
      return digits.substring(2);
    }
    return digits;
  }

  static bool isValidEmail(String email) {
    final value = email.trim();
    return value.length >= 5 && value.length <= 100 && _email.hasMatch(value);
  }

  static bool isValidCode(String code) => _code.hasMatch(code.trim());

  /// Problemas de [input] ya normalizado (lista vacía = válido).
  static List<String> check(EmployeeInput input,
      {required bool requirePassword}) {
    return [
      if (!_isValidPersonName(input.name)) nameInvalid,
      if (!_isValidPersonName(input.lastname)) lastnameInvalid,
      if (!isValidEmail(input.email)) emailInvalid,
      if (!_phone.hasMatch(input.phone)) phoneInvalid,
      if (requirePassword && !input.hasPassword) passwordRequired,
      if (input.hasPassword && !isStrongPassword(input.password!)) passwordWeak,
      if (!isValidCommission(input.commissionPercentage) ||
          input.services.values
              .any((s) => !isValidCommission(s.commissionPercentage)))
        commissionInvalid,
      if (input.services.values.any(_badCustomPrice)) customPriceInvalid,
      if (!_isValidSchedule(input.schedule)) scheduleInvalid,
    ];
  }

  static bool isStrongPassword(String password) =>
      password.length >= 8 && _password.hasMatch(password);

  static bool _isValidPersonName(String value) =>
      value.length >= 2 && value.length <= 50 && _personName.hasMatch(value);

  /// `null` (sin valor) o de 0 a 100 % con hasta 2 decimales (DTO del backend).
  static bool isValidCommission(double? percentage) =>
      percentage == null ||
      (percentage >= 0 &&
          percentage <= 100 &&
          ((percentage * 100) - (percentage * 100).round()).abs() < 1e-6);

  static bool _badCustomPrice(ServiceAssignment service) =>
      service.customPrice != null && service.customPrice! < 0;

  static bool _isValidSchedule(Map<String, WorkHours> schedule) =>
      schedule.entries.every((entry) =>
          WorkHours.weekdays.contains(entry.key) && entry.value.isValid);

  static String _collapseSpaces(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');
}
