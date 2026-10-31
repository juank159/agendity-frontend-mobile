import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';

/// Todos los servicios, también los desactivados (gestión del catálogo:
/// interruptor de activo, 2026-10-31).
class GetAllServicesUseCase extends UseCase<List<ServiceEntity>, NoParams> {
  final ServicesRepository repository;

  GetAllServicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ServiceEntity>>> call(NoParams params) =>
      repository.getAllServices();
}
