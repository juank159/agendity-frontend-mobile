import 'package:dartz/dartz.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:login_signup/features/settings/data/models/business_settings_model.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/repositories/settings_repository.dart';

/// Configuración del negocio (10.02b): se **lee de la base local** (feed
/// `business_settings`, también sin conexión) y, si aún no ha bajado, del
/// servidor. Los cambios siguen siendo con conexión (no hay
/// `settings.update` en `/sync/push`, decisión del orquestador); su
/// respuesta se guarda también en local.
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource _remote;
  final SessionService _session;

  /// `null` = sin base local (solo red).
  final OfflineStore? _store;

  SettingsRepositoryImpl({
    required SettingsRemoteDataSource remote,
    required SessionService session,
    OfflineStore? store,
  })  : _remote = remote,
        _session = session,
        _store = store;

  @override
  Future<Either<Failure, BusinessSettings>> getSettings() =>
      safeCall(() async {
        final local = await _localDocument();
        if (local != null) {
          return _applied(BusinessSettingsModel.fromJson(local));
        }
        return _applied(await _remote.getSettings());
      });

  Future<Map<String, dynamic>?> _localDocument() async {
    final store = _store;
    if (store == null) return null;
    final docs = await DocumentStore.list(
        await store.database(), SharedDocs.businessSettings.entity);
    return docs.firstOrNull;
  }

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
      safeCall(() async {
        final saved = await _remote.update(changes);
        await _saveLocally(saved);
        return _applied(saved);
      });

  /// La respuesta del PATCH queda también en local (la bajada la confirmará).
  Future<void> _saveLocally(BusinessSettingsModel saved) async {
    final store = _store;
    final local = await _localDocument();
    if (store == null || local == null) return;
    await DocumentStore.put(
        await store.database(), SharedDocs.businessSettings,
        local['id'] as String, {...local, ...saved.toJson()});
  }

  /// La zona que dice el backend es la de la sesión desde ahora.
  Future<BusinessSettings> _applied(BusinessSettingsModel model) async {
    await _session.applyTimeZone(model.timeZone);
    return model.toEntity();
  }
}
