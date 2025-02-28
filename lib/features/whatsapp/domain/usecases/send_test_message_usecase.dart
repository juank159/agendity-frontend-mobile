import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import '../repositories/whatsapp_repository.dart';

class SendTestMessageUseCase implements UseCase<bool, NoParams> {
  final WhatsappRepository repository;

  SendTestMessageUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.sendTestMessage();
  }
}
