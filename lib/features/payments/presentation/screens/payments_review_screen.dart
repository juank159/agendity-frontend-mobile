import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/payments/domain/entities/payment_review_item.dart';
import 'package:login_signup/features/payments/presentation/controllers/payments_review_controller.dart';
import 'package:login_signup/shared/widgets/payment_method_ui.dart';
import 'package:login_signup/features/payments/presentation/widgets/refund_dialog.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';

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
            emptyIcon: Icons.verified_rounded,
            emptyMessage: 'No hay pagos por revisar',
            emptySubMessage: 'Aquí salen los pagos registrados sin conexión '
                'que no cabían al sincronizar.',
            builder: (context, items) => RefreshIndicator(
              onRefresh: controller.refreshFromServer,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
                itemCount: items.length + 1,
                itemBuilder: (context, index) => index == 0
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
                        child: AppNote(
                          'El dinero ya se recibió: no cuenta en lo pagado de '
                          'la cita hasta devolver lo que sobra.',
                          tone: AppTone.info,
                          icon: Icons.info_outline_rounded,
                        ),
                      )
                    : AppFadeIn(
                        index: index - 1,
                        child: _ReviewCard(
                            item: items[index - 1], onRefund: _refund),
                      ),
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
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final warning = tokens.warning;
    final date = item.appointmentDate;
    final method = item.payment.paymentMethod;
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant, height: 1.35);
    return AppCard(
      tint: warning.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppAvatar(name: item.clientName, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (date != null)
                      Text('Cita del ${formatWeekdayDayMonth(date)}',
                          style: muted),
                  ],
                ),
              ),
              StatusChip(
                label: 'En revisión',
                icon: Icons.flag_rounded,
                colors: warning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Figure(
                  label: 'Pago recibido',
                  value: formatCop(item.payment.netAmount),
                  icon: method.icon,
                  detail: method.displayName,
                ),
              ),
              Expanded(
                child: _Figure(
                  label: 'Total de la cita',
                  value: formatCop(item.appointmentTotal),
                  icon: Icons.receipt_long_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppNote(
            PaymentsReviewScreen.reasonOf(item),
            tone: AppTone.warning,
            icon: item.isForCancelledAppointment
                ? Icons.event_busy_rounded
                : Icons.report_problem_rounded,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Obx(() => AppGradientButton(
                  icon: Icons.undo_rounded,
                  label: 'Reembolsar ${formatCop(item.suggestedRefund)}',
                  loading: controller.refundingId.value == item.payment.id,
                  onPressed: controller.refundingId.value == null
                      ? () => onRefund(item)
                      : null,
                )),
          ),
        ],
      ),
    );
  }
}

/// Una cifra de la tarjeta: etiqueta, monto tabular e ícono.
class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? detail;

  const _Figure({
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final extra = detail;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              Text(value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)
                      .tabular),
              if (extra != null)
                Text(extra,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
