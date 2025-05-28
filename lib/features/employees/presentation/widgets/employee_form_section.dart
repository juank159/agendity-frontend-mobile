import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';

class EmployeeFormSection extends StatelessWidget {
  final EmployeesController controller;
  final bool isEditMode;

  const EmployeeFormSection({
    super.key,
    required this.controller,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // Usar GetBuilder en lugar de Obx para evitar reconstrucciones innecesarias
    return GetBuilder<EmployeesController>(
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'Nombre *',
            hint: 'Ingrese el nombre',
            // Usar el controlador preexistente del EmployeesController
            controller: controller.nameController,
            onChanged: controller.updateName,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Apellido *',
            hint: 'Ingrese el apellido',
            controller: controller.lastnameController,
            onChanged: controller.updateLastname,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email *',
            hint: 'Ingrese el email',
            controller: controller.emailController,
            onChanged: controller.updateEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Teléfono *',
            hint: 'Ingrese el teléfono',
            controller: controller.phoneController,
            onChanged: controller.updatePhone,
            keyboardType: TextInputType.phone,
            // Añadir el formatter para aceptar múltiples dígitos
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: isEditMode
                ? 'Contraseña (dejar en blanco para no cambiar)'
                : 'Contraseña *',
            hint: isEditMode
                ? 'Nueva contraseña (opcional)'
                : 'Ingrese la contraseña',
            controller: controller.passwordController,
            onChanged: controller.updatePassword,
            isPassword: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required Function(String) onChanged,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    List<TextInputFormatter>? inputFormatters,
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
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: isPassword,
          inputFormatters: inputFormatters,
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
