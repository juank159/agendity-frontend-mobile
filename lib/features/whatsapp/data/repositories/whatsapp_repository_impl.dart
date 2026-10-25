import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/features/whatsapp/data/datasources/whatsapp_remote_datasource.dart';
import 'package:login_signup/features/whatsapp/data/models/whatsapp_config_model.dart';
import 'package:login_signup/features/whatsapp/domain/entities/whatsapp_config.dart';
import 'package:login_signup/features/whatsapp/domain/repositories/whatsapp_repository.dart';

class WhatsappRepositoryImpl implements WhatsappRepository {
  final WhatsappRemoteDataSource _remote;

  WhatsappRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, WhatsappConfig?>> getConfig() async {
    final result = await safeCall<WhatsappConfig?>(
        () async => (await _remote.getConfig()).toEntity());
    // Sin configuración el backend responde 404: no es un error para la app.
    return result.fold(
      (failure) =>
          failure is NotFoundFailure ? const Right(null) : Left(failure),
      (config) => Right(config),
    );
  }

  @override
  Future<Either<Failure, WhatsappConfig>> saveConfig(WhatsappConfig config) =>
      safeCall(() async =>
          (await _remote.saveConfig(WhatsappConfigModel.fromEntity(config)))
              .toEntity());

  @override
  Future<Either<Failure, bool>> sendTestMessage() =>
      safeCall(_remote.sendTestMessage);

  @override
  Future<Either<Failure, bool>> sendMessage(
          String phoneNumber, String message) =>
      safeCall(() => _remote.sendMessage(phoneNumber, message));
}
