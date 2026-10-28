import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/statistics/domain/entities/professional_stats_entity.dart';

/// DTO de un elemento de `GET /payments/stats/by-professional`
/// (`ProfessionalStats`). El nombre llega como `name + ' ' + lastname`, con
/// espacio final si no hay apellido: se recorta.
class ProfessionalStatsModel {
  final String professionalId;
  final String professionalName;
  final int appointmentCount;
  final int paymentCount;
  final double totalAmount;
  final double averagePerPayment;
  final double percentageOfTotal;

  const ProfessionalStatsModel({
    required this.professionalId,
    required this.professionalName,
    required this.appointmentCount,
    required this.paymentCount,
    required this.totalAmount,
    required this.averagePerPayment,
    required this.percentageOfTotal,
  });

  factory ProfessionalStatsModel.fromJson(Map<String, dynamic> json) =>
      ProfessionalStatsModel(
        professionalId: JsonRead.asString(json['professional_id']),
        professionalName: JsonRead.asString(json['professional_name']),
        appointmentCount: JsonRead.asInt(json['appointment_count']),
        paymentCount: JsonRead.asInt(json['payment_count']),
        totalAmount: JsonRead.asDouble(json['total_amount']),
        averagePerPayment: JsonRead.asDouble(json['average_per_payment']),
        percentageOfTotal: JsonRead.asDouble(json['percentage_of_total']),
      );

  ProfessionalStatsEntity toEntity() => ProfessionalStatsEntity(
        professionalId: professionalId,
        professionalName: professionalName,
        appointmentCount: appointmentCount,
        paymentCount: paymentCount,
        totalAmount: totalAmount,
        averagePerPayment: averagePerPayment,
        percentageOfTotal: percentageOfTotal,
      );
}
