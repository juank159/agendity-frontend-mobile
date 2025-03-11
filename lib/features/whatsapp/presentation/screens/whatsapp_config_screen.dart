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
                  'Configuración de notificaciones para WhatsApp',
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

                // Si no hay configuración o estamos editando, mostrar la guía
                if (!controller.hasExistingConfig.value ||
                    controller.isEditing.value) ...[
                  const WhatsappSetupGuide(),
                  const SizedBox(height: 24),
                ],

                // Mostrar el estado actual o el formulario
                controller.hasExistingConfig.value &&
                        !controller.isEditing.value
                    ? _buildConfigInfo(context)
                    : _buildConfigForm(context),

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

  // Widget para mostrar la información de configuración existente
  Widget _buildConfigInfo(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración Actual',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.phone,
              label: 'Número de WhatsApp:',
              value: '+57 ${controller.phoneNumber.value}',
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.key,
              label: 'API Key:',
              value: controller.apiKey.value,
              obscureText: true,
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.notifications,
              label: 'Estado:',
              value:
                  controller.isEnabled.value ? 'Habilitado' : 'Deshabilitado',
              valueColor:
                  controller.isEnabled.value ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para mostrar filas de información
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool obscureText = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  obscureText ? '••••••' : value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Formulario de configuración
  Widget _buildConfigForm(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: controller.phoneNumber.value,
            decoration: const InputDecoration(
              labelText: 'Número de WhatsApp (sin código de país)',
              hintText: 'Ejemplo: 3138448436',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
              prefixText: '+57 ',
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          if (controller.hasExistingConfig.value &&
              !controller.isEditing.value) ...[
            // Botones para configuración existente
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed: controller.enableEditing,
                    text: 'Editar configuración',
                    icon: Icons.edit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    onPressed: controller.sendTestMessage,
                    text: 'Enviar prueba',
                    icon: Icons.send,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () {
                  controller.isEnabled.value = !controller.isEnabled.value;
                  controller.saveConfig();
                },
                text: controller.isEnabled.value
                    ? 'Deshabilitar WhatsApp'
                    : 'Habilitar WhatsApp',
                icon: controller.isEnabled.value
                    ? Icons.notifications_off
                    : Icons.notifications_active,
                color:
                    controller.isEnabled.value ? Colors.orange : Colors.green,
              ),
            ),
          ] else ...[
            // Botones para nueva configuración o edición
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed: controller.saveConfig,
                    text: 'Guardar configuración',
                    icon: Icons.save,
                  ),
                ),
                if (controller.isEditing.value) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      onPressed: controller.cancelEditing,
                      text: 'Cancelar',
                      icon: Icons.cancel,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
