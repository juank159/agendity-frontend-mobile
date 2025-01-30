import '../entities/service_entity.dart';
import '../repositories/services_repository.dart';

class GetServicesUseCase {
  final ServicesRepository repository;

  GetServicesUseCase(this.repository);

  Future<List<ServiceEntity>> execute() async {
    return await repository.getServices();
  }
}
