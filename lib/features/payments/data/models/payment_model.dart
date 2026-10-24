import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/core/utils/date_codec.dart';

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
      paymentMethod: _parsePaymentMethod(
          json['payment_method'], json['custom_payment_method_id']),
      customPaymentMethodId: json['custom_payment_method_id'],
      status: PaymentStatus.fromApi(json['status']) ?? PaymentStatus.COMPLETED,
      transactionId: json['transaction_id'],
      paymentDetails: json['payment_details'],
      createdAt: json['created_at'] != null
          ? DateCodec.decode(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateCodec.decode(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointment_id': appointmentId,
      'amount': amount,
      // CUSTOM no existe en el backend: viaja solo como custom_payment_method_id.
      if (paymentMethod.toApi() != null) 'payment_method': paymentMethod.toApi(),
      'custom_payment_method_id': customPaymentMethodId,
      'transaction_id': transactionId,
      'payment_details': paymentDetails,
      // No incluyas created_at ni updated_at
    };
  }

  String getFormattedDate(DateTime date) {
    if (date == null) return 'N/A';
    // Convertir a local y formatear
    final localDate = date.toLocal();
    return '${localDate.day}/${localDate.month}/${localDate.year} - ${localDate.hour}:${localDate.minute.toString().padLeft(2, '0')}';
  }

  /// Estándar → su valor; con método propio del negocio (o un valor que no
  /// se reconoce) → CUSTOM; sin nada → CASH, como antes.
  static PaymentMethod _parsePaymentMethod(Object? method, Object? customId) {
    final standard = PaymentMethod.fromApi(method);
    if (standard != null) return standard;
    return method == null && customId == null
        ? PaymentMethod.CASH
        : PaymentMethod.CUSTOM;
  }

}
