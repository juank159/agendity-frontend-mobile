import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/controllers/reschedule_list_controller.dart';

/// "Citas por mover" (`/appointments/to-reschedule`, Owner y empleada).
class RescheduleListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RescheduleListController>(
      () => RescheduleListController(
          getAppointmentsToRescheduleUseCase: Get.find()),
    );
  }
}
