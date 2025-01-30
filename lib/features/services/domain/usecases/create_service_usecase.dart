// lib/features/services/domain/usecases/create_service_usecase.dart

import 'package:login_signup/features/services/domain/entities/service_entity.dart';

import '../repositories/services_repository.dart';

class CreateServiceUseCase {
  final ServicesRepository repository;

  CreateServiceUseCase(this.repository);

  Future<void> execute(ServiceEntity service) async {
    return await repository.createService(service);
  }
}
