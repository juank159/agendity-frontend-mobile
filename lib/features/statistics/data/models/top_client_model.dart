import '../../domain/entities/top_client_entity.dart';

class TopClientModel extends TopClientEntity {
  TopClientModel({
    required super.clientId,
    required super.clientName,
    required super.visitCount,
    required super.totalSpent,
  });

  factory TopClientModel.fromJson(Map<String, dynamic> json) {
    return TopClientModel(
      clientId: json['client_id'] as String,
      clientName: json['client_name'] as String,
      visitCount: json['visit_count'] as int,
      totalSpent: (json['total_spent'] as num).toDouble(),
    );
  }
}
