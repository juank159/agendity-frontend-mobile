// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:calendar_view/calendar_view.dart';
// import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
// import 'package:login_signup/features/appointments/domain/usescases/get_appointments_usecase.dart';

// class CalendarController extends GetxController {
//   final GetAppointmentsUseCase getAppointmentsUseCase;

//   // Variables reactivas
//   final Rx<DateTime> selectedDate = DateTime.now().obs;
//   final RxString currentMonth = ''.obs;
//   final RxString currentDayName = ''.obs;
//   final RxInt currentDay = 0.obs;
//   final RxBool isMonthViewVisible = false.obs;

//   final RxList<AppointmentEntity> appointments = <AppointmentEntity>[].obs;
//   final RxBool isLoading = false.obs;

//   CalendarController(this.getAppointmentsUseCase);

//   // Controladores
//   final EventController eventController = EventController();
//   final dayViewKey = GlobalKey<DayViewState>();

//   // Mapas constantes
//   static const Map<int, String> months = {
//     1: 'enero',
//     2: 'febrero',
//     3: 'marzo',
//     4: 'abril',
//     5: 'mayo',
//     6: 'junio',
//     7: 'julio',
//     8: 'agosto',
//     9: 'septiembre',
//     10: 'octubre',
//     11: 'noviembre',
//     12: 'diciembre',
//   };

//   static const Map<int, String> days = {
//     1: 'LUN',
//     2: 'MAR',
//     3: 'MIÉ',
//     4: 'JUE',
//     5: 'VIE',
//     6: 'SÁB',
//     7: 'DOM',
//   };

//   @override
//   void onInit() {
//     super.onInit();
//     updateDateInfo(DateTime.now());
//     loadAppointments();
//   }

