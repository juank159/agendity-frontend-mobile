import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/shared/controller/session_controller.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import '../../domain/entities/employee_stats_entity.dart';
import '../../domain/usecases/get_employee_stats_usecase.dart';
import '../../domain/usecases/stats_use_case.dart';
import 'stats_period_controller.dart';
import 'stats_section.dart';

/// "Mis estadísticas" (ruta `/employee-statistics`): solo pide
/// `employee-stats`, el único endpoint de estadísticas que el Employee puede
/// usar. El backend le devuelve siempre las suyas; al Owner le exige
/// `professionalId`, así que para él se piden las de su propio usuario.
class EmployeeStatsController extends StatsPeriodController {
  final GetEmployeeStatsUseCase _getEmployeeStats;
  final SessionController _session;

  EmployeeStatsController({
    required GetEmployeeStatsUseCase getEmployeeStatsUseCase,
    required SessionController session,
    super.clock,
  })  : _getEmployeeStats = getEmployeeStatsUseCase,
        _session = session;

  final stats = StatsSection<EmployeeStatsEntity>();

  EmployeeStatsParams get _params {
    final ownStats = _session.isOnlyEmployee || _session.userId.isEmpty;
    return EmployeeStatsParams(range.value,
        professionalId: ownStats ? null : _session.userId);
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<Failure?> load() => stats.load(() => _getEmployeeStats(_params));

  /// Pull to refresh: si ya había datos y falla, se conservan y se avisa.
  Future<void> refreshStats() async {
    final failure = await load();
    if (failure != null && stats.hasData) {
      AppSnackbar.error(stats.error.value ?? failure.message);
    }
  }

  @override
  void onRangeChanged() {
    stats.reset();
    load();
  }
}
