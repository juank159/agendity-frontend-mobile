import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/repositories/settings_repository.dart';
import 'package:login_signup/features/settings/domain/usecases/business_settings_rules.dart';

/// Cambia el nombre del negocio (solo Owner). El slug del link público se
/// genera la primera vez y no cambia al renombrar (8.00).
class UpdateBusinessNameUseCase extends UseCase<BusinessSettings, String> {
  final SettingsRepository repository;

  UpdateBusinessNameUseCase(this.repository);

  @override
  Future<Either<Failure, BusinessSettings>> call(String params) async {
    final name = params.trim();
    final invalid = BusinessSettingsRules.checkName(name);
    if (invalid != null) return Left(invalid);
    return repository.updateName(name);
  }
}
