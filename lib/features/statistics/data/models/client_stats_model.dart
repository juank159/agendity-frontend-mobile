import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/statistics/domain/entities/client_stats_entity.dart';

/// DTO de un elemento de `GET /payments/stats/by-client` (`ClientStats`).
/// Las visitas son instantes con offset (fecha de la cita); un `Date`
/// inválido del backend llega como `null`.
class ClientStatsModel {
  final String clientId;
  final String clientName;
  final DateTime? firstVisitDate;
  final DateTime? lastVisitDate;
  final int visitCount;
  final int paymentCount;
  final double totalSpent;
  final double averagePerPayment;
  final int frequencyDays;

  const ClientStatsModel({
    required this.clientId,
    required this.clientName,
    this.firstVisitDate,
    this.lastVisitDate,
    required this.visitCount,
    required this.paymentCount,
    required this.totalSpent,
    required this.averagePerPayment,
    required this.frequencyDays,
  });

  factory ClientStatsModel.fromJson(Map<String, dynamic> json) =>
      ClientStatsModel(
        clientId: JsonRead.asString(json['client_id']),
        clientName: JsonRead.asString(json['client_name']),
        firstVisitDate: DateCodec.tryDecode(json['first_visit_date']),
        lastVisitDate: DateCodec.tryDecode(json['last_visit_date']),
        visitCount: JsonRead.asInt(json['visit_count']),
        paymentCount: JsonRead.asInt(json['payment_count']),
        totalSpent: JsonRead.asDouble(json['total_spent']),
        averagePerPayment: JsonRead.asDouble(json['average_per_payment']),
        frequencyDays: JsonRead.asInt(json['frequency_days']),
      );

  ClientStatsEntity toEntity() => ClientStatsEntity(
        clientId: clientId,
        clientName: clientName,
        firstVisitDate: firstVisitDate,
        lastVisitDate: lastVisitDate,
        visitCount: visitCount,
        paymentCount: paymentCount,
        totalSpent: totalSpent,
        averagePerPayment: averagePerPayment,
        frequencyDays: frequencyDays,
      );
}
