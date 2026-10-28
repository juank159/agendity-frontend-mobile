import 'package:login_signup/core/errors/failures.dart';

/// Un contacto que no se importó y por qué.
class ClientImportRejection {
  final String name;
  final String phone;

  /// Motivo apto para el usuario (del backend o de la validación local).
  final String reason;

  const ClientImportRejection({
    required this.name,
    required this.phone,
    required this.reason,
  });

  @override
  bool operator ==(Object other) =>
      other is ClientImportRejection &&
      other.name == name &&
      other.phone == phone &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(name, phone, reason);

  @override
  String toString() => 'ClientImportRejection($phone: $reason)';
}

/// Resultado PARCIAL de importar contactos (backend 2.17: cada fila se guarda
/// o se rechaza por separado).
///
/// - [imported]: clientes creados.
/// - [rejected]: contactos rechazados, por la validación local (sin nombre,
///   teléfono corto, repetido en la lista) o por el backend (teléfono ya
///   registrado en el negocio…).
/// - [notSent]: contactos que no llegaron al backend porque un lote falló
///   (red, sesión…); [interruption] dice por qué.
class ClientImportResult {
  final int requested;
  final int imported;
  final List<ClientImportRejection> rejected;
  final int notSent;
  final Failure? interruption;

  const ClientImportResult({
    required this.requested,
    required this.imported,
    this.rejected = const [],
    this.notSent = 0,
    this.interruption,
  });

  /// Todo lo que no quedó importado.
  int get failed => rejected.length + notSent;

  /// `true` si todos los contactos llegaron al backend.
  bool get isComplete => notSent == 0 && interruption == null;

  /// Suma de dos resultados (lotes). [requested] se suma también.
  ClientImportResult operator +(ClientImportResult other) => ClientImportResult(
        requested: requested + other.requested,
        imported: imported + other.imported,
        rejected: [...rejected, ...other.rejected],
        notSent: notSent + other.notSent,
        interruption: interruption ?? other.interruption,
      );

  @override
  String toString() => 'ClientImportResult($imported de $requested, '
      '${rejected.length} rechazados, $notSent sin enviar)';
}
