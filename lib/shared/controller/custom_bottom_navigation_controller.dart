import 'package:get/get.dart';

class CustomBottomNavigationController extends GetxController {
  static CustomBottomNavigationController get to => Get.find();

  final selectedIndex = 0.obs;

  void changeIndex(int index) {
    selectedIndex.value = index;
    // Aquí puedes agregar la navegación a las diferentes vistas
    switch (index) {
      case 0:
        Get.toNamed('/home');
        break;
      case 1:
        Get.toNamed('/reservas');
        break;
      case 2:
        Get.toNamed('/search');
        break;
      case 3:
        Get.toNamed('/profile');
        break;
      case 4:
        Get.toNamed('/settings');
        break;
    }
  }
}
