import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';
import 'package:login_signup/features/services/domain/usecases/catalog_rules.dart';

/// Crea un servicio (solo Owner). Valida las reglas del backend antes de
/// enviarlo (`InvalidCatalogDataFailure`); nombre y descripción van sin
/// espacios sobrantes. Nombre repetido → `DuplicateServiceNameFailure`.
class CreateServiceUseCase extends UseCase<ServiceEntity, ServiceEntity> {
  final ServicesRepository repository;

  CreateServiceUseCase(this.repository);

  @override
  Future<Either<Failure, ServiceEntity>> call(ServiceEntity params) async {
    final service = params.copyWith(
        name: params.name.trim(), description: params.description.trim());
    final invalid = CatalogRules.checkService(service);
    if (invalid != null) return Left(invalid);
    return repository.createService(service);
  }
}
