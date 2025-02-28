// lib/features/whatsapp/domain/usecases/save_whatsapp_config_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import '../entities/whatsapp_config.dart';
import '../repositories/whatsapp_repository.dart';

class SaveWhatsappConfigParams {
  final String phoneNumber;
  final String apiKey;
  final bool isEnabled;

  SaveWhatsappConfigParams({
    required this.phoneNumber,
    required this.apiKey,
    this.isEnabled = true,
  });
}

class SaveWhatsappConfigUseCase
    implements UseCase<WhatsappConfig, SaveWhatsappConfigParams> {
  final WhatsappRepository repository;

  SaveWhatsappConfigUseCase(this.repository);

  @override
  Future<Either<Failure, WhatsappConfig>> call(
      SaveWhatsappConfigParams params) {
    final config = WhatsappConfig(
      phoneNumber: params.phoneNumber,
      apiKey: params.apiKey,
      isEnabled: params.isEnabled,
    );
    return repository.saveConfig(config);
  }
}
