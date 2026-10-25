// lib/features/statistics/data/models/employee_stats_model.dart
import '../../domain/entities/employee_stats_entity.dart';

class EmployeeStatsModel extends EmployeeStatsEntity {
  EmployeeStatsModel({
    required super.summary,
    required super.byService,
    required super.dailyEvolution,
  });

  factory EmployeeStatsModel.fromJson(Map<String, dynamic> json) {
    return EmployeeStatsModel(
      summary: json['summary'] ?? {},
      byService: (json['by_service'] as List?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ??
          [],
      dailyEvolution: (json['daily_evolution'] as List?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}
