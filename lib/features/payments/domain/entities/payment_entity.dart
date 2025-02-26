// import 'package:login_signup/common/enums/payment_method_enum.dart';
// import 'package:login_signup/common/enums/payment_status_enum.dart';

// class PaymentEntity {
//   final String id;
//   final String appointmentId;
//   final double amount;
//   final PaymentMethod paymentMethod;
//   final String? customPaymentMethodId;
//   final PaymentStatus status;
//   final String? transactionId;
//   final Map<String, dynamic>? paymentDetails;
//   final DateTime createdAt;
//   final DateTime updatedAt;

//   const PaymentEntity({
//     this.id = '',
//     required this.appointmentId,
//     required this.amount,
//     required this.paymentMethod,
//     this.customPaymentMethodId,
//     this.status = PaymentStatus.COMPLETED,
//     this.transactionId,
//     this.paymentDetails,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   })  : this.createdAt = createdAt ?? DateTime.now(),
//         this.updatedAt = updatedAt ?? DateTime.now();
// }

import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';

class PaymentEntity {
  final String id;
  final String appointmentId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? customPaymentMethodId;
  final PaymentStatus status;
  final String? transactionId;
  final Map<String, dynamic>? paymentDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentEntity({
    this.id = '',
    required this.appointmentId,
    required this.amount,
    required this.paymentMethod,
    this.customPaymentMethodId,
    this.status = PaymentStatus.COMPLETED,
    this.transactionId,
    this.paymentDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();
}
