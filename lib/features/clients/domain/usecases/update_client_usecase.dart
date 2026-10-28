import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/failures/client_failures.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';
import 'package:login_signup/features/clients/domain/usecases/client_rules.dart';

/// Edita un cliente ([params] con `id`). Mismas reglas que el alta; un email
/// vacío lo quita. Teléfono o email repetido → `DuplicateClientFailure`.
class UpdateClientUseCase extends UseCase<ClientEntity, ClientEntity> {
  static const missingId = 'Falta el cliente a editar';

  final ClientsRepository repository;

  UpdateClientUseCase(this.repository);

  @override
  Future<Either<Failure, ClientEntity>> call(ClientEntity params) async {
    final client = ClientRules.normalize(params);
    final problems = [
      if (client.id == null || client.id!.trim().isEmpty) missingId,
      ...ClientRules.check(client),
    ];
    if (problems.isNotEmpty) {
      return Left(InvalidClientDataFailure.of(problems));
    }
    return repository.updateClient(client);
  }
}
