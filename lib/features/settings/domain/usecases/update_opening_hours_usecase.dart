import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/repositories/settings_repository.dart';
import 'package:login_signup/features/settings/domain/usecases/business_settings_rules.dart';

/// Guarda el horario de apertura (solo Owner, 8.01). `null` = quitarlo (el
/// negocio no limita las citas por horario); `OpeningHours.closed` = cerrado
/// todos los días. Valida antes de enviar: apertura antes del cierre y sin
/// franjas que se pisen. Fuera del horario el backend responde
/// `OUTSIDE_BUSINESS_HOURS` al agendar.
class UpdateOpeningHoursUseCase
    extends UseCase<BusinessSettings, OpeningHours?> {
  final SettingsRepository repository;

  UpdateOpeningHoursUseCase(this.repository);

  @override
  Future<Either<Failure, BusinessSettings>> call(OpeningHours? params) async {
    if (params == null) return repository.updateOpeningHours(null);
    final hours = BusinessSettingsRules.normalize(params);
    final invalid = BusinessSettingsRules.checkOpeningHours(hours);
    if (invalid != null) return Left(invalid);
    return repository.updateOpeningHours(hours);
  }
}
