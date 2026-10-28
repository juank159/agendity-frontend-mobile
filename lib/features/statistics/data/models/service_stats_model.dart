import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/statistics/domain/entities/service_stats_entity.dart';

/// DTO de un elemento de `GET /payments/stats/by-service` (`ServiceStats`).
class ServiceStatsModel {
  final String serviceId;
  final String serviceName;
  final int paymentCount;
  final double totalAmount;
  final double averageAmount;
  final double percentageOfTotal;

  const ServiceStatsModel({
    required this.serviceId,
    required this.serviceName,
    required this.paymentCount,
    required this.totalAmount,
    required this.averageAmount,
    required this.percentageOfTotal,
  });

  factory ServiceStatsModel.fromJson(Map<String, dynamic> json) =>
      ServiceStatsModel(
        serviceId: JsonRead.asString(json['service_id']),
        serviceName: JsonRead.asString(json['service_name']),
        paymentCount: JsonRead.asInt(json['payment_count']),
        totalAmount: JsonRead.asDouble(json['total_amount']),
        averageAmount: JsonRead.asDouble(json['average_amount']),
        percentageOfTotal: JsonRead.asDouble(json['percentage_of_total']),
      );

  ServiceStatsEntity toEntity() => ServiceStatsEntity(
        serviceId: serviceId,
        serviceName: serviceName,
        paymentCount: paymentCount,
        totalAmount: totalAmount,
        averageAmount: averageAmount,
        percentageOfTotal: percentageOfTotal,
      );
}
