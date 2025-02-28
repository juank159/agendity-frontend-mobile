class WhatsappConfig {
  final String? id;
  final String phoneNumber;
  final String apiKey;
  final bool isEnabled;

  WhatsappConfig({
    this.id,
    required this.phoneNumber,
    required this.apiKey,
    this.isEnabled = true,
  });
}
