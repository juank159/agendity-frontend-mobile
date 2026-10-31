import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';

/// Servicios del negocio. Leer: Owner y Employee. Escribir: solo Owner (el
/// Employee recibe `ForbiddenFailure`).
abstract class ServicesRepository {
  /// Servicios activos del negocio, con su categoría.
  Future<Either<Failure, List<ServiceEntity>>> getServices();

  /// Todos, también los desactivados (gestión del catálogo, 2026-10-31).
  Future<Either<Failure, List<ServiceEntity>>> getAllServices();

  /// Servicios activos que hace [professionalId] (7.04, como
  /// `GET /auth/me/services`): el Owner, todos; un empleado, los asignados y
  /// activos. Para el catálogo del formulario de cita.
  Future<Either<Failure, List<ServiceEntity>>> getServicesOfferedBy(
      String professionalId);

  /// Nombre repetido en el negocio → `DuplicateServiceNameFailure`.
  Future<Either<Failure, ServiceEntity>> createService(ServiceEntity service);

  /// [service] debe traer `id`. Nombre repetido → `DuplicateServiceNameFailure`.
  Future<Either<Failure, ServiceEntity>> updateService(ServiceEntity service);

  Future<Either<Failure, Unit>> deleteService(String id);
}
