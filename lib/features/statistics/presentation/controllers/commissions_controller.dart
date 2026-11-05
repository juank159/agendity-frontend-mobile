import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import '../../domain/entities/commission_settlement.dart';
import '../../domain/usecases/get_commission_settlement_usecase.dart';
import '../../domain/usecases/stats_use_case.dart';
import 'stats_period_controller.dart';
import 'stats_section.dart';

/// Liquidación de comisiones del período (D-16). La usan dos pantallas:
/// "Comisiones" (`/commissions`, Owner: todo el equipo y lo del negocio) y
/// "Mis ganancias" (`/my-earnings`, Employee: lo suyo, sin lo del negocio, y
/// lo que está por ganar, D-27). Qué ve cada rol lo filtra el backend.
class CommissionsController extends StatsPeriodController {
  final GetCommissionSettlementUseCase _getSettlement;

  CommissionsController({
    required GetCommissionSettlementUseCase getCommissionSettlementUseCase,
    super.clock,
  }) : _getSettlement = getCommissionSettlementUseCase;

  final settlement = StatsSection<CommissionSettlement>();
  Worker? _syncWorker;

  @override
  void onInit() {
    super.onInit();
    // Cuando el negocio completa una cita, la siguiente sincronización la
    // trae y su comisión pasa de "Por ganar" a "Ganado" sin recargar a mano.
    if (Get.isRegistered<SyncController>()) {
      _syncWorker = Get.find<SyncController>().onDataChanged(load);
    }
    load();
  }

  @override
  void onClose() {
    _syncWorker?.dispose();
    super.onClose();
  }

  /// Carga el período. Con datos ya cargados, un fallo no los oculta.
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
