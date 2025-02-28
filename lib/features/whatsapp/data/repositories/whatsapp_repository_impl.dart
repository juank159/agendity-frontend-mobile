// lib/features/whatsapp/data/repositories/whatsapp_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/exceptions.dart';
import 'package:login_signup/core/errors/failures.dart';
import '../../domain/entities/whatsapp_config.dart';
import '../../domain/repositories/whatsapp_repository.dart';
import '../datasources/whatsapp_remote_datasource.dart';
import '../models/whatsapp_config_model.dart';

import '../../../../core/network/network_info.dart';

class WhatsappRepositoryImpl implements WhatsappRepository {
  final WhatsappRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  WhatsappRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, WhatsappConfig>> getConfig() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteConfig = await remoteDataSource.getConfig();
        return Right(remoteConfig);
      } on NotFoundException {
        // Si no existe configuración, devolvemos una vacía en lugar de un error
        return Right(WhatsappConfigModel(
          phoneNumber: '',
          apiKey: '',
          isEnabled: true,
        ));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, WhatsappConfig>> saveConfig(
      WhatsappConfig config) async {
    if (await networkInfo.isConnected) {
      try {
        final configModel = WhatsappConfigModel.fromEntity(config);
        final savedConfig = await remoteDataSource.saveConfig(configModel);
        return Right(savedConfig);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> sendTestMessage() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.sendTestMessage();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> sendMessage(
      String phoneNumber, String message) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.sendMessage(phoneNumber, message);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure());
    }
  }
}
