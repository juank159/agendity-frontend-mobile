import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';
import 'package:login_signup/features/payments/data/models/payment_model.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';

/// Respuesta real de `POST /payments` (RELATIONS.MINIMAL: la cita va anidada).
Map<String, dynamic> backendPayment({
  Object? method = 'CASH',
  Object? customId,
  Object? status = 'COMPLETED',
  Object? refund,
}) =>
    {
      'id': 'p1',
      'ownerId': 'owner-1',
      'amount': '50000.00',
      'payment_method': method,
      'custom_payment_method_id': customId,
      'status': status,
      'transaction_id': null,
      'payment_details': null,
      'refund_reason': refund == null ? null : 'Cliente insatisfecho',
      'refund_amount': refund,
      'created_at': '2026-10-21T08:00:00.000-05:00',
      'updated_at': '2026-10-21T08:00:00.000-05:00',
      'appointment': {'id': 'a1', 'status': 'CONFIRMED'},
    };

void main() {
  group('PaymentModel.fromJson', () {
    test('respuesta real del backend → entidad', () {
      final entity = PaymentModel.fromJson(backendPayment()).toEntity();
      expect(
          entity,
          PaymentEntity(
            id: 'p1',
            appointmentId: 'a1',
            amount: 50000,
            paymentMethod: PaymentMethod.CASH,
            status: PaymentStatus.COMPLETED,
            createdAt: DateTime.utc(2026, 10, 21, 13).toLocal(),
            updatedAt: DateTime.utc(2026, 10, 21, 13).toLocal(),
          ));
      expect(entity.netAmount, 50000);
    });

    test('appointment_id plano también vale', () {
      final json = backendPayment()
        ..remove('appointment')
        ..['appointment_id'] = 'a2';
      expect(PaymentModel.fromJson(json).appointmentId, 'a2');
    });

    test('reembolso parcial: refund_amount como texto y neto', () {
      final entity =
          PaymentModel.fromJson(backendPayment(refund: '20000.50')).toEntity();
      expect(entity.status, PaymentStatus.COMPLETED);
      expect(entity.refundAmount, 20000.5);
      expect(entity.refundReason, 'Cliente insatisfecho');
      expect(entity.netAmount, 29999.5);
    });

    test('método estándar', () {
      expect(
          PaymentModel.fromJson(backendPayment(method: 'TRANSFER'))
              .paymentMethod,
          PaymentMethod.TRANSFER);
    });

    test('método propio del negocio (payment_method null) → CUSTOM', () {
      final model =
          PaymentModel.fromJson(backendPayment(method: null, customId: 'c1'));
      expect(model.paymentMethod, PaymentMethod.CUSTOM);
      expect(model.customPaymentMethodId, 'c1');
    });

    test('sin método → CASH (como antes); desconocido → CUSTOM', () {
      expect(PaymentModel.fromJson(backendPayment(method: null)).paymentMethod,
          PaymentMethod.CASH);
      expect(PaymentModel.fromJson(backendPayment(method: 'NEQUI')).paymentMethod,
          PaymentMethod.CUSTOM);
    });

    test('status del backend; sin status → PENDING (default de la columna)',
        () {
      expect(PaymentModel.fromJson(backendPayment(status: 'REFUNDED')).status,
          PaymentStatus.REFUNDED);
      expect(PaymentModel.fromJson(backendPayment(status: null)).status,
          PaymentStatus.PENDING);
    });

    test('tolerante: nulls, números y fechas inválidas', () {
      final model = PaymentModel.fromJson({
        'id': null,
        'amount': 45000,
        'refund_amount': null,
        'created_at': 'no-es-fecha',
      });
      expect(model.id, isNull);
      expect(model.appointmentId, '');
      expect(model.amount, 45000);
      expect(model.refundAmount, 0);
      expect(model.createdAt, isNull);
    });
  });

  group('PaymentModel.toJson (CreatePaymentDto)', () {
    test('estándar: solo los campos del DTO, sin nulls', () {
      final body = PaymentModel.fromEntity(const PaymentEntity(
        id: 'p1',
        appointmentId: 'a1',
        amount: 1000,
        paymentMethod: PaymentMethod.CREDIT_CARD,
        customPaymentMethodId: 'ignorado',
        status: PaymentStatus.COMPLETED,
        refundAmount: 10,
      )).toJson();
      expect(body, {
        'appointment_id': 'a1',
        'amount': 1000.0,
        'payment_method': 'CREDIT_CARD',
      });
    });

    test('CUSTOM no envía payment_method (el backend no tiene ese valor)', () {
      final body = const PaymentModel(
        appointmentId: 'a1',
        amount: 1000,
        paymentMethod: PaymentMethod.CUSTOM,
        customPaymentMethodId: 'c1',
        transactionId: 'TRX1',
      ).toJson();
      expect(body, {
        'appointment_id': 'a1',
        'amount': 1000.0,
        'custom_payment_method_id': 'c1',
        'transaction_id': 'TRX1',
      });
    });

    test('fromEntity/toEntity ida y vuelta', () {
      final entity = PaymentEntity(
        id: 'p1',
        appointmentId: 'a1',
        amount: 1000,
        paymentMethod: PaymentMethod.CUSTOM,
        customPaymentMethodId: 'c1',
        status: PaymentStatus.REFUNDED,
        transactionId: 'T',
        refundAmount: 1000,
        refundReason: 'r',
        createdAt: DateTime.utc(2026),
      );
      expect(PaymentModel.fromEntity(entity).toEntity(), entity);
    });
  });
}
