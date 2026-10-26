import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';

/// Borra un servicio por id (solo Owner).
class DeleteServiceUseCase extends UseCase<Unit, String> {
  final ServicesRepository repository;

  DeleteServiceUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      repository.deleteService(params);
}
