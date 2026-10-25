// lib/core/di/modules/whatsapp_module.dart
// Sin referencias desde la 4.01: el registro vive en
// features/whatsapp/whatsapp_dependencies.dart. Pendiente de borrar (D-12).
import 'package:login_signup/features/whatsapp/whatsapp_dependencies.dart';

class WhatsappModule {
  static Future<void> init() async => WhatsappDependencies.init();
}
