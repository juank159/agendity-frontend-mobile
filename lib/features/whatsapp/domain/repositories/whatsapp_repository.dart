import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/whatsapp/domain/entities/whatsapp_config.dart';

abstract class WhatsappRepository {
  /// `Right(null)` si el negocio aún no tiene configuración (el backend da 404).
  /// Un Employee recibe `Left(ForbiddenFailure)`: la configuración es del Owner.
  Future<Either<Failure, WhatsappConfig?>> getConfig();

  /// Crea o actualiza (el backend guarda una sola por negocio).
  Future<Either<Failure, WhatsappConfig>> saveConfig(WhatsappConfig config);

  /// `Right(false)` si CallMeBot no lo aceptó o no hay configuración activa.
  Future<Either<Failure, bool>> sendTestMessage();

  /// CallMeBot entrega siempre al número del Owner, no a [phoneNumber].
  Future<Either<Failure, bool>> sendMessage(String phoneNumber, String message);
}
