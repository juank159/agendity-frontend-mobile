import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<PaymentEntity> createPayment(PaymentEntity payment);
}
