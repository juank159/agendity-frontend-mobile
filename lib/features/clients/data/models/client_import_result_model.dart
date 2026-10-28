import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/clients/domain/entities/client_import_result.dart';

/// Respuesta de `POST /clients/batch` (2.17):
/// `{imported: Client[], errors: [{data, error}], success, failed, total}`.
class ClientImportResultModel {
  final int success;
  final List<ClientImportRejection> errors;

  const ClientImportResultModel({required this.success, required this.errors});

  factory ClientImportResultModel.fromJson(Map<String, dynamic> json) =>
      ClientImportResultModel(
        success: JsonRead.asInt(json['success'],
            fallback: JsonRead.asMapList(json['imported']).length),
        errors: JsonRead.asMapList(json['errors']).map((error) {
          final data = JsonRead.asMap(error['data']) ?? const {};
          final name = JsonRead.asString(data['name']);
          final lastname = JsonRead.asString(data['lastname']);
          return ClientImportRejection(
            name: lastname.isEmpty ? name : '$name $lastname',
            phone: JsonRead.asString(data['phone']),
            reason: JsonRead.asString(error['error'],
                fallback: 'No se pudo importar este cliente'),
          );
        }).toList(),
      );

  /// [sent] = contactos enviados en el lote (no se toma `total` del backend).
  ClientImportResult toEntity({required int sent}) => ClientImportResult(
        requested: sent,
        imported: success,
        rejected: errors,
      );
}
