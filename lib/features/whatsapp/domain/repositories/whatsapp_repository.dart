import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/whatsapp/domain/entities/whatsapp_config.dart';

abstract class WhatsappRepository {
  Future<Either<Failure, WhatsappConfig>> getConfig();
  Future<Either<Failure, WhatsappConfig>> saveConfig(WhatsappConfig config);
  Future<Either<Failure, bool>> sendTestMessage();
  Future<Either<Failure, bool>> sendMessage(String phoneNumber, String message);
}
