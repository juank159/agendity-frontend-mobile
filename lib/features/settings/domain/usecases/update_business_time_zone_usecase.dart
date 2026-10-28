import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/failures/settings_failures.dart';
import 'package:login_signup/features/settings/domain/repositories/settings_repository.dart';

/// Cambia la zona horaria del negocio (solo Owner). Una zona desconocida →
/// `InvalidTimeZoneFailure` sin llamar al backend. Al guardarla, la sesión
/// pasa a la zona nueva: las horas que se carguen después se ven en ella
/// (lo ya cargado hay que volver a pedirlo). Las citas, pagos y bloqueos ya
/// creados conservan su propia zona (backend 6.03).
class UpdateBusinessTimeZoneUseCase extends UseCase<BusinessSettings, String> {
  final SettingsRepository repository;

  UpdateBusinessTimeZoneUseCase(this.repository);

  @override
  Future<Either<Failure, BusinessSettings>> call(String params) async {
    final timeZone = BusinessTimeZone.canonicalName(params);
    if (timeZone == null) return const Left(InvalidTimeZoneFailure());
    return repository.updateTimeZone(timeZone);
  }
}
