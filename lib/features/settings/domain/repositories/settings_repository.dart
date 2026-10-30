import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';

/// Configuración del negocio de la sesión. Toda respuesta correcta actualiza
/// la zona del negocio de la sesión (`SessionService.applyTimeZone`), con la
/// que `DateCodec` interpreta y presenta las horas.
abstract class SettingsRepository {
  /// `GET /settings` (Owner y Employee).
  Future<Either<Failure, BusinessSettings>> getSettings();

  /// `PATCH /settings {timezone}` (solo Owner: el Employee recibe
  /// `ForbiddenFailure`). Devuelve la configuración guardada, con el nombre
  /// canónico de la zona.
  Future<Either<Failure, BusinessSettings>> updateTimeZone(String timeZone);

  /// `PATCH /settings {name}` (solo Owner).
  Future<Either<Failure, BusinessSettings>> updateName(String name);

  /// `PATCH /settings {opening_hours}` (solo Owner). `null` = sin horario.
  Future<Either<Failure, BusinessSettings>> updateOpeningHours(
      OpeningHours? hours);
}
