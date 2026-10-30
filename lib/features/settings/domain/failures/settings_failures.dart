import 'package:login_signup/core/errors/failures.dart';

/// La zona elegida no es una zona IANA conocida. La produce el use case
/// antes de llamar al backend (que respondería 400 `VALIDATION_ERROR`).
class InvalidTimeZoneFailure extends ValidationFailure {
  static const defaultMessage = 'Elige una zona horaria válida';

  const InvalidTimeZoneFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// Nombre del negocio vacío o fuera de 2 a 100 caracteres (regla del DTO).
class InvalidBusinessNameFailure extends ValidationFailure {
  static const defaultMessage =
      'El nombre del negocio debe tener entre 2 y 100 caracteres';

  const InvalidBusinessNameFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// Horario de apertura incoherente: día fuera de 1–7, hora que no es `HH:mm`,
/// cierre no posterior a la apertura o franjas del mismo día que se pisan.
/// El mensaje dice cuál.
class InvalidOpeningHoursFailure extends ValidationFailure {
  static const defaultMessage = 'El horario del negocio no es válido';

  const InvalidOpeningHoursFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}
