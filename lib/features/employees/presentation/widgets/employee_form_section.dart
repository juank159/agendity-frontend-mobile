import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';

class EmployeeFormSection extends StatelessWidget {
  final EmployeesController controller;

  const EmployeeFormSection({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'Nombre *',
              hint: 'Ingrese el nombre',
              value: controller.name.value,
              onChanged: controller.updateName,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Apellido *',
              hint: 'Ingrese el apellido',
              value: controller.lastname.value,
              onChanged: controller.updateLastname,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Email *',
              hint: 'Ingrese el email',
              value: controller.email.value,
              onChanged: controller.updateEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Teléfono *',
              hint: 'Ingrese el teléfono',
              value: controller.phone.value,
              onChanged: controller.updatePhone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Contraseña *',
              hint: 'Ingrese la contraseña',
              value: controller.password.value,
              onChanged: controller.updatePassword,
              isPassword: true,
            ),
          ],
        ));
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String value,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }
}
