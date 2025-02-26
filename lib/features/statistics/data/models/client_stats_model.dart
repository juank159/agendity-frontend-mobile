import '../../domain/entities/client_stats_entity.dart';

class ClientStatsModel extends ClientStatsEntity {
  ClientStatsModel({
    required super.clientId,
    required super.clientName,
    required super.firstVisitDate,
    required super.lastVisitDate,
    required super.visitCount,
    required super.paymentCount,
    required super.totalSpent,
    required super.averagePerPayment,
    required super.frequencyDays,
  });

  factory ClientStatsModel.fromJson(Map<String, dynamic> json) {
    return ClientStatsModel(
      clientId: json['client_id'] as String,
      clientName: json['client_name'] as String,
      firstVisitDate: DateTime.parse(json['first_visit_date']),
      lastVisitDate: DateTime.parse(json['last_visit_date']),
      visitCount: json['visit_count'] as int,
      paymentCount: json['payment_count'] as int,
      totalSpent: (json['total_spent'] as num).toDouble(),
      averagePerPayment: (json['average_per_payment'] as num).toDouble(),
      frequencyDays: json['frequency_days'] as int,
    );
  }
}
