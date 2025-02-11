import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_calendar.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_form_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/view_selector_bottom_sheet.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../controllers/appointments_controller.dart';
import 'package:login_signup/shared/custom_drawer.dart';

class AppointmentsView extends GetView<AppointmentsController> {
  const AppointmentsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const CustomDrawer(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Obx(() {
        String title = 'Mis Citas';
        switch (controller.currentView.value) {
          case CalendarView.day:
            title = 'Vista Diaria';
            break;
          case CalendarView.week:
            title = 'Vista Semanal';
            break;
          case CalendarView.month:
            title = 'Vista Mensual';
            break;
          default:
            title = 'Mis Citas';
        }
        return Text(title);
      }),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_view_day),
          onPressed: () => ViewSelectorBottomSheet.show(context, controller),
          tooltip: 'Cambiar vista',
        ),
        IconButton(
          icon: const Icon(Icons.today),
          onPressed: () {
            controller.selectedDate.value = DateTime.now();
            controller.changeView(controller.currentView
                .value); // Usamos changeView en lugar del método privado
          },
          tooltip: 'Ir a hoy',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.error.value != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: ${controller.error.value}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.changeView(controller
                    .currentView.value), // Usamos changeView para recargar
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      }

      return AppointmentCalendar(controller: controller);
    });
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => AppointmentFormDialog.show(context, controller),
      child: const Icon(Icons.add),
      tooltip: 'Nueva Cita',
    );
  }
}
