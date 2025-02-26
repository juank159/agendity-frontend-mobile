import '../../domain/entities/service_stats_entity.dart';

class ServiceStatsModel extends ServiceStatsEntity {
  ServiceStatsModel({
    required super.serviceId,
    required super.serviceName,
    required super.paymentCount,
    required super.totalAmount,
    required super.averageAmount,
    required super.percentageOfTotal,
  });

  factory ServiceStatsModel.fromJson(Map<String, dynamic> json) {
    return ServiceStatsModel(
      serviceId: json['service_id'] as String,
      serviceName: json['service_name'] as String,
      paymentCount: json['payment_count'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      averageAmount: (json['average_amount'] as num).toDouble(),
      percentageOfTotal: (json['percentage_of_total'] as num).toDouble(),
    );
  }
}
