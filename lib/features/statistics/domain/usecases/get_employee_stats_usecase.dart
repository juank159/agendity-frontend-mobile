// lib/features/statistics/domain/usecases/get_employee_stats_usecase.dart
import '../entities/employee_stats_entity.dart';
import '../repositories/statistics_repository.dart';

class GetEmployeeStatsUseCase {
  final StatisticsRepository repository;

  GetEmployeeStatsUseCase(this.repository);

  Future<EmployeeStatsEntity> call(DateTime startDate, DateTime endDate) async {
    return await repository.getEmployeeStats(startDate, endDate);
  }
}
