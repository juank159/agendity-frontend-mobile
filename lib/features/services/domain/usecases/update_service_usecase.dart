import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';

class UpdateServiceUseCase {
  final ServicesRepository repository;

  UpdateServiceUseCase(this.repository);

  Future<void> execute(String id, ServiceEntity service) {
    return repository.updateService(id, service);
  }
}
