import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/employees/presentation/controllers/new_employee_controller.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_form_section.dart';

/// Alta de un profesional. Al crearlo se abre la verificación de su email
/// (nace pendiente de verificación).
class CreateEmployeeScreen extends GetView<NewEmployeeController> {
  const CreateEmployeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo profesional')),
      body: EmployeeFormSection(
        controller: controller,
        submitLabel: 'Crear profesional',
      ),
    );
  }
}
