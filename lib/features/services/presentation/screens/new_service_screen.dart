import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Obx(() => AppGradientButton(
                label: 'Guardar',
                icon: Icons.check_rounded,
                expand: true,
                loading: controller.isSaving.value,
                onPressed: controller.save,
              )),
        ),
      ),
    );
  }
}
