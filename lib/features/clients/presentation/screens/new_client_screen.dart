import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import '../controllers/new_client_controller.dart';
import '../widgets/client_form.dart';

/// Alta de un cliente.
class NewClientScreen extends GetView<NewClientController> {
  const NewClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo cliente')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClientForm(controller: controller),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Obx(() => AppGradientButton(
                      label: 'Guardar cliente',
                      icon: Icons.check_rounded,
                      expand: true,
                      loading: controller.isSaving.value,
                      onPressed: controller.isUploadingImage.value
                          ? null
                          : controller.submit,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
