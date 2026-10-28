import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/failures/client_failures.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';
import 'package:login_signup/features/clients/domain/usecases/client_rules.dart';

/// Crea un cliente. Normaliza los datos (`ClientRules.normalize`: email vacío
/// = sin email) y los valida antes de enviarlos (`InvalidClientDataFailure`).
/// Teléfono o email repetido → `DuplicateClientFailure`.
class CreateClientUseCase extends UseCase<ClientEntity, ClientEntity> {
  final ClientsRepository repository;

  CreateClientUseCase(this.repository);

  @override
  Future<Either<Failure, ClientEntity>> call(ClientEntity params) async {
    final client = ClientRules.normalize(params);
    final problems = ClientRules.check(client);
    if (problems.isNotEmpty) {
      return Left(InvalidClientDataFailure.of(problems));
    }
    return repository.createClient(client);
  }
}
