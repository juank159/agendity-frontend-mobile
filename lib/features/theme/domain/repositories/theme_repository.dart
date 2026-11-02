import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/theme/domain/entities/theme_preference.dart';

/// Apariencia guardada en **este dispositivo** (no depende de la sesión: el
/// tema sobrevive al logout y es el mismo para cualquier usuario del equipo).
abstract class ThemeRepository {
  /// Lo guardado; sin nada guardado → `ThemePreference.initial`. Un valor
  /// ilegible cuenta como no guardado (no es un error).
  Future<Either<Failure, ThemePreference>> getPreference();

  /// Guarda la paleta (o la quita si es `null`) y el modo.
  Future<Either<Failure, ThemePreference>> savePreference(
      ThemePreference preference);
}
