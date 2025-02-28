// lib/features/whatsapp/domain/usecases/send_message_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import '../repositories/whatsapp_repository.dart';

class SendMessageParams {
  final String phoneNumber;
  final String message;

  SendMessageParams({
    required this.phoneNumber,
    required this.message,
  });
}

class SendMessageUseCase implements UseCase<bool, SendMessageParams> {
  final WhatsappRepository repository;

  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(SendMessageParams params) {
    return repository.sendMessage(params.phoneNumber, params.message);
  }
}
