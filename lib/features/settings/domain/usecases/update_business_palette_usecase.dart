import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/repositories/settings_repository.dart';

/// Cambia la paleta del negocio (12.02, D-22): la ven todos los dispositivos
/// del negocio que no eligieron una propia y la web de reservas. `null` =
/// quitarla (lavanda). Como el resto de ajustes, solo el Owner (el Employee
/// recibe `ForbiddenFailure`) y con conexión (`NetworkFailure` sin red; no
/// hay `settings.update` en `/sync/push`).
class UpdateBusinessPaletteUseCase
    extends UseCase<BusinessSettings, AppPalette?> {
  final SettingsRepository repository;

  UpdateBusinessPaletteUseCase(this.repository);

  @override
  Future<Either<Failure, BusinessSettings>> call(AppPalette? params) =>
      repository.updateThemePalette(params);
}
