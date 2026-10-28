import 'package:login_signup/core/errors/failures.dart';

/// Activar a mano (`PATCH /auth/employee/:id/status`) un empleado que no ha
/// verificado su email (409 `EMAIL_NOT_VERIFIED`, regla 2.15). Se activa al
/// verificar el código (`VerifyEmployeeEmailUseCase`).
class EmployeeEmailNotVerifiedFailure extends ConflictFailure {
  static const defaultMessage =
      'El profesional debe verificar su email antes de activarse';

  const EmployeeEmailNotVerifiedFailure({
    String? message,
    super.statusCode,
    super.details,
  }) : super(
          message: message ?? defaultMessage,
          code: ApiErrorCode.emailNotVerified,
        );
}

/// Código de verificación del email incorrecto, vencido o agotado tras
/// varios intentos: 400 `INVALID_VERIFICATION_CODE` (2.33). Se conserva el
/// texto del backend, que dice el motivo.
class InvalidEmployeeVerificationCodeFailure extends ValidationFailure {
  static const defaultMessage = 'Código de verificación inválido';

  const InvalidEmployeeVerificationCodeFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// Datos de un profesional fuera de las reglas del backend
/// (`EmployeeRules`). La producen los use cases antes de llamar al backend;
/// [details] lista todos los problemas y [message] los une.
class InvalidEmployeeDataFailure extends ValidationFailure {
  const InvalidEmployeeDataFailure({super.message, super.details});

  factory InvalidEmployeeDataFailure.of(List<String> problems) =>
      InvalidEmployeeDataFailure(
          message: problems.join('\n'), details: problems);
}
