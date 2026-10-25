/// Configuración de CallMeBot del negocio (solo la ve y edita el Owner).
class WhatsappConfig {
  final String? id;

  /// Número del Owner con indicativo de país, solo dígitos (`57300…`).
  final String phoneNumber;
  final String apiKey;
  final bool isEnabled;

  const WhatsappConfig({
    this.id,
    required this.phoneNumber,
    required this.apiKey,
    this.isEnabled = true,
  });

  WhatsappConfig copyWith({
    String? id,
    String? phoneNumber,
    String? apiKey,
    bool? isEnabled,
  }) =>
      WhatsappConfig(
        id: id ?? this.id,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        apiKey: apiKey ?? this.apiKey,
        isEnabled: isEnabled ?? this.isEnabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhatsappConfig &&
          other.id == id &&
          other.phoneNumber == phoneNumber &&
          other.apiKey == apiKey &&
          other.isEnabled == isEnabled;

  @override
  int get hashCode => Object.hash(id, phoneNumber, apiKey, isEnabled);
}
