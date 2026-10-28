import 'error_codes.dart';

export 'error_codes.dart';

/// Jerarquía de failures genéricos (ARQUITECTURA.md §3).
///
/// - Los repositorios los devuelven en `Either<Failure, T>` (vía `safeCall`).
/// - `code` es el código del contrato (`ApiErrorCode`) cuando lo dio el backend;
///   la app decide por `code` o por el tipo, nunca por el texto de `message`.
/// - `message` siempre es un texto en español apto para el usuario.
/// - Los failures propios de una feature viven en `features/<f>/domain/failures/`
///   y extienden estos.
abstract class Failure {
  final String message;
  final String? code;
  final int? statusCode;
  final List<String> details;

  const Failure({
    required this.message,
    this.code,
    this.statusCode,
    this.details = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          other.runtimeType == runtimeType &&
          other.message == message &&
          other.code == code &&
          other.statusCode == statusCode;

  @override
  int get hashCode => Object.hash(runtimeType, message, code, statusCode);

  @override
  String toString() => message;
}

/// 5xx, `INTERNAL_ERROR` o una respuesta que no se pudo interpretar.
class ServerFailure extends Failure {
  static const defaultMessage =
      'Error interno del servidor. Intenta de nuevo más tarde.';

  const ServerFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// La petición no llegó o no volvió: sin conexión, timeouts o certificado.
class NetworkFailure extends Failure {
  static const defaultMessage = 'Error de conexión a internet';

  const NetworkFailure({
    String? message,
  }) : super(message: message ?? defaultMessage);
}

/// La petición se canceló desde la app (`CancelToken`).
class CancelledFailure extends Failure {
  static const defaultMessage = 'Solicitud cancelada';

  const CancelledFailure({
    String? message,
  }) : super(message: message ?? defaultMessage);
}

/// 400/422: `VALIDATION_ERROR` o `BAD_REQUEST`. `details` trae la lista de errores.
class ValidationFailure extends Failure {
  static const defaultMessage = 'Los datos enviados no son válidos';

  const ValidationFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// 401: sin token o token vencido. El `AuthInterceptor` avisa de la sesión expirada.
class UnauthorizedFailure extends Failure {
  static const defaultMessage = 'Tu sesión expiró. Inicia sesión de nuevo.';

  const UnauthorizedFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// 403: `FORBIDDEN` o `ACCOUNT_INACTIVE` (este último lo refina auth en la Fase 4).
class ForbiddenFailure extends Failure {
  static const defaultMessage = 'No tienes permiso para realizar esta acción';

  const ForbiddenFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// 404: el recurso no existe o es de otro negocio.
class NotFoundFailure extends Failure {
  static const defaultMessage = 'Recurso no encontrado';

  const NotFoundFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// 409 y conflictos de negocio: `CONFLICT`, `SLOT_UNAVAILABLE`,
/// `PROFESSIONAL_INACTIVE`, `INVALID_STATE_TRANSITION`, `APPOINTMENT_PAID`,
/// `EMAIL_NOT_VERIFIED`, `OWNER_NOT_DELETABLE`, `CATEGORY_HAS_SERVICES`. Mirar
/// `code` para distinguirlos (o el failure de la feature, que lo refina).
class ConflictFailure extends Failure {
  static const defaultMessage =
      'La operación entra en conflicto con el estado actual';

  const ConflictFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// 402: `TRIAL_LIMIT_REACHED` o `SUBSCRIPTION_INACTIVE` (los refina subscriptions en 4.05).
class PaymentRequiredFailure extends Failure {
  static const defaultMessage =
      'Necesitas una suscripción activa para continuar';

  const PaymentRequiredFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// 429: demasiados intentos (throttle de `/auth/*`).
class TooManyRequestsFailure extends Failure {
  static const defaultMessage =
      'Demasiados intentos. Espera un momento y vuelve a intentarlo.';

  const TooManyRequestsFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// `DUPLICATE_EMAIL`: usuario o cliente con un email ya registrado.
class DuplicateEmailFailure extends ConflictFailure {
  final String email;

  const DuplicateEmailFailure({
    this.email = '',
    String? message,
    super.statusCode,
    super.details,
  }) : super(
          message: message ??
              (email == ''
                  ? 'Ya existe un usuario con ese email'
                  : 'Ya existe un usuario con el email: $email'),
          code: ApiErrorCode.duplicateEmail,
        );
}

/// `DUPLICATE_PHONE`: usuario o cliente con un teléfono ya registrado.
class DuplicatePhoneFailure extends ConflictFailure {
  final String phone;

  const DuplicatePhoneFailure({
    this.phone = '',
    String? message,
    super.statusCode,
    super.details,
  }) : super(
          message: message ??
              (phone == ''
                  ? 'Ya existe un usuario con ese teléfono'
                  : 'Ya existe un usuario con el teléfono: $phone'),
          code: ApiErrorCode.duplicatePhone,
        );
}
