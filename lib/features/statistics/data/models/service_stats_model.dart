import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/statistics/domain/entities/service_stats_entity.dart';

/// DTO de un elemento de `GET /payments/stats/by-service` (`ServiceStats`).
class ServiceStatsModel {
  final String serviceId;
  final String serviceName;
  final int appointmentCount;
  final int paymentCount;
  final double totalAmount;
  final double averageAmount;
  final double percentageOfTotal;

  const ServiceStatsModel({
    required this.serviceId,
    required this.serviceName,
    required this.appointmentCount,
    required this.paymentCount,
    required this.totalAmount,
    required this.averageAmount,
    required this.percentageOfTotal,
  });

  factory ServiceStatsModel.fromJson(Map<String, dynamic> json) =>
      ServiceStatsModel(
        serviceId: JsonRead.asString(json['service_id']),
        serviceName: JsonRead.asString(json['service_name']),
        appointmentCount: JsonRead.asInt(json['appointment_count']),
        paymentCount: JsonRead.asInt(json['payment_count']),
        totalAmount: JsonRead.asDouble(json['total_amount']),
        averageAmount: JsonRead.asDouble(json['average_amount']),
        percentageOfTotal: JsonRead.asDouble(json['percentage_of_total']),
      );

  ServiceStatsEntity toEntity() => ServiceStatsEntity(
        serviceId: serviceId,
        serviceName: serviceName,
        appointmentCount: appointmentCount,
        paymentCount: paymentCount,
        totalAmount: totalAmount,
        averageAmount: averageAmount,
        percentageOfTotal: percentageOfTotal,
      );
}
