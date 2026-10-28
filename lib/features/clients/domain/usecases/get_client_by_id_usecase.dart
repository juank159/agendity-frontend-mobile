import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';

/// Un cliente del negocio por id. Inexistente o de otro negocio →
/// `NotFoundFailure`.
class GetClientByIdUseCase extends UseCase<ClientEntity, String> {
  final ClientsRepository repository;

  GetClientByIdUseCase(this.repository);

  @override
  Future<Either<Failure, ClientEntity>> call(String params) =>
      repository.getClientById(params);
}
