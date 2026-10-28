import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/client_import_result.dart';
import 'package:login_signup/features/clients/domain/failures/client_failures.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';
import 'package:login_signup/features/clients/domain/usecases/client_rules.dart';

/// Importa contactos del teléfono como clientes. Quien llama los lee del
/// dispositivo y los pasa como `ClientEntity` (sin `id`).
///
/// 1. Normaliza cada contacto. Un email inválido se descarta (el cliente se
///    importa sin email): el backend rechazaría el lote entero.
/// 2. Rechaza localmente los que no tienen nombre o tienen un teléfono corto,
///    y los teléfonos repetidos dentro de la lista.
/// 3. Envía el resto en lotes de [batchSize]. El backend importa fila a fila
///    (2.17) y devuelve los rechazados (p. ej. teléfono ya registrado).
///
/// Si el **primer** lote falla (red, permisos…) → `Left` con ese failure. Si
/// falla uno posterior, se detiene y devuelve lo importado hasta ahí con
/// `notSent` e `interruption`. Lista vacía → `InvalidClientDataFailure`.
class ImportClientsUseCase
    extends UseCase<ClientImportResult, List<ClientEntity>> {
  static const batchSize = 50;
  static const noContacts = 'No hay contactos para importar';
  static const repeatedPhone = 'Teléfono repetido en tus contactos';

  final ClientsRepository repository;

  ImportClientsUseCase(this.repository);

  @override
  Future<Either<Failure, ClientImportResult>> call(
      List<ClientEntity> params) async {
    if (params.isEmpty) {
      return const Left(InvalidClientDataFailure(message: noContacts));
    }

    final valid = <ClientEntity>[];
    final rejected = <ClientImportRejection>[];
    final phones = <String>{};
    for (final contact in params) {
      final client = _prepare(contact);
      final problems = ClientRules.check(client);
      final reason = problems.isNotEmpty
          ? problems.join('\n')
          : (phones.add(client.phone) ? null : repeatedPhone);
      if (reason == null) {
        valid.add(client);
      } else {
        rejected.add(ClientImportRejection(
            name: client.fullName, phone: client.phone, reason: reason));
      }
    }

    var result = ClientImportResult(
        requested: params.length - valid.length,
        imported: 0,
        rejected: rejected);

    for (var start = 0; start < valid.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, valid.length);
      final batch = await repository.importClients(valid.sublist(start, end));
      final failure = batch.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) {
        if (start == 0) return Left(failure);
        final pending = valid.length - start;
        return Right(result +
            ClientImportResult(
                requested: pending,
                imported: 0,
                notSent: pending,
                interruption: failure));
      }
      result += batch.getOrElse(() => throw StateError('unreachable'));
    }
    return Right(result);
  }

  /// Normalizado, marcado como importado y sin un email que el backend
  /// rechazaría.
  static ClientEntity _prepare(ClientEntity contact) {
    final client = ClientRules.normalize(contact);
    final email = client.email;
    final keepEmail = email != null && ClientRules.isValidEmail(email);
    return ClientEntity(
      name: client.name,
      lastname: client.lastname,
      email: keepEmail ? email : null,
      phone: client.phone,
      isFromDevice: true,
      deviceContactId: client.deviceContactId,
      notes: client.notes,
      birthday: client.birthday,
      address: client.address,
    );
  }
}
