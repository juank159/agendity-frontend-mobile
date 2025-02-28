import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import '../entities/whatsapp_config.dart';
import '../repositories/whatsapp_repository.dart';

class GetWhatsappConfigUseCase implements UseCase<WhatsappConfig, NoParams> {
  final WhatsappRepository repository;

  GetWhatsappConfigUseCase(this.repository);

  @override
  Future<Either<Failure, WhatsappConfig>> call(NoParams params) {
    return repository.getConfig();
  }
}
