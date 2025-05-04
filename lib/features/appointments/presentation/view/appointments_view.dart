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
        // Base del título dependiendo del rol del usuario
        String baseTitle = controller.userRole.value == 'Employee'
            ? 'Mis Citas Asignadas'
            : 'Todas las Citas';

        // Añadir el tipo de vista
        String viewType = '';
        switch (controller.currentView.value) {
          case CalendarView.day:
            viewType = '(Día)';
            break;
          case CalendarView.week:
            viewType = '(Semana)';
            break;
          case CalendarView.month:
            viewType = '(Mes)';
            break;
          default:
            viewType = '';
        }

        return Text('$baseTitle $viewType');
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
            controller.changeView(controller.currentView.value);
          },
          tooltip: 'Ir a hoy',
        ),
        IconButton(
          onPressed: () => Get.toNamed('/notifications'),
          icon: const Icon(Icons.notifications),
          tooltip: 'Notificaciones',
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
                onPressed: () =>
                    controller.changeView(controller.currentView.value),
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
    // Podríamos restringir la creación de citas para empleados si fuera necesario
    return FloatingActionButton(
      onPressed: () => AppointmentFormDialog.show(context, controller),
      child: const Icon(Icons.add),
      tooltip: 'Nueva Cita',
    );
  }
}
