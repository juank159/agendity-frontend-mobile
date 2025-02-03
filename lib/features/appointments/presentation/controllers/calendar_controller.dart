import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calendar_view/calendar_view.dart';

class CalendarController extends GetxController {
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxString currentMonth = ''.obs;
  final RxString currentDayName = ''.obs;
  final RxInt currentDay = 0.obs;
  final RxBool isMonthViewVisible = false.obs;
  final EventController eventController = EventController();
  final dayViewKey = GlobalKey<DayViewState>();

  @override
  void onInit() {
    super.onInit();
    updateDateInfo(DateTime.now());
  }

  void toggleMonthView() {
    isMonthViewVisible.value = !isMonthViewVisible.value;
  }

  void onDaySelected(DateTime date) {
    print('onDaySelected llamado con fecha: ${date.toString()}');

    updateDateInfo(date);
    isMonthViewVisible.value = false;

    print('Intentando navegar usando DayViewState');
    dayViewKey.currentState?.animateToDate(date);

    print('Antes de crear evento temporal');
    // Crear un evento temporal para forzar la actualización
    final tempEvent = CalendarEventData(
      date: date,
      title: '',
      startTime: date,
      endTime: date.add(const Duration(minutes: 30)),
    );
    print('Evento temporal creado');

    print('Limpiando eventos anteriores');
    eventController.removeWhere((element) => true);

    print('Añadiendo evento temporal');
    eventController.add(tempEvent);

    print('Selected Date actualizado a: ${selectedDate.value}');

    // Intentar forzar la actualización del DayView
    Future.delayed(const Duration(milliseconds: 100), () {
      print('Ejecutando delayed');
      eventController.removeWhere((element) => true);
      print('Eventos removidos después del delay');
    });
  }

  // void onDaySelected(DateTime date) {
  //   updateDateInfo(date);
  //   isMonthViewVisible.value = false;
  // }

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
    print('onPageChanged llamado con fecha: ${date.toString()}');
    updateDateInfo(date);
  }

  void updateDateInfo(DateTime date) {
    print('updateDateInfo llamado con fecha: ${date.toString()}');
    selectedDate.value = date;
    updateMonth(date);
    updateDayName(date);
    currentDay.value = date.day;
    print(
        'Información actualizada: Día=${currentDay.value}, Mes=${currentMonth.value}');
  }

  void updateMonth(DateTime date) {
    const months = {
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
    currentMonth.value = months[date.month] ?? '';
  }

  void updateDayName(DateTime date) {
    const days = {
      1: 'LUN',
      2: 'MAR',
      3: 'MIÉ',
      4: 'JUE',
      5: 'VIE',
      6: 'SÁB',
      7: 'DOM',
    };
    currentDayName.value = days[date.weekday] ?? '';
  }
}
