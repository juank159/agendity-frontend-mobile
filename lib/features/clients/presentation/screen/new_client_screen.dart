import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/new_client_controller.dart';
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClientForm(controller: controller),
              const SizedBox(height: 16),
              Obx(() => FilledButton.icon(
                    onPressed: controller.isSaving.value ||
                            controller.isUploadingImage.value
                        ? null
                        : controller.submit,
                    icon: controller.isSaving.value
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('Guardar cliente'),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