//   Future<void> loadAppointments() async {
//     try {
//       isLoading.value = true;
//       final appointmentsList = await getAppointmentsUseCase();
//       appointments.value = appointmentsList;
//       _updateCalendarEvents();
//     } catch (e) {
//       print('Error loading appointments: $e');
//       // Handle error (show snackbar, etc.)
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void _updateCalendarEvents() {
//     eventController.removeWhere((element) => true);
//     for (var appointment in appointments) {
//       final event = CalendarEventData(
//         date: appointment.date,
//         title: appointment.service.name,
//         description: appointment.client.name,
//         startTime: appointment.date,
//         endTime: appointment.date
//             .add(Duration(minutes: appointment.service.duration)),
//         color:
//             Color(int.parse(appointment.service.color.replaceAll('#', '0xFF'))),
//       );
//       eventController.add(event);
//     }
//   }

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calendar_view/calendar_view.dart'
    show DayView, DayViewState, EventController, CalendarEventData;
//import 'package:calendar_view/calendar_view.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_appointments_usecase.dart';

class CalendarController extends GetxController {
  final GetAppointmentsUseCase _getAppointmentsUseCase;

  // Variables reactivas
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxString currentMonth = ''.obs;
  final RxString currentDayName = ''.obs;
  final RxInt currentDay = 0.obs;
  final RxBool isMonthViewVisible = false.obs;
  final RxList appointments = [].obs;
  final RxBool isLoading = false.obs;

  // Controladores
  final EventController eventController = EventController();
  final dayViewKey = GlobalKey<DayViewState>();

  CalendarController(this._getAppointmentsUseCase);

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
    loadAppointmentsForDate(DateTime.now());
  }

  Future<void> loadAppointmentsForDate(DateTime date) async {
    try {
      isLoading.value = true;

      // Crear fecha de inicio y fin para el día seleccionado
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = startDate
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1));

      print('Cargando citas para el día: ${date.toString()}');
      print('Rango de fechas: $startDate - $endDate');

      final result = await _getAppointmentsUseCase(
        startDate: startDate,
        endDate: endDate,
      );

      appointments.value = result;
      _updateCalendarEvents();
    } catch (e) {
      print('Error cargando citas: $e');
      Get.snackbar(
        'Error',
        'No se pudieron cargar las citas',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAppointments() async {
    try {
      isLoading.value = true;
      final result = await _getAppointmentsUseCase();
      print('Citas cargadas: ${result.length}'); // Añadir este log
      appointments.value = result;
      _updateCalendarEvents();
    } catch (e) {
      print('Error loading appointments: $e');
      Get.snackbar('Error', 'No se pudieron cargar las citas');
    } finally {
      isLoading.value = false;
    }
  }

  void _updateCalendarEvents() {
    try {
      print('=== INICIO ACTUALIZACIÓN EVENTOS ===');
      eventController.removeWhere((element) => true);

      for (var appointment in appointments) {
        // Convertir la fecha UTC a local manteniendo la hora original
        final originalDate = DateTime.parse(appointment.date.toString());
        print('Fecha original de BD: $originalDate');

        // Crear el evento usando las horas y minutos originales
        final eventDate = DateTime(
          originalDate.year,
          originalDate.month,
          originalDate.day,
          originalDate.hour, // Usar la hora original de la cita
          originalDate.minute, // Usar los minutos originales de la cita
        );

        print('Fecha evento a crear: $eventDate');

        final event = CalendarEventData(
          date: eventDate,
          title: appointment.service.name,
          description:
              '${appointment.client.name} ${appointment.client.lastname}',
          startTime: eventDate,
          endTime:
              eventDate.add(Duration(minutes: appointment.service.duration)),
          color: _getColorFromHex(appointment.service.color),
        );

        print(
            'Evento creado para ${event.title} a las ${event.startTime?.hour}:${event.startTime?.minute}');
        eventController.add(event);
      }

      print('=== FIN ACTUALIZACIÓN EVENTOS ===');
    } catch (e) {
      print('Error actualizando eventos del calendario: $e');
    }
  }

  // void _updateCalendarEvents() {
  //   try {
  //     eventController.removeWhere((element) => true);

  //     for (var appointment in appointments) {
  //       final utcDate = DateTime.parse(appointment.date.toString());
  //       final eventDate = DateTime(
  //         utcDate.year,
  //         utcDate.month,
  //         utcDate.day,
  //         utcDate.hour + 6, // Ajuste de zona horaria
  //         utcDate.minute,
  //       );

  //       final event = CalendarEventData(
  //         date: eventDate,
  //         title: appointment.service.name,
  //         description:
  //             '${appointment.client.name} ${appointment.client.lastname}',
  //         startTime: eventDate,
  //         endTime:
  //             eventDate.add(Duration(minutes: appointment.service.duration)),
  //         color: _getColorFromHex(appointment.service.color),
  //       );

  //       eventController.add(event);
  //     }
  //   } catch (e) {
  //     print('Error actualizando eventos del calendario: $e');
  //   }
  // }

  Color _getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF' + hexColor;
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      print('Error parsing color: $e');
      return Colors.blue; // Color por defecto
    }
  }

  void toggleMonthView() {
    isMonthViewVisible.value = !isMonthViewVisible.value;
  }

  void onDaySelected(DateTime date) {
    updateDateInfo(date);
    isMonthViewVisible.value = false;

    // Usar el GlobalKey para acceder al estado del DayView
    if (dayViewKey.currentState != null) {
      // Esto animará el DayView a la fecha seleccionada
      dayViewKey.currentState!.animateToDate(date);
    }

    // Recargar las citas si es necesario
    if (date.day != selectedDate.value.day ||
        date.month != selectedDate.value.month ||
        date.year != selectedDate.value.year) {
      loadAppointments();
    }
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
    print('Cambiando a fecha: $date');
    updateDateInfo(date);
    loadAppointmentsForDate(date);
  }

  void updateDateInfo(DateTime date) {
    selectedDate.value = date;
    currentMonth.value = months[date.month] ?? '';
    currentDayName.value = days[date.weekday] ?? '';
    currentDay.value = date.day;
  }
}
