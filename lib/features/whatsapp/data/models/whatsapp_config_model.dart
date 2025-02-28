// lib/features/whatsapp/data/models/whatsapp_config_model.dart
import '../../domain/entities/whatsapp_config.dart';

class WhatsappConfigModel extends WhatsappConfig {
  WhatsappConfigModel({
    String? id,
    required String phoneNumber,
    required String apiKey,
    bool isEnabled = true,
  }) : super(
          id: id,
          phoneNumber: phoneNumber,
          apiKey: apiKey,
          isEnabled: isEnabled,
        );

  factory WhatsappConfigModel.fromJson(Map<String, dynamic> json) {
    return WhatsappConfigModel(
      id: json['id'],
      phoneNumber: json['phoneNumber'],
      apiKey: json['apiKey'],
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'phoneNumber': phoneNumber,
      'apiKey': apiKey,
      'isEnabled': isEnabled,
    };
  }

  factory WhatsappConfigModel.fromEntity(WhatsappConfig entity) {
    return WhatsappConfigModel(
      id: entity.id,
      phoneNumber: entity.phoneNumber,
      apiKey: entity.apiKey,
      isEnabled: entity.isEnabled,
    );
  }
}
