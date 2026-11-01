import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/features/reminders/data/datasources/reminders_remote_datasource.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_delivery.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_settings.dart';
import 'package:login_signup/features/reminders/domain/failures/reminder_failures.dart';
import 'package:login_signup/features/reminders/domain/repositories/reminders_repository.dart';

/// Con conexión (Fase 11): 403 del Employee → `ForbiddenFailure`, 400 →
/// `ValidationFailure`, red → `NetworkFailure` (los da `safeCall`).
class RemindersRepositoryImpl implements RemindersRepository {
  final RemindersRemoteDataSource _remote;

  RemindersRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, ReminderSettings>> getSettings() =>
      safeCall(_remote.getSettings);

  @override
  Future<Either<Failure, ReminderSettings>> updateSettings(
          ReminderSettings settings) =>
      safeCall(() => _remote.updateSettings(settings));

  @override
  Future<Either<Failure, List<ReminderRule>>> getRules() =>
      safeCall(_remote.getRules);

  @override
  Future<Either<Failure, ReminderRule>> saveRule(ReminderRule rule) =>
      safeCall(
        () => rule.id == null
            ? _remote.createRule(rule)
            : _remote.updateRule(rule.id!, rule),
        refine: _refineDuplicate,
      );

  @override
  Future<Either<Failure, Unit>> deleteRule(String id) => safeCall(() async {
        await _remote.deleteRule(id);
        return unit;
      });

  @override
  Future<Either<Failure, String>> preview(ReminderKind kind, String template) =>
      safeCall(() => _remote.preview(kind, template));

  @override
  Future<Either<Failure, List<ReminderDelivery>>> getDeliveries(
          DeliveriesQuery query) =>
      safeCall(() => _remote.getDeliveries(query));

  /// Al guardar una regla, el único 409 es la regla repetida.
  static Failure _refineDuplicate(Failure failure) =>
      failure.code == ApiErrorCode.conflict
          ? DuplicateReminderRuleFailure(
              message: failure.message,
              code: failure.code,
              statusCode: failure.statusCode,
              details: failure.details)
          : failure;
}
