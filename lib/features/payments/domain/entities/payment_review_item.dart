import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';

/// Pago en revisión (10.01b, D-18) con lo necesario de su cita para
/// decidir el reembolso en "Pagos por revisar".
class PaymentReviewItem {
  final PaymentEntity payment;
  final String clientName;

  /// Hora de pared del negocio (`null` si la cita no está en local).
  final DateTime? appointmentDate;
  final double appointmentTotal;

  /// Lo que hay que devolver para que el pago deje la revisión: todo si la
  /// cita está cancelada; lo que pasa del total si se pagó de más.
  final double suggestedRefund;

  const PaymentReviewItem({
    required this.payment,
    required this.clientName,
    this.appointmentDate,
    this.appointmentTotal = 0,
    this.suggestedRefund = 0,
  });

  bool get isForCancelledAppointment =>
      payment.reviewRequired == PaymentReviewReason.appointmentCancelled;
}

/// Motivos de revisión de un pago (backend `PAYMENT_REVIEW`).
abstract final class PaymentReviewReason {
  static const appointmentCancelled = 'APPOINTMENT_CANCELLED';
  static const overpaid = 'OVERPAID';
}
