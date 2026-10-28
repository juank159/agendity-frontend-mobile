import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';

/// DTO de `/payments` (backend: `Payment`, snake_case). Los importes llegan
/// como texto (`decimal` de Postgres) y la cita como relación `appointment`.
class PaymentModel {
  final String? id;
  final String appointmentId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? customPaymentMethodId;
  final PaymentStatus status;
  final String? transactionId;
  final double refundAmount;
  final String? refundReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentModel({
    this.id,
    required this.appointmentId,
    required this.amount,
    required this.paymentMethod,
    this.customPaymentMethodId,
    this.status = PaymentStatus.PENDING,
    this.transactionId,
    this.refundAmount = 0,
    this.refundReason,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final customId = _string(json['custom_payment_method_id']);
    return PaymentModel(
      id: _string(json['id']),
      appointmentId: _string(json['appointment_id']) ??
          _string(JsonRead.asMap(json['appointment'])?['id']) ??
          '',
      amount: JsonRead.asDouble(json['amount']),
      paymentMethod: _parsePaymentMethod(json['payment_method'], customId),
      customPaymentMethodId: customId,
      // El backend siempre lo envía; sin él, el default de la columna.
      status: PaymentStatus.fromApi(json['status']) ?? PaymentStatus.PENDING,
      transactionId: _string(json['transaction_id']),
      refundAmount: JsonRead.asDouble(json['refund_amount']),
      refundReason: _string(json['refund_reason']),
      createdAt: DateCodec.tryDecode(json['created_at']),
      updatedAt: DateCodec.tryDecode(json['updated_at']),
    );
  }

  /// Cuerpo de `POST /payments` (`CreatePaymentDto`, con
  /// `forbidNonWhitelisted`): sin id, estado, reembolsos ni fechas.
  /// `CUSTOM` no existe en el backend: viaja solo `custom_payment_method_id`.
  Map<String, dynamic> toJson() {
    final method = paymentMethod.toApi();
    return {
      'appointment_id': appointmentId,
      'amount': amount,
      if (method != null) 'payment_method': method,
      if (method == null && customPaymentMethodId != null)
        'custom_payment_method_id': customPaymentMethodId,
      if (transactionId != null) 'transaction_id': transactionId,
    };
  }

  factory PaymentModel.fromEntity(PaymentEntity entity) => PaymentModel(
        id: entity.id,
        appointmentId: entity.appointmentId,
        amount: entity.amount,
        paymentMethod: entity.paymentMethod,
        customPaymentMethodId: entity.customPaymentMethodId,
        status: entity.status,
        transactionId: entity.transactionId,
        refundAmount: entity.refundAmount,
        refundReason: entity.refundReason,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );

  PaymentEntity toEntity() => PaymentEntity(
        id: id,
        appointmentId: appointmentId,
        amount: amount,
        paymentMethod: paymentMethod,
        customPaymentMethodId: customPaymentMethodId,
        status: status,
        transactionId: transactionId,
        refundAmount: refundAmount,
        refundReason: refundReason,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Estándar → su valor; con método propio del negocio (o un valor que no
  /// se reconoce) → CUSTOM; sin nada → CASH, como antes.
  static PaymentMethod _parsePaymentMethod(Object? method, String? customId) {
    final standard = PaymentMethod.fromApi(method);
    if (standard != null) return standard;
    return method == null && customId == null
        ? PaymentMethod.CASH
        : PaymentMethod.CUSTOM;
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}
