import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/di/session_scope.dart';

class _DataController extends GetxController {
  static int created = 0;
  final items = <String>[].obs;
  bool closed = false;
  _DataController() {
    created++;
  }
  @override
  void onClose() {
    closed = true;
    super.onClose();
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    _DataController.created = 0;
  });
  tearDown(Get.reset);

  test('borra un controller permanente y llama a onClose', () {
    final c = Get.put(_DataController(), permanent: true)..items.add('x');
    deleteSessionController<_DataController>();
    expect(Get.isRegistered<_DataController>(), isFalse);
    expect(c.closed, isTrue);
  });

  test('con fenix conserva la fábrica y crea una instancia vacía', () {
    Get.lazyPut(() => _DataController(), fenix: true);
    Get.find<_DataController>().items.add('de la cuenta anterior');
    deleteSessionController<_DataController>();
    final fresh = Get.find<_DataController>();
    expect(fresh.items, isEmpty);
    expect(_DataController.created, 2);
  });

  test('sin registro no hace nada', () {
    expect(() => deleteSessionController<_DataController>(), returnsNormally);
  });

  test('la lista de SessionScope no incluye los de alcance de app', () {
    // 18 controllers de feature (inventario de la 3.05) menos
    // EditCategoryController, muerto (retirado en la 4.03), más
    // EmployeeStatsController (4.04: "Mis estadísticas" tiene el suyo).
    expect(SessionScope.featureControllers, hasLength(18));
  });
}
