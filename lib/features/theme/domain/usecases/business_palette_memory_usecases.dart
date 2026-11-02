import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/theme/domain/entities/theme_preference.dart';
import 'package:login_signup/features/theme/domain/repositories/theme_repository.dart';

/// Última paleta del negocio vista en este dispositivo (12.03): la app arranca
/// con ella y así no parpadea de lavanda a la del negocio. `null` = ninguna.
class GetLastBusinessPaletteUseCase extends UseCase<AppPalette?, NoParams> {
  final ThemeRepository repository;

  GetLastBusinessPaletteUseCase(this.repository);

  @override
  Future<Either<Failure, AppPalette?>> call(NoParams params) =>
      repository.getLastBusinessPalette();
}

/// Guarda la paleta del negocio recién leída (o la borra con `null`).
class RememberBusinessPaletteUseCase extends UseCase<AppPalette?, AppPalette?> {
  final ThemeRepository repository;

  RememberBusinessPaletteUseCase(this.repository);

  @override
  Future<Either<Failure, AppPalette?>> call(AppPalette? params) =>
      repository.rememberBusinessPalette(params);
}
