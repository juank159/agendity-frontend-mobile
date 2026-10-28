import 'package:login_signup/core/errors/failures.dart';

/// Ya existe un cliente con ese teléfono o email en el negocio (409
/// `DUPLICATE_EMAIL`/`DUPLICATE_PHONE` al crear o editar, 2.30). Se conserva
/// el texto del servidor, que dice el valor repetido.
class DuplicateClientFailure extends ConflictFailure {
  static const defaultMessage =
      'Ya existe un cliente con ese teléfono o email en tu negocio';

  const DuplicateClientFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// Teléfono repetido en el negocio (`DUPLICATE_PHONE`).
class DuplicateClientPhoneFailure extends DuplicateClientFailure {
  static const defaultMessage =
      'Ya existe un cliente con ese teléfono en tu negocio';

  const DuplicateClientPhoneFailure({
    String? message,
    super.code = ApiErrorCode.duplicatePhone,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// El cliente tiene citas o reseñas y no se puede borrar (409 `CONFLICT` de
/// la clave foránea al hacer `DELETE /clients/:id`).
class ClientHasHistoryFailure extends ConflictFailure {
  static const defaultMessage =
      'No se puede eliminar el cliente porque tiene citas o reseñas registradas';

  const ClientHasHistoryFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// Datos de un cliente fuera de las reglas (`ClientRules`). La producen los
/// use cases antes de llamar al backend; [details] lista todos los problemas
/// y [message] los une.
class InvalidClientDataFailure extends ValidationFailure {
  const InvalidClientDataFailure({super.message, super.details});

  factory InvalidClientDataFailure.of(List<String> problems) =>
      InvalidClientDataFailure(message: problems.join('\n'), details: problems);
}
