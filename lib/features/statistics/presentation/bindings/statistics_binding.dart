import 'package:get/get.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import '../controllers/commissions_controller.dart';
import '../controllers/employee_stats_controller.dart';
import '../controllers/statistics_controller.dart';

/// Panel del negocio (`/statistics`, solo Owner). Solo el controller: los use
/// cases los registra `StatisticsDependencies`. Sin `fenix`: ninguna otra
/// pantalla lo busca y vive con su ruta.
class StatisticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StatisticsController>(
      () => StatisticsController(
        getPaymentStatsUseCase: Get.find(),
        getPaymentComparisonUseCase: Get.find(),
        getPaymentStatsByMethodUseCase: Get.find(),
        getPaymentStatsByProfessionalUseCase: Get.find(),
        getPaymentStatsByServiceUseCase: Get.find(),
        getTopClientsUseCase: Get.find(),
        session: Get.find<SessionController>(),
      ),
    );
  }
}

/// "Mis estadísticas" (`/employee-statistics`). Igual que [StatisticsBinding].
class EmployeeStatsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeeStatsController>(
      () => EmployeeStatsController(
        getEmployeeStatsUseCase: Get.find(),
        session: Get.find<SessionController>(),
      ),
    );
  }
}

/// Liquidación de comisiones (`/commissions`, Owner y Employee).
class CommissionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CommissionsController>(
      () => CommissionsController(
        getCommissionSettlementUseCase: Get.find(),
        session: Get.find<SessionController>(),
      ),
    );
  }
}
