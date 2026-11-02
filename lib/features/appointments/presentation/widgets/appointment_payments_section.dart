import 'package:flutter/material.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/features/payments/domain/entities/appointment_balance.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/shared/widgets/payment_method_ui.dart';
import 'package:login_signup/shared/widgets/app_pill.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';

/// Pagos de la cita (Owner): barra de lo pagado sobre el total, lo pagado
/// y el saldo, y el historial (método, fecha y hora en 12 h, monto, lo
/// devuelto y si está en revisión).
class AppointmentPaymentsSection extends StatelessWidget {
  final AppointmentBalance balance;

  const AppointmentPaymentsSection({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final payments = balance.payments;
    final done = balance.isFullyPaid;
    final barColor = done ? tokens.success.color : scheme.primary;
    return Column(
      key: const Key('detail-payments'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          icon: Icons.payments_rounded,
          title: 'Pagos',
          subtitle: payments.isEmpty
              ? 'Aún no hay pagos'
              : formatCount(payments.length, 'pago', 'pagos'),
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 10),
        ),
        Semantics(
          label: 'Pagado ${formatPercent(balance.paidFraction * 100)} '
              'del total',
          child: ClipRRect(
            borderRadius: AppRadii.chipRadius,
            child: LinearProgressIndicator(
              key: const Key('detail-payment-progress'),
              value: balance.paidFraction,
              minHeight: 10,
              color: barColor,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Figure(
                  label: 'Pagado',
                  value: formatCop(balance.paid),
                  color: tokens.success.color),
            ),
            Expanded(
              child: _Figure(
                label: 'Saldo',
                value: formatCop(balance.outstanding),
                color: done ? scheme.onSurfaceVariant : tokens.warning.color,
                end: true,
              ),
            ),
          ],
        ),
        for (final payment in payments) _PaymentRow(payment: payment),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool end;

  const _Figure({
    required this.label,
    required this.value,
    required this.color,
    this.end = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment:
          end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w800)
                .tabular),
      ],
    );
  }
}

/// Un pago del historial.
class _PaymentRow extends StatelessWidget {
  final PaymentEntity payment;

  const _PaymentRow({required this.payment});

  /// Estado del pago si no es el normal (`COMPLETED`).
  static String? statusLabel(PaymentStatus status) => switch (status) {
        PaymentStatus.COMPLETED => null,
        PaymentStatus.PENDING => 'Pendiente',
        PaymentStatus.FAILED => 'Fallido',
        PaymentStatus.REFUNDED => 'Reembolsado',
        PaymentStatus.CANCELLED => 'Anulado',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final method = payment.paymentMethod;
    final when = payment.createdAt;
    final status = statusLabel(payment.status);
    final refunded = payment.refundAmount > 0;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadii.fieldRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(method.icon, size: 18, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    method == PaymentMethod.CUSTOM
                        ? 'Método propio'
                        : method.displayName,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (when != null)
                  Text('${formatShortDate(when)} · ${formatTime(when)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)
                          .tabular),
                if (refunded || status != null || payment.needsReview)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(spacing: 6, runSpacing: 4, children: [
                      if (payment.needsReview)
                        StatusChip(
                          label: 'En revisión',
                          icon: Icons.flag_rounded,
                          colors: tokens.warning,
                          dense: true,
                        ),
                      if (status != null)
                        AppPill(label: status, dense: true),
                      if (refunded)
                        AppPill(
                          label: 'Devuelto ${formatCop(payment.refundAmount)}',
                          icon: Icons.undo_rounded,
                          colors: tokens.info,
                          dense: true,
                          tabular: true,
                        ),
                    ]),
                  ),
              ],
            ),
          ),
          Text(formatCop(payment.amount),
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700)
                  .tabular),
        ],
      ),
    );
  }
}

/// Esqueleto de la sección de pagos mientras se leen.
class AppointmentPaymentsSkeleton extends StatelessWidget {
  const AppointmentPaymentsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 16),
      child: SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(width: 120, height: 16),
            SizedBox(height: 10),
            SkeletonBox(height: 10),
            SizedBox(height: 10),
            SkeletonBox(height: 40),
          ],
        ),
      ),
    );
  }
}
