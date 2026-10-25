import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/payments/presentation/controllers/payment_controller.dart';

/// Diálogo "Registrar pago". No registra su controller: lo hace
/// `AppointmentsBinding`. Usar [PaymentDialog.show], que prepara el
/// formulario; devuelve `true` si se registró el pago.
class PaymentDialog extends GetView<PaymentController> {
  final AppointmentEntity appointment;

  /// Métodos propios del negocio. Sin ellos no se ofrece "Otro método".
  final List<CustomPaymentMethodOption> customMethods;

  const PaymentDialog({
    super.key,
    required this.appointment,
    this.customMethods = const [],
  });

  /// Usa el navigator de GetX: quien lo llama suele cerrar antes su propio
  /// diálogo, y su `context` ya no sirve para abrir otro.
  static Future<bool> show(
    AppointmentEntity appointment, {
    List<CustomPaymentMethodOption> customMethods = const [],
  }) async {
    Get.find<PaymentController>().start(appointment);
    final result = await Get.dialog<bool>(
      PaymentDialog(appointment: appointment, customMethods: customMethods),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final methods = PaymentMethod.values
        .where((m) => m != PaymentMethod.CUSTOM || customMethods.isNotEmpty);

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Registrar pago',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _TotalBox(total: controller.total),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('payment-amount'),
                  controller: controller.amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto recibido',
                    prefixText: '\$ ',
                    helperText: 'Puede ser un anticipo; no más del total.',
                    errorText: controller.amountError.value,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Método de pago',
                    style: Theme.of(context).textTheme.titleSmall),
                RadioGroup<PaymentMethod>(
                  groupValue: controller.method.value,
                  onChanged: (value) {
                    if (value != null) controller.selectMethod(value);
                  },
                  child: Column(
                    children: [
                      for (final m in methods)
                        RadioListTile<PaymentMethod>(
                          title: Text(m.displayName),
                          value: m,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
                if (controller.method.value == PaymentMethod.CUSTOM)
                  DropdownButtonFormField<String>(
                    key: const Key('payment-custom-method'),
                    initialValue: controller.customMethodId.value,
                    decoration: InputDecoration(
                      labelText: 'Método propio',
                      errorText: controller.methodError.value,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final option in customMethods)
                        DropdownMenuItem(
                            value: option.id, child: Text(option.name)),
                    ],
                    onChanged: controller.selectCustomMethod,
                  ),
                if (controller.needsTransactionId) ...[
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('payment-transaction'),
                    controller: controller.transactionController,
                    decoration: const InputDecoration(
                      labelText: 'ID de transacción (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : () async {
                              final navigator = Navigator.of(context);
                              if (await controller.submit()) {
                                navigator.pop(true);
                              }
                            },
                      icon: controller.isSaving.value
                          ? SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: scheme.onPrimary),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Confirmar pago'),
                    ),
                  ],
                ),
              ],
            )),
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  final double total;

  const _TotalBox({required this.total});

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.success;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total de la cita',
              style: TextStyle(
                  color: colors.onContainer, fontWeight: FontWeight.w500)),
          Text(
            formatCop(total),
            style: TextStyle(
              color: colors.onContainer,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
