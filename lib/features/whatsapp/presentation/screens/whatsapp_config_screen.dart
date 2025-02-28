// lib/features/whatsapp/presentation/screens/whatsapp_config_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/whatsapp_controller.dart';
import '../widgets/whatsapp_setup_guide.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_overlay.dart';

class WhatsappConfigScreen extends GetView<WhatsappController> {
  const WhatsappConfigScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de WhatsApp'),
        elevation: 0,
      ),
      body: Obx(() {
        return LoadingOverlay(
          isLoading: controller.isLoading.value,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuración de CallMeBot para WhatsApp',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configure su integración con WhatsApp para enviar recordatorios a sus clientes.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Guía de configuración
                const WhatsappSetupGuide(),
                const SizedBox(height: 24),

                // Formulario de configuración
                _buildConfigForm(context),
                const SizedBox(height: 24),

                // Mensajes de error o éxito
                _buildMessages(),
                const SizedBox(height: 16),

                // Botones de acción
                _buildActionButtons(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildConfigForm(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: controller.phoneNumber.value,
            decoration: const InputDecoration(
              labelText: 'Número de WhatsApp con código de país',
              hintText: 'Ejemplo: 573138448436',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) => controller.phoneNumber.value = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: controller.apiKey.value,
            decoration: const InputDecoration(
              labelText: 'API Key de CallMeBot',
              hintText: 'Ejemplo: 6188231',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key),
            ),
            onChanged: (value) => controller.apiKey.value = value,
          ),
          const SizedBox(height: 16),
          Obx(() => SwitchListTile(
                title: const Text('Habilitar notificaciones por WhatsApp'),
                subtitle: const Text(
                    'Enviar recordatorios automáticos a los clientes'),
                value: controller.isEnabled.value,
                onChanged: (value) => controller.isEnabled.value = value,
                secondary: const Icon(Icons.notifications),
              )),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return Obx(() {
      if (controller.errorMessage.value != null &&
          controller.errorMessage.value!.isNotEmpty) {
        String displayMessage = controller.errorMessage.value!;
        if (displayMessage.contains('not found for owner')) {
          displayMessage =
              'Debes guardar la configuración antes de enviar un mensaje de prueba';
        }
        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.red.shade50,
          width: double.infinity,
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.errorMessage.value!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      } else if (controller.successMessage.value != null &&
          controller.successMessage.value!.isNotEmpty) {
        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.green.shade50,
          width: double.infinity,
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.successMessage.value!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  // Widget _buildActionButtons() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8.0),
  //     child: Column(
  //       // Cambiado de Row a Column para pantallas pequeñas
  //       children: [
  //         SizedBox(
  //           width: double.infinity,
  //           child: CustomButton(
  //             onPressed: controller.saveConfig,
  //             text: 'Guardar configuración',
  //             icon: Icons.save,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         SizedBox(
  //           width: double.infinity,
  //           child: CustomButton(
  //             onPressed: controller.sendTestMessage,
  //             text: 'Enviar mensaje de prueba',
  //             icon: Icons.send,
  //             color: Colors.green,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              onPressed: controller.saveConfig,
              text: 'Guardar configuración',
              icon: Icons.save,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            // Verificar si los campos necesarios están llenos
            bool canTest = controller.phoneNumber.value.isNotEmpty &&
                controller.apiKey.value.isNotEmpty;

            return SizedBox(
              width: double.infinity,
              child: CustomButton(
                // Proporcionamos una función que no hace nada cuando está deshabilitado
                onPressed: canTest
                    ? () {
                        controller.sendTestMessage();
                      }
                    : () {/* No hacer nada */},
                text: 'Enviar mensaje de prueba',
                icon: Icons.send,
                color: canTest
                    ? Colors.green
                    : Colors.grey, // Cambiar color si está deshabilitado
              ),
            );
          }),
        ],
      ),
    );
  }
}
