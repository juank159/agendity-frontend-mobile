import 'package:get/get.dart';
import '../../../../core/di/modules/statistics_module.dart';
import '../controllers/statistics_controller.dart';
import '../../domain/usecases/get_payment_stats_usecase.dart';
import '../../domain/usecases/get_payment_comparison_usecase.dart';
import '../../domain/usecases/get_payment_stats_by_method_usecase.dart';
import '../../domain/usecases/get_payment_stats_by_professional_usecase.dart';
import '../../domain/usecases/get_payment_stats_by_service_usecase.dart';
import '../../domain/usecases/get_payment_stats_by_client_usecase.dart';
import '../../domain/usecases/get_top_clients_usecase.dart';

class StatisticsBinding extends Bindings {
  @override
  void dependencies() {
    try {
      // Verificar y registrar dependencias necesarias si no existen
      if (!Get.isRegistered<GetPaymentStatsUseCase>() ||
          !Get.isRegistered<GetPaymentComparisonUseCase>() ||
          !Get.isRegistered<GetPaymentStatsByMethodUseCase>() ||
          !Get.isRegistered<GetPaymentStatsByProfessionalUseCase>() ||
          !Get.isRegistered<GetPaymentStatsByServiceUseCase>() ||
          !Get.isRegistered<GetPaymentStatsByClientUseCase>() ||
          !Get.isRegistered<GetTopClientsUseCase>()) {
        StatisticsModule.init();
      }

      // Registrar el controlador
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
          ),
        );
      }
    } catch (e) {
      print('Error en StatisticsBinding: $e');
      rethrow;
    }
  }
}
