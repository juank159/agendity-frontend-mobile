// lib/core/di/modules/payment_module.dart
// Sin referencias desde la 4.02: el registro vive en
// features/payments/payments_dependencies.dart. Pendiente de borrar (D-12).
import 'package:login_signup/features/payments/payments_dependencies.dart';

class PaymentModule {
  static Future<void> init() async => PaymentsDependencies.init();
}
