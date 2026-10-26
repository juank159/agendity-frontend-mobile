import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/failures/services_failures.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';
import 'package:login_signup/features/services/domain/usecases/catalog_rules.dart';

/// Edita un servicio existente (solo Owner); [params] debe traer `id`.
/// Mismas reglas que el alta. Nombre repetido → `DuplicateServiceNameFailure`.
class UpdateServiceUseCase extends UseCase<ServiceEntity, ServiceEntity> {
  static const missingIdMessage =
      'No se puede editar un servicio sin identificador';

  final ServicesRepository repository;

  UpdateServiceUseCase(this.repository);

  @override
  Future<Either<Failure, ServiceEntity>> call(ServiceEntity params) async {
    final id = params.id;
    if (id == null || id.isEmpty) {
      return const Left(InvalidCatalogDataFailure(message: missingIdMessage));
    }
    final service = params.copyWith(
        name: params.name.trim(), description: params.description.trim());
    final invalid = CatalogRules.checkService(service);
    if (invalid != null) return Left(invalid);
    return repository.updateService(service);
  }
}
