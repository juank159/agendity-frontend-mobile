import 'package:login_signup/features/services/domain/repositories/services_repository.dart';

class DeleteServiceUseCase {
  final ServicesRepository repository;

  DeleteServiceUseCase(this.repository);

  Future<void> execute(String id) {
    return repository.deleteService(id);
  }
}
