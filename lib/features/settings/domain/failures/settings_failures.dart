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
