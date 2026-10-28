import 'package:get/get.dart';
import '../controllers/statistics_controller.dart';

/// Solo el controller: los use cases los registra `StatisticsDependencies`.
class StatisticsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<StatisticsController>()) {
      Get.put<StatisticsController>(
        StatisticsController(
          getPaymentStatsUseCase: Get.find(),
          getPaymentComparisonUseCase: Get.find(),
          getPaymentStatsByMethodUseCase: Get.find(),
          getPaymentStatsByProfessionalUseCase: Get.find(),
          getPaymentStatsByServiceUseCase: Get.find(),
          getPaymentStatsByClientUseCase: Get.find(),
          getTopClientsUseCase: Get.find(),
          getEmployeeStatsUseCase: Get.find(),
        ),
      );
    }
  }
}
