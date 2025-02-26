import '../../domain/entities/professional_stats_entity.dart';

class ProfessionalStatsModel extends ProfessionalStatsEntity {
  ProfessionalStatsModel({
    required super.professionalId,
    required super.professionalName,
    required super.appointmentCount,
    required super.paymentCount,
    required super.totalAmount,
    required super.averagePerPayment,
    required super.percentageOfTotal,
  });

  factory ProfessionalStatsModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalStatsModel(
      professionalId: json['professional_id'] as String,
      professionalName: json['professional_name'] as String,
      appointmentCount: json['appointment_count'] as int,
      paymentCount: json['payment_count'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      averagePerPayment: (json['average_per_payment'] as num).toDouble(),
      percentageOfTotal: (json['percentage_of_total'] as num).toDouble(),
    );
  }
}
