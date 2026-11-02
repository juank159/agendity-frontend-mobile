import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/theme/domain/entities/theme_preference.dart';
import 'package:login_signup/features/theme/domain/repositories/theme_repository.dart';

/// Apariencia guardada en el dispositivo (paleta propia o `null` y modo).
class GetThemePreferenceUseCase extends UseCase<ThemePreference, NoParams> {
  final ThemeRepository repository;

  GetThemePreferenceUseCase(this.repository);

  @override
  Future<Either<Failure, ThemePreference>> call(NoParams params) =>
      repository.getPreference();
}
