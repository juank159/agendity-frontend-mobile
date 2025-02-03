// lib/core/providers/calendar_provider.dart
import 'package:calendar_view/calendar_view.dart';
import 'package:get/get.dart';

class CalendarProvider extends GetxService {
  final EventController eventController = EventController();

  static CalendarProvider get to => Get.find<CalendarProvider>();

  @override
  void onInit() {
    super.onInit();
    // Inicialización adicional si es necesaria
  }
}
