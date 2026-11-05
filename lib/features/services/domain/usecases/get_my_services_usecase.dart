import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/entities/my_service.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';

/// "Mis servicios" (D-27): los que tiene asignados la profesional de la
/// sesión, con su comisión.
class GetMyServicesUseCase extends UseCase<List<MyService>, NoParams> {
  final ServicesRepository repository;

  GetMyServicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<MyService>>> call(NoParams params) =>
      repository.getMyServices();
}
