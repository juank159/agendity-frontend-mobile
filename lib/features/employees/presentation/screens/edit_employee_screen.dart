import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/features/employees/presentation/controllers/edit_employee_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/employee_form_controller.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_form_section.dart';

/// Edición de un profesional (ruta `employeeEdit`).
class EditEmployeeScreen extends GetView<EditEmployeeController> {
  const EditEmployeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar profesional')),
      body: Obx(() {
        switch (controller.status.value) {
          case EmployeeLoadStatus.loading:
            return const LoadingState(message: 'Cargando profesional…');
          case EmployeeLoadStatus.error:
            return ErrorState(
              title: 'No se pudo cargar',
              message: controller.loadError.value ?? '',
              onRetry: controller.load,
            );
          case EmployeeLoadStatus.ready:
            return EmployeeFormSection(
              controller: controller,
              isEdit: true,
              submitLabel: 'Guardar cambios',
            );
        }
      }),
    );
  }
}
