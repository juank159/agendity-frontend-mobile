import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import '../../domain/entities/commission_settlement.dart';
import '../../domain/usecases/get_commission_settlement_usecase.dart';
import '../../domain/usecases/stats_use_case.dart';
import 'stats_period_controller.dart';
import 'stats_section.dart';

/// Liquidación de comisiones (`/commissions`, D-16): citas completadas del
/// período con lo que toca a cada profesional y al negocio. El Owner ve a
/// todo el equipo; el Employee, solo lo suyo (lo filtra el backend).
class CommissionsController extends StatsPeriodController {
  final GetCommissionSettlementUseCase _getSettlement;
  final SessionController _session;

  CommissionsController({
    required GetCommissionSettlementUseCase getCommissionSettlementUseCase,
    required SessionController session,
    super.clock,
  })  : _getSettlement = getCommissionSettlementUseCase,
        _session = session;

  final settlement = StatsSection<CommissionSettlement>();

  /// El Employee solo ve su propia liquidación.
  bool get isOwnOnly => _session.isOnlyEmployee;

  String get title => isOwnOnly ? 'Mis comisiones' : 'Comisiones';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<Failure?> load() =>
      settlement.load(() => _getSettlement(EmployeeStatsParams(range.value)));

  /// Pull to refresh: si ya había datos y falla, se conservan y se avisa.
  Future<void> refreshSettlement() async {
    final failure = await load();
    if (failure != null && settlement.hasData) {
      AppSnackbar.error(settlement.error.value ?? failure.message);
    }
  }

  @override
  void onRangeChanged() {
    settlement.reset();
    load();
  }
}
