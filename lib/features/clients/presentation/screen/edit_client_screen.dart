import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/presentation/controller/edit_client_controller.dart';
import 'package:login_signup/features/clients/presentation/widgets/client_image_picker.dart';

// edit_client_screen.dart
class EditClientScreen extends GetView<EditClientController> {
  const EditClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        title: const Text('Editar cliente'),
        actions: [
          TextButton(
            onPressed: () => controller.updateClient(),
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Foto
              const ClientImagePicker(),
              const SizedBox(height: 24),

              // Campos
              TextField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: controller.phoneController,
                decoration: const InputDecoration(
                  labelText: 'Número de teléfono móvil',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: controller.emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: controller.notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas del cliente',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Switch para mostrar notas
              Row(
                children: [
                  Obx(() => Switch(
                        value: controller.showNotes.value,
                        onChanged: (value) =>
                            controller.showNotes.value = value,
                      )),
                  const Text('Mostrar notas del cliente en cada cita'),
                ],
              ),
              const SizedBox(height: 16),

              // Campo de cumpleaños
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    controller.birthdayController.text =
                        "${picked.day}/${picked.month}/${picked.year}";
                  }
                },
                child: IgnorePointer(
                  child: TextField(
                    controller: controller.birthdayController,
                    decoration: const InputDecoration(
                      labelText: 'Cumpleaños',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón eliminar
              TextButton(
                onPressed: () => controller.showDeleteConfirmation(),
                child: const Text(
                  'Eliminar cliente',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
