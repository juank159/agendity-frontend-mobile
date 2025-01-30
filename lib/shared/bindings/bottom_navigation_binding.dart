// lib/shared/bindings/bottom_navigation_binding.dart
import 'package:get/get.dart';
import '../controller/custom_bottom_navigation_controller.dart';

class BottomNavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CustomBottomNavigationController());
  }
}
