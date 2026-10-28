import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/enums/appointment_payment_status_enum.dart';
import 'package:login_signup/common/enums/appointment_status_enum.dart';

void main() {
  test('estado de la cita: valores del backend, minúsculas antiguas y desconocidos',
      () {
    expect(AppointmentStatus.fromApi('CONFIRMED'), AppointmentStatus.CONFIRMED);
    expect(AppointmentStatus.fromApi('completed'), AppointmentStatus.COMPLETED);
    expect(AppointmentStatus.fromApi('CANCELED'), AppointmentStatus.CANCELLED);
    expect(AppointmentStatus.fromApi('raro'), isNull);
    expect(AppointmentStatus.COMPLETED.isFinal, true);
    expect(AppointmentStatus.CONFIRMED.isFinal, false);
  });

  test('estado de pago de la cita: PARTIAL (anticipo, 2.24)', () {
    expect(AppointmentPaymentStatus.fromApi('PARTIAL'),
        AppointmentPaymentStatus.PARTIAL);
    expect(AppointmentPaymentStatus.fromApi(' partial '),
        AppointmentPaymentStatus.PARTIAL);
    expect(AppointmentPaymentStatus.fromApi(null), isNull);
    expect(AppointmentPaymentStatus.values.map((s) => s.toApi()),
        ['PENDING', 'PARTIAL', 'COMPLETED', 'FAILED', 'REFUNDED', 'CANCELLED']);
    expect(AppointmentPaymentStatus.PARTIAL.hasNetPayments, true);
    expect(AppointmentPaymentStatus.COMPLETED.hasNetPayments, true);
    expect(AppointmentPaymentStatus.REFUNDED.hasNetPayments, false);
    expect(AppointmentPaymentStatus.PARTIAL.isFullyPaid, false);
    expect(AppointmentPaymentStatus.COMPLETED.isFullyPaid, true);
  });
}
