import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/theme/domain/entities/theme_preference.dart';
import 'package:login_signup/features/theme/domain/repositories/theme_repository.dart';

/// Guarda la apariencia del dispositivo. `palette: null` = "usar la del
/// negocio". Sin conexión y para cualquier rol: es local.
class SaveThemePreferenceUseCase
    extends UseCase<ThemePreference, ThemePreference> {
  final ThemeRepository repository;

  SaveThemePreferenceUseCase(this.repository);

  @override
  Future<Either<Failure, ThemePreference>> call(ThemePreference params) =>
      repository.savePreference(params);
}
