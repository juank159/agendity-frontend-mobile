import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calendar_view/calendar_view.dart';

class CalendarController extends GetxController {
  // Variables reactivas
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxString currentMonth = ''.obs;
  final RxString currentDayName = ''.obs;
  final RxInt currentDay = 0.obs;
  final RxBool isMonthViewVisible = false.obs;

  // Controladores
  final EventController eventController = EventController();
  final dayViewKey = GlobalKey<DayViewState>();

  // Mapas constantes
  static const Map<int, String> months = {
    1: 'enero',
    2: 'febrero',
    3: 'marzo',
    4: 'abril',
    5: 'mayo',
    6: 'junio',
    7: 'julio',
    8: 'agosto',
    9: 'septiembre',
    10: 'octubre',
    11: 'noviembre',
    12: 'diciembre',
  };

  static const Map<int, String> days = {
    1: 'LUN',
    2: 'MAR',
    3: 'MIÉ',
    4: 'JUE',
    5: 'VIE',
    6: 'SÁB',
    7: 'DOM',
  };

  @override
  void onInit() {
    super.onInit();
    updateDateInfo(DateTime.now());
  }

  void toggleMonthView() {
    isMonthViewVisible.value = !isMonthViewVisible.value;
  }

  void onDaySelected(DateTime date) {
    updateDateInfo(date);
    isMonthViewVisible.value = false;
    dayViewKey.currentState?.animateToDate(date);

    // Evento temporal para forzar actualización
    _createTemporaryEvent(date);
  }

  void _createTemporaryEvent(DateTime date) {
    final tempEvent = CalendarEventData(
      date: date,
      title: '',
      startTime: date,
      endTime: date.add(const Duration(minutes: 30)),
    );

    eventController.removeWhere((element) => true);
    eventController.add(tempEvent);

    Future.delayed(
      const Duration(milliseconds: 100),
      () => eventController.removeWhere((element) => true),
    );
  }

  void previousMonth() {
    final newDate =
        DateTime(selectedDate.value.year, selectedDate.value.month - 1);
    updateDateInfo(newDate);
  }

  void nextMonth() {
    final newDate =
        DateTime(selectedDate.value.year, selectedDate.value.month + 1);
    updateDateInfo(newDate);
  }

  void onPageChanged(DateTime date) {
    updateDateInfo(date);
  }

  void updateDateInfo(DateTime date) {
    selectedDate.value = date;
    currentMonth.value = months[date.month] ?? '';
    currentDayName.value = days[date.weekday] ?? '';
    currentDay.value = date.day;
  }
}
