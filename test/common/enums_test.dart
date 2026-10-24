import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/enums/appointment_status_enum.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';

void main() {
  group('AppointmentStatus', () {
    test('valores idénticos al backend', () {
      expect(AppointmentStatus.values.map((s) => s.toApi()),
          ['PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED']);
    });

    test('fromApi tolerante', () {
      expect(AppointmentStatus.fromApi('CONFIRMED'), AppointmentStatus.CONFIRMED);
      expect(AppointmentStatus.fromApi(' completed '),
          AppointmentStatus.COMPLETED);
      expect(AppointmentStatus.fromApi('pending'), AppointmentStatus.PENDING);
      expect(AppointmentStatus.fromApi('canceled'), AppointmentStatus.CANCELLED);
      for (final value in [null, '', 'DONE', 3]) {
        expect(AppointmentStatus.fromApi(value), isNull, reason: '$value');
      }
    });

    test('ida y vuelta', () {
      for (final status in AppointmentStatus.values) {
        expect(AppointmentStatus.fromApi(status.toApi()), status);
      }
    });

    test('estados finales', () {
      expect(AppointmentStatus.values.where((s) => s.isFinal),
          [AppointmentStatus.COMPLETED, AppointmentStatus.CANCELLED]);
    });
  });

  group('PaymentStatus', () {
    test('valores idénticos al backend', () {
      expect(PaymentStatus.values.map((s) => s.toApi()),
          ['PENDING', 'COMPLETED', 'FAILED', 'REFUNDED', 'CANCELLED']);
    });

    test('fromApi tolerante', () {
      expect(PaymentStatus.fromApi('refunded'), PaymentStatus.REFUNDED);
      expect(PaymentStatus.fromApi('CANCELED'), PaymentStatus.CANCELLED);
      expect(PaymentStatus.fromApi(null), isNull);
      expect(PaymentStatus.fromApi('PAID'), isNull);
      for (final status in PaymentStatus.values) {
        expect(PaymentStatus.fromApi(status.toApi()), status);
      }
    });
  });

  group('PaymentMethod', () {
    test('estándar idénticos al backend; CUSTOM no se envía', () {
      expect(
          PaymentMethod.values.map((m) => m.toApi()),
          ['CASH', 'CREDIT_CARD', 'DEBIT_CARD', 'TRANSFER', 'ONLINE', null]);
    });

    test('fromApi tolerante y nunca devuelve CUSTOM', () {
      expect(PaymentMethod.fromApi('credit_card'), PaymentMethod.CREDIT_CARD);
      expect(PaymentMethod.fromApi('debit-card'), PaymentMethod.DEBIT_CARD);
      expect(PaymentMethod.fromApi(' Cash '), PaymentMethod.CASH);
      expect(PaymentMethod.fromApi('CUSTOM'), isNull);
      expect(PaymentMethod.fromApi('NEQUI'), isNull);
      expect(PaymentMethod.fromApi(null), isNull);
    });
  });
}
