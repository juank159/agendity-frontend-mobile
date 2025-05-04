class EmployeeStatsEntity {
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> byService;
  final List<Map<String, dynamic>> dailyEvolution;

  EmployeeStatsEntity({
    required this.summary,
    required this.byService,
    required this.dailyEvolution,
  });
}
