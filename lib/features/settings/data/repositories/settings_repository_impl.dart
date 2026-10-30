import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:login_signup/features/settings/data/models/business_settings_model.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource _remote;
  final SessionService _session;

  SettingsRepositoryImpl({
    required SettingsRemoteDataSource remote,
    required SessionService session,
  })  : _remote = remote,
        _session = session;

  @override
  Future<Either<Failure, BusinessSettings>> getSettings() =>
      safeCall(() async => _applied(await _remote.getSettings()));

  @override
  Future<Either<Failure, BusinessSettings>> updateTimeZone(String timeZone) =>
      _update(BusinessSettingsModel.timeZoneUpdate(timeZone));

  @override
  Future<Either<Failure, BusinessSettings>> updateName(String name) =>
      _update(BusinessSettingsModel.nameUpdate(name));

  @override
  Future<Either<Failure, BusinessSettings>> updateOpeningHours(
          OpeningHours? hours) =>
      _update(BusinessSettingsModel.openingHoursUpdate(hours));

  Future<Either<Failure, BusinessSettings>> _update(
          Map<String, dynamic> changes) =>
      safeCall(() async => _applied(await _remote.update(changes)));

  /// La zona que dice el backend es la de la sesión desde ahora.
  Future<BusinessSettings> _applied(BusinessSettingsModel model) async {
    await _session.applyTimeZone(model.timeZone);
    return model.toEntity();
  }
}
