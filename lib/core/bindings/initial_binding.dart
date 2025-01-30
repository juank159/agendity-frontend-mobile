import 'package:get/get.dart';
import '../../shared/controller/custom_bottom_navigation_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomBottomNavigationController>(
      () => CustomBottomNavigationController(),
      fenix: true,
    );
  }
}
