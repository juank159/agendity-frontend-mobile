// lib/features/clients/presentation/screens/edit_client_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/presentation/controller/edit_client_controller.dart';
import 'package:login_signup/features/clients/presentation/widgets/client_image_picker.dart';

class EditClientScreen extends GetView<EditClientController> {
  const EditClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Editar Cliente',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Obx(() => controller.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Colors.white,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextButton.icon(
                    onPressed: () => controller.updateClient(),
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      'Guardar',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: Colors.blue.shade700),
          );
        }

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade800,
                  Colors.blue.shade200,
                  Colors.blue.shade50,
                ],
                stops: const [0.0, 0.1, 0.3],
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen del cliente
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 20),
                    child: const ClientImagePicker(),
                  ),

                  // Contenido principal
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        // Información básica
                        _buildSectionHeader(
                          'Información Básica',
                          Icons.person,
                          theme,
                        ),
                        const SizedBox(height: 16),

                        // Nombre
                        _buildTextField(
                          controller: controller.nameController,
                          icon: Icons.person_outline,
                          label: 'Nombre',
                          hint: 'Ingrese el nombre',
                          required: true,
                        ),
                        const SizedBox(height: 16),

                        // Teléfono
                        _buildTextField(
                          controller: controller.phoneController,
                          icon: Icons.phone_android,
                          label: 'Teléfono móvil',
                          hint: 'Ingrese el número de teléfono',
                          keyboardType: TextInputType.phone,
                          required: true,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        _buildTextField(
                          controller: controller.emailController,
                          icon: Icons.email_outlined,
                          label: 'Email',
                          hint: 'Ingrese el correo electrónico',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 30),

                        // Información adicional
                        _buildSectionHeader(
                          'Información Adicional',
                          Icons.assignment_outlined,
                          theme,
                        ),
                        const SizedBox(height: 16),

                        // Notas
                        _buildTextField(
                          controller: controller.notesController,
                          icon: Icons.note_outlined,
                          label: 'Notas del cliente',
                          hint: 'Ingrese notas o información adicional',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // Switch para mostrar notas
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.visibility,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'Mostrar notas en cada cita',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Obx(() => Switch(
                                      value: controller.showNotes.value,
                                      onChanged: (value) =>
                                          controller.showNotes.value = value,
                                      activeColor: Colors.blue,
                                    )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Cumpleaños
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Colors.blue,
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              controller.birthdayController.text =
                                  "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                            }
                          },
                          child: IgnorePointer(
                            child: _buildTextField(
                              controller: controller.birthdayController,
                              icon: Icons.cake_outlined,
                              label: 'Cumpleaños',
                              hint: 'DD/MM/AAAA',
                              suffixIcon: Icons.calendar_today,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Botones de acción
                        Row(
                          children: [
                            // Botón eliminar
                            Expanded(
                              flex: 1,
                              child: Container(
                                height: 55,
                                margin:
                                    const EdgeInsets.only(bottom: 30, right: 8),
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      controller.showDeleteConfirmation(),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text(
                                    'ELIMINAR',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    elevation: 3,
                                    shadowColor: Colors.red.shade200,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Botón guardar
                            Expanded(
                              flex: 1,
                              child: Container(
                                height: 55,
                                margin:
                                    const EdgeInsets.only(bottom: 30, left: 8),
                                child: ElevatedButton.icon(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () => controller.updateClient(),
                                  icon: const Icon(Icons.save),
                                  label: const Text(
                                    'GUARDAR',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shadowColor: Colors.blue.shade200,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.blue.shade700,
          size: 28,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    IconData? suffixIcon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blue),
            prefixText: prefixText,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: Colors.blue)
                : null,
            labelText: required ? "$label *" : label,
            hintText: hint,
            border: InputBorder.none,
            labelStyle: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }
}
