import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/clients/domain/failures/client_failures.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';

/// Sube la foto de un cliente (ruta del archivo en el dispositivo) y devuelve
/// su URL, que luego se guarda en `ClientEntity.image` al crear o editar.
class UploadClientImageUseCase extends UseCase<String, String> {
  final ClientsRepository repository;

  UploadClientImageUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(String params) async {
    if (params.trim().isEmpty) {
      return const Left(
          InvalidClientDataFailure(message: 'No se eligió ninguna imagen'));
    }
    return repository.uploadImage(params);
  }
}
