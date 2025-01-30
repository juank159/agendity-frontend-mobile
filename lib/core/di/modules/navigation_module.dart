import 'package:get/get.dart';
import 'package:login_signup/shared/controller/custom_bottom_navigation_controller.dart';

class NavigationModule {
  static void init() {
    try {
      Get.put<CustomBottomNavigationController>(
        CustomBottomNavigationController(),
        permanent: true,
      );
    } catch (e) {
      print('Error initializing NavigationModule: $e');
      rethrow;
    }
  }
}
