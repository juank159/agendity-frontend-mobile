import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/clients/domain/failures/client_failures.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';

/// Borra un cliente por id. Con citas o reseñas → `ClientHasHistoryFailure`.
class DeleteClientUseCase extends UseCase<Unit, String> {
  final ClientsRepository repository;

  DeleteClientUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String params) async {
    if (params.trim().isEmpty) {
      return const Left(
          InvalidClientDataFailure(message: 'Falta el cliente a eliminar'));
    }
    return repository.deleteClient(params);
  }
}
