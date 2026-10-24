import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';
import 'package:login_signup/features/payments/data/models/payment_model.dart';

Map<String, dynamic> json({Object? method, Object? customId, Object? status}) => {
      'id': 'p1',
      'appointment_id': 'a1',
      'amount': '50000.00',
      'payment_method': method,
      'custom_payment_method_id': customId,
      if (status != null) 'status': status,
    };

void main() {
  group('PaymentModel.fromJson', () {
    test('método estándar', () {
      expect(PaymentModel.fromJson(json(method: 'TRANSFER')).paymentMethod,
          PaymentMethod.TRANSFER);
    });

    test('método propio del negocio (payment_method null) → CUSTOM', () {
      final model = PaymentModel.fromJson(json(customId: 'c1'));
      expect(model.paymentMethod, PaymentMethod.CUSTOM);
      expect(model.customPaymentMethodId, 'c1');
    });

    test('sin método → CASH (como antes); desconocido → CUSTOM', () {
      expect(PaymentModel.fromJson(json()).paymentMethod, PaymentMethod.CASH);
      expect(PaymentModel.fromJson(json(method: 'NEQUI')).paymentMethod,
          PaymentMethod.CUSTOM);
    });

    test('status del backend; sin status → COMPLETED', () {
      expect(PaymentModel.fromJson(json(method: 'CASH', status: 'REFUNDED'))
          .status, PaymentStatus.REFUNDED);
      expect(PaymentModel.fromJson(json(method: 'CASH')).status,
          PaymentStatus.COMPLETED);
    });
  });

  group('PaymentModel.toJson', () {
    test('estándar envía payment_method', () {
      final body = PaymentModel(
              appointmentId: 'a1',
              amount: 1000,
              paymentMethod: PaymentMethod.CREDIT_CARD)
          .toJson();
      expect(body['payment_method'], 'CREDIT_CARD');
    });

    test('CUSTOM no envía payment_method (el backend no tiene ese valor)', () {
      final body = PaymentModel(
              appointmentId: 'a1',
              amount: 1000,
              paymentMethod: PaymentMethod.CUSTOM,
              customPaymentMethodId: 'c1')
          .toJson();
      expect(body.containsKey('payment_method'), false);
      expect(body['custom_payment_method_id'], 'c1');
    });
  });
}
