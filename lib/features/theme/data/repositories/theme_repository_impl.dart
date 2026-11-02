import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/features/theme/data/datasources/theme_local_datasource.dart';
import 'package:login_signup/features/theme/data/models/theme_preference_model.dart';
import 'package:login_signup/features/theme/domain/entities/theme_preference.dart';
import 'package:login_signup/features/theme/domain/repositories/theme_repository.dart';

/// Apariencia del dispositivo, solo local (sin red ni sesión).
class ThemeRepositoryImpl implements ThemeRepository {
  final ThemeLocalDataSource _local;

  ThemeRepositoryImpl(this._local);

  @override
  Future<Either<Failure, ThemePreference>> getPreference() =>
      safeCall(() async => (await _local.read()).toEntity());

  @override
  Future<Either<Failure, ThemePreference>> savePreference(
          ThemePreference preference) =>
      safeCall(() async {
        await _local.write(ThemePreferenceModel.fromEntity(preference));
        return preference;
      });

  @override
  Future<Either<Failure, AppPalette?>> getLastBusinessPalette() => safeCall(
      () async => AppPalette.fromId(await _local.readBusinessPalette()));

  @override
  Future<Either<Failure, AppPalette?>> rememberBusinessPalette(
          AppPalette? palette) =>
      safeCall(() async {
        await _local.writeBusinessPalette(palette?.id);
        return palette;
      });
}
