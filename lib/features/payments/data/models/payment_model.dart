import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  PaymentModel({
    super.id,
    required super.appointmentId,
    required super.amount,
    required super.paymentMethod,
    super.customPaymentMethodId,
    super.status = PaymentStatus.COMPLETED,
    super.transactionId,
    super.paymentDetails,
    super.createdAt,
    super.updatedAt,
  });

  factory PaymentModel.fromEntity(PaymentEntity entity) {
    return PaymentModel(
      id: entity.id,
      appointmentId: entity.appointmentId,
      amount: entity.amount,
      paymentMethod: entity.paymentMethod,
      customPaymentMethodId: entity.customPaymentMethodId,
      status: entity.status,
      transactionId: entity.transactionId,
      paymentDetails: entity.paymentDetails,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      appointmentId: json['appointment_id'] ?? '',
      amount: double.parse(json['amount'].toString()),
      paymentMethod: _parsePaymentMethod(json['payment_method']),
      customPaymentMethodId: json['custom_payment_method_id'],
      status: PaymentStatus
          .COMPLETED, // Asumimos que es siempre completado al crearse
      transactionId: json['transaction_id'],
      paymentDetails: json['payment_details'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointment_id': appointmentId,
      'amount': amount,
      'payment_method': paymentMethod.toString().split('.').last,
      'custom_payment_method_id': customPaymentMethodId,
      'transaction_id': transactionId,
      'payment_details': paymentDetails,
    };
  }

  static PaymentMethod _parsePaymentMethod(String? method) {
    if (method == null) return PaymentMethod.CASH;

    switch (method) {
      case 'CASH':
        return PaymentMethod.CASH;
      case 'CREDIT_CARD':
        return PaymentMethod.CREDIT_CARD;
      case 'DEBIT_CARD':
        return PaymentMethod.DEBIT_CARD;
      case 'TRANSFER':
        return PaymentMethod.TRANSFER;
      case 'ONLINE':
        return PaymentMethod.ONLINE;
      default:
        return PaymentMethod.CUSTOM;
    }
  }
}
