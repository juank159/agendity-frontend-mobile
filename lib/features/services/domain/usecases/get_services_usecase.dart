import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';

/// Servicios activos del negocio (Owner y Employee).
class GetServicesUseCase extends UseCase<List<ServiceEntity>, NoParams> {
  final ServicesRepository repository;

  GetServicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ServiceEntity>>> call(NoParams params) =>
      repository.getServices();
}
