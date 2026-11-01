import 'package:login_signup/core/errors/failures.dart';

/// Datos de una regla o de la configuración fuera de las reglas del backend
/// (`reminder.dto.ts`, `templateError`). La produce el use case antes de
/// llamar al backend; [details] lista los problemas.
class InvalidReminderDataFailure extends ValidationFailure {
  const InvalidReminderDataFailure({super.message, super.details});

  factory InvalidReminderDataFailure.of(List<String> problems) =>
      InvalidReminderDataFailure(
          message: problems.join('\n'), details: problems);
}

/// Ya hay una regla igual (409 `CONFLICT`): otro recordatorio de cita con
/// los mismos minutos, o una segunda regla de mantenimiento, cumpleaños o
/// "te extrañamos". Conserva el texto del backend.
class DuplicateReminderRuleFailure extends ConflictFailure {
  static const defaultMessage = 'Ya hay una regla de este tipo; edítala';

  const DuplicateReminderRuleFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}
