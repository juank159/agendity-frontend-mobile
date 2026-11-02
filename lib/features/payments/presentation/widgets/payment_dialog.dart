import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/payments/domain/entities/custom_payment_method.dart';
import 'package:login_signup/features/payments/presentation/controllers/payment_controller.dart';
import 'package:login_signup/shared/widgets/payment_method_ui.dart';
import 'package:login_signup/shared/widgets/app_dialog_title.dart';
import 'package:login_signup/shared/widgets/money_field.dart';

/// Diálogo "Registrar pago". No registra su controller: lo hace
/// `AppointmentsBinding`. Usar [PaymentDialog.show], que prepara el
/// formulario; devuelve `true` si se registró el pago.
class PaymentDialog extends GetView<PaymentController> {
  final AppointmentEntity appointment;

  /// Métodos propios del negocio. Sin ellos no se ofrece "Otro método".
  final List<CustomPaymentMethod> customMethods;

  const PaymentDialog({
    super.key,
    required this.appointment,
    this.customMethods = const [],
  });

  /// Usa el navigator de GetX: quien lo llama suele cerrar antes su propio
  /// diálogo, y su `context` ya no sirve para abrir otro. [balanceDue] = lo
  /// que falta por pagar (con anticipos); sin él, el total.
  static Future<bool> show(
    AppointmentEntity appointment, {
    double? balanceDue,
    List<CustomPaymentMethod> customMethods = const [],
  }) async {
    Get.find<PaymentController>().start(appointment, balanceDue: balanceDue);
    final result = await Get.dialog<bool>(
      PaymentDialog(appointment: appointment, customMethods: customMethods),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final methods = PaymentMethod.values
        .where((m) => m != PaymentMethod.CUSTOM || customMethods.isNotEmpty);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDialogTitle(
                    icon: Icons.payments_rounded,
                    title: 'Registrar pago',
                    subtitle: appointment.clientName,
                  ),
                  const SizedBox(height: 18),
                  _TotalBox(
                    total: controller.total,
                    balanceDue: controller.hasPreviousPayments
                        ? controller.balanceDue
                        : null,
                  ),
                  const SizedBox(height: 18),
                  MoneyField(
                    key: const Key('payment-amount'),
                    controller: controller.amountController,
                    label: 'Monto recibido',
                    helperText: 'Puede ser un anticipo; no más del saldo.',
                    errorText: controller.amountError.value,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 18),
                  Text('Método de pago',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in methods)
                        _MethodChip(
                          method: m,
                          selected: controller.method.value == m,
                          onSelected: () => controller.selectMethod(m),
                        ),
                    ],
                  ),
                  if (controller.method.value == PaymentMethod.CUSTOM) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: const Key('payment-custom-method'),
                      initialValue: controller.customMethodId.value,
                      decoration: InputDecoration(
                        labelText: 'Método propio',
                        prefixIcon: Icon(PaymentMethod.CUSTOM.icon),
                        errorText: controller.methodError.value,
                      ),
                      items: [
                        for (final option in customMethods)
                          DropdownMenuItem(
                              value: option.id, child: Text(option.name)),
                      ],
                      onChanged: controller.selectCustomMethod,
                    ),
                  ],
                  if (controller.needsTransactionId) ...[
                    const SizedBox(height: 14),
                    TextField(
                      key: const Key('payment-transaction'),
                      controller: controller.transactionController,
                      decoration: const InputDecoration(
                        labelText: 'ID de transacción (opcional)',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      TextButton(
                        onPressed: controller.isSaving.value
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppGradientButton(
                          label: 'Confirmar pago',
                          icon: Icons.check_rounded,
                          expand: true,
                          loading: controller.isSaving.value,
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            if (await controller.submit()) {
                              navigator.pop(true);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              )),
        ),
      ),
    );
  }
}

/// Método de pago como chip con su ícono (sin la marca de Material: el ícono
/// queda siempre visible y el elegido se resalta con el contenedor primario).
class _MethodChip extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onSelected;

  const _MethodChip({
    required this.method,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(method.icon,
          size: 18,
          color: selected ? scheme.onPrimaryContainer : scheme.primary),
      label: Text(method.displayName),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

/// Total de la cita y, si ya hay pagos, el saldo pendiente: tarjeta con el
/// degradado de la paleta y cifras tabulares.
class _TotalBox extends StatelessWidget {
  final double total;

  /// Saldo pendiente si ya hay pagos (anticipos); `null` si no.
  final double? balanceDue;

  const _TotalBox({required this.total, this.balanceDue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final on = tokens.onGradient;
    final due = balanceDue;
    final label = theme.textTheme.bodyMedium
        ?.copyWith(color: on.withValues(alpha: 0.9), fontWeight: FontWeight.w600);
    final big = theme.textTheme.headlineSmall
        ?.copyWith(color: on, fontWeight: FontWeight.w800)
        .tabular;
    final small = theme.textTheme.titleSmall
        ?.copyWith(color: on, fontWeight: FontWeight.w700)
        .tabular;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: tokens.primaryGradient,
        borderRadius: AppRadii.fieldRadius,
        border: Border.all(color: tokens.innerBorder),
        boxShadow: tokens.elevation2(tint: tokens.gradientEnd),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: AppRadii.fieldRadius,
        gradient: tokens.sheenGradient,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Total de la cita', style: label)),
              Text(formatCop(total), style: due == null ? big : small),
            ],
          ),
          if (due != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Saldo pendiente', style: label)),
                Text(formatCop(due), style: big),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
