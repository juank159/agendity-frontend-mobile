import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/statistics/domain/entities/top_client_entity.dart';

/// DTO de un elemento de `GET /payments/stats/top-clients`.
class TopClientModel {
  final String clientId;
  final String clientName;
  final int visitCount;
  final double totalSpent;

  const TopClientModel({
    required this.clientId,
    required this.clientName,
    required this.visitCount,
    required this.totalSpent,
  });

  factory TopClientModel.fromJson(Map<String, dynamic> json) => TopClientModel(
        clientId: JsonRead.asString(json['client_id']),
        clientName: JsonRead.asString(json['client_name']),
        visitCount: JsonRead.asInt(json['visit_count']),
        totalSpent: JsonRead.asDouble(json['total_spent']),
      );

  TopClientEntity toEntity() => TopClientEntity(
        clientId: clientId,
        clientName: clientName,
        visitCount: visitCount,
        totalSpent: totalSpent,
      );
}
