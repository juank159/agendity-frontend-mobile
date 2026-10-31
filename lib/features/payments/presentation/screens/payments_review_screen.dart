import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/payments/domain/entities/payment_review_item.dart';
import 'package:login_signup/features/payments/presentation/controllers/payments_review_controller.dart';
import 'package:login_signup/features/payments/presentation/widgets/refund_dialog.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';

/// "Pagos por revisar" (10.03, solo Owner). Un pago registrado sin conexión
/// queda en revisión si al sincronizar la cita ya estaba cancelada o se
/// pagó de más (otro dispositivo cobró). El dinero ya se recibió: no cuenta
/// en lo pagado de la cita hasta devolver lo que sobra.
class PaymentsReviewScreen extends GetView<PaymentsReviewController> {
  const PaymentsReviewScreen({super.key});

  static String reasonOf(PaymentReviewItem item) => item.isForCancelledAppointment
      ? 'La cita ya estaba cancelada cuando se sincronizó el pago. '
          'Devuelve el pago completo.'
      : 'Con este pago la cita queda pagada de más (otro dispositivo también '
          'cobró). Devuelve lo que sobra.';

  Future<void> _refund(PaymentReviewItem item) async {
    final input = await RefundDialog.show(item);
    if (input == null) return;
    await controller.refund(item, amount: input.$1, reason: input.$2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos por revisar')),
      body: Obx(() => ListStateView<PaymentReviewItem>(
            isLoading: controller.isLoading.value,
            error: controller.error.value?.message,
            items: controller.items.toList(),
            onRetry: controller.load,
            emptyIcon: Icons.verified_outlined,
            emptyMessage: 'No hay pagos por revisar',
            emptySubMessage: 'Aquí salen los pagos registrados sin conexión '
                'que no cabían al sincronizar.',
            builder: (context, items) => RefreshIndicator(
              onRefresh: controller.refreshFromServer,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _ReviewCard(item: items[index], onRefund: _refund),
              ),
            ),
          )),
    );
  }
}

class _ReviewCard extends GetView<PaymentsReviewController> {
  final PaymentReviewItem item;
  final ValueChanged<PaymentReviewItem> onRefund;

  const _ReviewCard({required this.item, required this.onRefund});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = context.tokens.warning;
    final date = item.appointmentDate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.clientName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Chip(
                  avatar: Icon(Icons.flag_outlined,
                      size: 16, color: warning.onContainer),
                  label: Text('En revisión',
                      style: TextStyle(color: warning.onContainer)),
                  backgroundColor: warning.container,
                  side: BorderSide.none,
                ),
              ],
            ),
            Text('${formatCop(item.payment.netAmount)} · '
                '${item.payment.paymentMethod.displayName}'
                '${date == null ? '' : ' · cita del ${formatWeekdayDayMonth(date)}'}'
                ' · total de la cita ${formatCop(item.appointmentTotal)}'),
            const SizedBox(height: 4),
            Text(PaymentsReviewScreen.reasonOf(item),
                style: theme.textTheme.bodySmall),
            Align(
              alignment: Alignment.centerRight,
              child: Obx(() => FilledButton.icon(
                    onPressed: controller.refundingId.value == null
                        ? () => onRefund(item)
                        : null,
                    icon: const Icon(Icons.undo),
                    label: Text(
                        'Reembolsar ${formatCop(item.suggestedRefund)}'),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
