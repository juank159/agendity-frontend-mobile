import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/repositories/settings_repository.dart';

/// Configuración del negocio (hoy, su zona horaria).
class GetBusinessSettingsUseCase extends UseCase<BusinessSettings, NoParams> {
  final SettingsRepository repository;

  GetBusinessSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, BusinessSettings>> call(NoParams params) =>
      repository.getSettings();
}
