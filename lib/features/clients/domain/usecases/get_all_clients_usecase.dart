import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';

/// Todos los clientes del negocio sin paginar. Solo lo usa el recordatorio
/// manual de citas, que busca el teléfono por nombre; la 4.09 lo sustituye
/// por el cliente de la cita y entonces se retira.
class GetAllClientsUseCase extends UseCase<List<ClientEntity>, NoParams> {
  final ClientsRepository repository;

  GetAllClientsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ClientEntity>>> call(NoParams params) =>
      repository.getAllClients();
}
