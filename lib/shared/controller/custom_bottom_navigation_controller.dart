import 'package:get/get.dart';

class CustomBottomNavigationController extends GetxController {
  static CustomBottomNavigationController get to => Get.find();

  final selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    print('CustomBottomNavigationController: Inicializado'); // Debug log
  }

  @override
  void onReady() {
    super.onReady();
    print('CustomBottomNavigationController: Listo para usar'); // Debug log
  }

  @override
  void onClose() {
    print(
        'CustomBottomNavigationController: Cerrando controlador'); // Debug log
    selectedIndex.value = 0; // Resetear el índice al cerrar
    super.onClose();
  }

  void changeIndex(int index) {
    try {
      print(
          'CustomBottomNavigationController: Cambiando a índice $index'); // Debug log
      selectedIndex.value = index;

      // Navegación con manejo de errores
      String route = _getRouteForIndex(index);
      if (route.isNotEmpty) {
        Get.offNamed(route)?.then((_) {
          print(
              'CustomBottomNavigationController: Navegación exitosa a $route'); // Debug log
        }).catchError((error) {
          print(
              'CustomBottomNavigationController: Error en navegación - $error'); // Debug log
          selectedIndex.value = 0; // Volver al índice inicial en caso de error
        });
      }
    } catch (e) {
      print(
          'CustomBottomNavigationController: Error al cambiar índice - $e'); // Debug log
      selectedIndex.value = 0; // Volver al índice inicial en caso de error
    }
  }

  // Método separado para obtener la ruta basada en el índice
  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/reservas';
      case 2:
        return '/search';
      case 3:
        return '/profile';
      case 4:
        return '/settings';
      default:
        print(
            'CustomBottomNavigationController: Índice no válido - $index'); // Debug log
        return '';
    }
  }

  // Método para resetear el estado del controlador
  void reset() {
    print('CustomBottomNavigationController: Reseteando estado'); // Debug log
    selectedIndex.value = 0;
  }

  // Método para verificar si una ruta es válida
  bool isValidRoute(String route) {
    return ['/home', '/reservas', '/search', '/profile', '/settings']
        .contains(route);
  }
}
