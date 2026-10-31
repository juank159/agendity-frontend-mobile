import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';

/// Servicios que hace un profesional (7.04): el catálogo del formulario de
/// cita. Para la empleada, [call] con su propio id = solo sus servicios
/// (equivalente local de `GET /auth/me/services`). Sin conexión, igual.
class GetServicesOfferedByUseCase
    extends UseCase<List<ServiceEntity>, String> {
  final ServicesRepository repository;

  GetServicesOfferedByUseCase(this.repository);

  @override
  Future<Either<Failure, List<ServiceEntity>>> call(String professionalId) =>
      repository.getServicesOfferedBy(professionalId);
}
