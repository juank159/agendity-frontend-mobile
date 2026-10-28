import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/clients/domain/entities/paginated_list.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';

/// Una página de clientes del negocio con filtros y orden. Una página o un
/// tamaño fuera de rango (`page` ≥ 1, `limit` de 1 a 100) → `ValidationFailure`
/// sin llamar al backend.
class GetClientsPageUseCase
    extends UseCase<PaginatedList<ClientEntity>, ClientsQuery> {
  final ClientsRepository repository;

  GetClientsPageUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedList<ClientEntity>>> call(
      ClientsQuery params) async {
    if (params.page < 1 ||
        params.limit < 1 ||
        params.limit > ClientsQuery.maxLimit) {
      return const Left(ValidationFailure(
          message: 'Página o tamaño de página fuera de rango'));
    }
    return repository.getClients(params);
  }
}
