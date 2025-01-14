import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/constants/app_colors.dart';

import 'package:login_signup/features/services/presentation/controller/new_service_controller.dart';

class NewServiceScreen extends GetView<NewServiceController> {
  const NewServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Crear servicio',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tabs
          _buildTabs(),
          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfo(),
                  const SizedBox(height: 24),
                  _buildAdditionalSettings(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: controller.saveService,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Guardar',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100], // Color de fondo gris muy claro
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: Obx(() => _TabButton(
                    text: 'Información',
                    isSelected: controller.selectedTab.value == 0,
                    onTap: () => controller.selectTab(0),
                  )),
            ),
            Expanded(
              child: Obx(() => _TabButton(
                    text: 'Miembros del equipo',
                    isSelected: controller.selectedTab.value == 1,
                    onTap: () => controller.selectTab(1),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Info Básica',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Nombre del servicio
        TextField(
          controller: controller.nameController,
          decoration: _inputDecoration('Nombre del servicio'),
        ),
        const SizedBox(height: 16),

        // Precio
        TextField(
          controller: controller.priceController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Precio'),
        ),
        const SizedBox(height: 16),

        // Tipo de precio
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de precio',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _selectableField(
              Obx(() => Text(controller.selectedPriceType.value)),
              'Seleccionar',
              controller.selectPriceType,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tiempo del servicio
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tiempo del servicio',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _selectableField(
              Obx(() => Text('${controller.duration.value.inMinutes} Minutos')),
              'Seleccionar',
              controller.showDurationPicker,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Categoria del Servicio

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categoría de servicio',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _selectableField(
              Obx(() => Text(
                    controller.selectedCategory.value?.name ??
                        'Seleccionar categoría',
                    style: TextStyle(
                      color: controller.selectedCategory.value == null
                          ? Colors.grey
                          : Colors.black,
                    ),
                  )),
              'Seleccionar',
              controller.selectCategory,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Descripción
        TextField(
          controller: controller.descriptionController,
          maxLines: 2,
          decoration: _inputDecoration('Descripción del servicio (Opcional)'),
        ),
      ],
    );
  }

  Widget _buildAdditionalSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reserva online
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Se puede reservar online'),
          trailing: Obx(() => Switch(
                value: controller.isOnlineBooking.value,
                onChanged: (value) => controller.isOnlineBooking.value = value,
              )),
        ),

        // Configuración adicional expansible
        ExpansionTile(
          title: const Text(
            'Configuración adicional',
            style: TextStyle(
              color: Colors.deepPurple,
            ),
          ),
          tilePadding: EdgeInsets.zero, // Esto elimina el padding por defecto
          childrenPadding:
              EdgeInsets.zero, // Esto elimina el padding de los children
          children: [
            // Imagen del servicio
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Imagen del servicio',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                DottedBorder(
                  color: Colors.grey.shade400,
                  strokeWidth: 3,
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  dashPattern: const [5, 5],
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Text(
                            'Añade una imagen del servicio',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Color en la agenda
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Color en la agenda'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: controller.availableColors
                        .map(
                          (color) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  controller.selectedColor.value = color,
                              child: Obx(() => Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: controller.selectedColor.value ==
                                              color
                                          ? Border.all(
                                              color: Colors.black, width: 2)
                                          : null,
                                    ),
                                  )),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Abono mínimo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seleccionar porcentaje de abono'),
                Row(
                  children: [
                    // IconButton(
                    //   icon: const Icon(Icons.percent),
                    //   onPressed: () => controller.setDepositType('percentage'),
                    // ),
                    Obx(() => Text(
                        controller.depositType.value == 'percentage'
                            ? '${controller.minimumDeposit.value.round()}%'
                            : '\$${controller.minimumDeposit.value.round()}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ))),

                    IconButton(
                      icon: const Icon(Icons.attach_money),
                      onPressed: () => controller.setDepositType('fixed'),
                    ),
                  ],
                ),
              ],
            ),
            Obx(() => Slider(
                  value: controller.minimumDeposit.value,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: controller.depositType.value == 'percentage'
                      ? '${controller.minimumDeposit.value.round()}%'
                      : '\$${controller.minimumDeposit.value.round()}',
                  onChanged: (value) => controller.minimumDeposit.value = value,
                )),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      labelText: hint,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple),
      ),
    );
  }

  Widget _selectableField(Widget child, String action, VoidCallback? onTap,
      {bool showInfo = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: child),
            Text(
              action,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showInfo) ...[
              const SizedBox(width: 8),
              const Icon(Icons.info_outline, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
