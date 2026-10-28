import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/client_import_result.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/clients/domain/entities/paginated_list.dart';

/// Clientes del negocio. Owner y Employee leen y escriben los del negocio
/// (el backend filtra por el negocio del token). Un cliente de otro negocio o
/// inexistente → `NotFoundFailure`; un id mal formado → `ValidationFailure`.
abstract class ClientsRepository {
  Future<Either<Failure, PaginatedList<ClientEntity>>> getClients(
      ClientsQuery query);

  /// Todos los clientes sin paginar (`GET /clients/all`). Pesado: solo para
  /// el recordatorio manual hasta la 4.09.
  Future<Either<Failure, List<ClientEntity>>> getAllClients();

  Future<Either<Failure, ClientEntity>> getClientById(String id);

  /// Teléfono o email repetido → `DuplicateClientFailure` (o
  /// `DuplicateClientPhoneFailure`).
  Future<Either<Failure, ClientEntity>> createClient(ClientEntity client);

  /// [client] debe traer `id`. Mismos failures que [createClient].
  Future<Either<Failure, ClientEntity>> updateClient(ClientEntity client);

  /// Con citas o reseñas → `ClientHasHistoryFailure`.
  Future<Either<Failure, Unit>> deleteClient(String id);

  /// Un lote (`POST /clients/batch`): resultado parcial con los rechazados
  /// por el backend. Un lote con un dato inválido falla entero
  /// (`ValidationFailure`): los use cases los filtran antes.
  Future<Either<Failure, ClientImportResult>> importClients(
      List<ClientEntity> clients);

  /// Sube la foto (`POST /upload/image`, carpeta `clients`) y devuelve su URL.
  Future<Either<Failure, String>> uploadImage(String filePath);
}
