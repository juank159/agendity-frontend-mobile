import 'package:login_signup/features/whatsapp/domain/entities/whatsapp_config.dart';

/// DTO de `/whatsapp/config` (backend: `WhatsappConfiguration`, camelCase).
class WhatsappConfigModel {
  final String? id;
  final String phoneNumber;
  final String apiKey;
  final bool isEnabled;

  const WhatsappConfigModel({
    this.id,
    required this.phoneNumber,
    required this.apiKey,
    this.isEnabled = true,
  });

  factory WhatsappConfigModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final isEnabled = json['isEnabled'];
    return WhatsappConfigModel(
      id: id == null || id.toString().isEmpty ? null : id.toString(),
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      apiKey: json['apiKey']?.toString() ?? '',
      isEnabled: isEnabled is bool ? isEnabled : isEnabled != 'false',
    );
  }

  /// Cuerpo de `POST /whatsapp/config` (el DTO del backend no admite `id`).
  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'apiKey': apiKey,
        'isEnabled': isEnabled,
      };

  factory WhatsappConfigModel.fromEntity(WhatsappConfig entity) =>
      WhatsappConfigModel(
        id: entity.id,
        phoneNumber: entity.phoneNumber,
        apiKey: entity.apiKey,
        isEnabled: entity.isEnabled,
      );

  WhatsappConfig toEntity() => WhatsappConfig(
        id: id,
        phoneNumber: phoneNumber,
        apiKey: apiKey,
        isEnabled: isEnabled,
      );
}
