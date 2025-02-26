import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/payments/domain/usecases/create_payment_usecase.dart';
import 'package:login_signup/features/payments/presentation/controllers/payment_controller.dart';

class PaymentDialog extends StatelessWidget {
  final AppointmentEntity appointment;

  const PaymentDialog({
    Key? key,
    required this.appointment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Inicializar el controlador solo si no está registrado
    if (!Get.isRegistered<PaymentController>()) {
      Get.put(PaymentController(
        createPaymentUseCase: Get.find<CreatePaymentUseCase>(),
      ));
    }

    final controller = Get.find<PaymentController>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registrar pago',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Detalles del monto
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monto a pagar:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '\$${appointment.totalPrice}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Método de pago',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Lista de métodos de pago
            Obx(() => Column(
                  children: [
                    ...PaymentMethod.values.map((method) {
                      if (method == PaymentMethod.CUSTOM)
                        return const SizedBox.shrink();

                      return RadioListTile<PaymentMethod>(
                        title: Text(method.displayName),
                        value: method,
                        groupValue: controller.selectedPaymentMethod.value,
                        onChanged: (value) {
                          if (value != null) {
                            controller.setPaymentMethod(value);
                          }
                        },
                        dense: true,
                        activeColor: Theme.of(context).primaryColor,
                      );
                    }).toList(),
                  ],
                )),

            // Campo para ID de transacción (visible solo para algunos métodos)
            Obx(() {
              final needsTransactionId =
                  controller.selectedPaymentMethod.value ==
                          PaymentMethod.TRANSFER ||
                      controller.selectedPaymentMethod.value ==
                          PaymentMethod.ONLINE;

              if (!needsTransactionId) return const SizedBox.shrink();

              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'ID de transacción',
                    hintText: 'Ingrese el ID o referencia',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: controller.setTransactionId,
                ),
              );
            }),

            const SizedBox(height: 24),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                Obx(() => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () async {
                              final success =
                                  await controller.createPayment(appointment);
                              if (success) {
                                Get.back(result: true);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Confirmar pago'),
                    )),
              ],
            ),

            // Mensaje de error
            Obx(() {
              if (controller.error.value.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  controller.error.value,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
