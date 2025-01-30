import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/custom_bottom_navigation_controller.dart';

class CustomBottomNavigation extends GetView<CustomBottomNavigationController> {
  const CustomBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    // Asegurarnos que el controlador esté disponible
    Get.lazyPut<CustomBottomNavigationController>(
      () => CustomBottomNavigationController(),
      fenix: true,
    );

    return Obx(() => NavigationBar(
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: controller.changeIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Reservas',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Búsqueda',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ));
  }
}
