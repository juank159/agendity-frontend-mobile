import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/presentation/controllers/new_service_controller.dart';
import 'package:login_signup/features/services/presentation/widgets/service_form.dart';

/// Alta de un servicio (solo Owner).
class NewServiceScreen extends GetView<NewServiceController> {
  const NewServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo servicio')),
      body: ServiceForm(controller: controller),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() => FilledButton.icon(
                onPressed: controller.isSaving.value ? null : controller.save,
                icon: controller.isSaving.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Guardar'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
              )),
        ),
      ),
    );
  }
}
