import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_delivery.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_settings.dart';

/// Recordatorios automáticos del negocio (Fase 11, `/reminders/*`). Todo es
/// **solo del Owner** (el Employee recibe `ForbiddenFailure`) y **con
/// conexión**, como la configuración del negocio.
abstract class RemindersRepository {
  /// `GET /reminders/settings`.
  Future<Either<Failure, ReminderSettings>> getSettings();

  /// `PUT /reminders/settings` (`enabled`, ventana).
  Future<Either<Failure, ReminderSettings>> updateSettings(
      ReminderSettings settings);

  /// `GET /reminders/rules`.
  Future<Either<Failure, List<ReminderRule>>> getRules();

  /// `POST /reminders/rules` (sin id) o `PATCH /reminders/rules/:id`.
  /// Repetida → `DuplicateReminderRuleFailure`.
  Future<Either<Failure, ReminderRule>> saveRule(ReminderRule rule);

  /// `DELETE /reminders/rules/:id`.
  Future<Either<Failure, Unit>> deleteRule(String id);

  /// `POST /reminders/rules/preview`: el texto con datos de ejemplo.
  Future<Either<Failure, String>> preview(ReminderKind kind, String template);

  /// `GET /reminders/deliveries`, lo más reciente primero.
  Future<Either<Failure, List<ReminderDelivery>>> getDeliveries(
      DeliveriesQuery query);
}
