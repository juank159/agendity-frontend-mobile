import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_actions_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_feedback.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_conflict_ui.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_form_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_status_ui.dart';
import 'package:login_signup/features/appointments/presentation/widgets/cancel_appointment_dialog.dart';
import 'package:login_signup/features/payments/presentation/controllers/payment_controller.dart';
import 'package:login_signup/features/payments/presentation/widgets/payment_dialog.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Nota "Agendada en hora de Bogota: 10:00 a. m." si la cita se guardó en
/// otra zona que la actual del negocio (6.03); `null` si no. Las horas del
/// detalle ya están en la zona actual del negocio.
String? recordedZoneNote(AppointmentEntity a) {
  final zone = a.timeZone;
  if (zone == null || !a.isInOtherTimeZone) return null;
  return 'Agendada en hora de ${formatZoneCity(zone)}: '
      '${formatTime(a.recordStartTime)}';
}

/// Detalle de una cita con sus acciones según el estado y el rol:
/// pagar el saldo y editar (Owner), completar y cancelar (los dos; el
/// Employee solo ve sus citas). Lo que cambia se refleja en la agenda.
class AppointmentDetailsDialog extends GetView<AppointmentActionsController> {
  final AppointmentEntity appointment;

  const AppointmentDetailsDialog({super.key, required this.appointment});

  static Future<void> show(AppointmentEntity appointment) =>
      Get.dialog<void>(AppointmentDetailsDialog(appointment: appointment));

  AppointmentsController get _agenda => Get.find<AppointmentsController>();

  // --- Acciones -------------------------------------------------------------

  Future<void> _complete(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirmed = await AppDialogs.confirm(
      title: '¿Completar la cita?',
      message: appointment.isFullyPaid
          ? 'La cita quedará como atendida.'
          : 'La cita aún no está pagada del todo. Quedará como atendida y '
              'podrás registrar el pago después.',
      confirmLabel: 'Completar',
      icon: Icons.task_alt,
    );
    if (!confirmed) return;
    final updated = await controller.complete(appointment);
    if (updated == null) return;
    navigator.pop();
    _agenda.applyChange(updated);
  }

  Future<void> _cancel(BuildContext context) async {
    final navigator = Navigator.of(context);
    final reason = await CancelAppointmentDialog.show(appointment.clientName);
    if (reason == null) return;
    final updated = await controller.cancel(appointment, reason: reason);
    if (updated == null) return;
    navigator.pop();
    _agenda.applyChange(updated);
  }

  Future<void> _edit(BuildContext context) async {
    Navigator.of(context).pop();
    final saved = await AppointmentFormDialog.edit(appointment);
    if (saved != null) _agenda.applyChange(saved);
  }

  Future<void> _pay(BuildContext context) async {
    final navigator = Navigator.of(context);
    final due = await controller.balanceDue(appointment);
    if (due == null) return;
    navigator.pop();
    if (due <= 0) {
      AppSnackbar.info('La cita ya está pagada');
      await _refresh();
      return;
    }
    final methods = await Get.find<PaymentController>().loadCustomMethods();
    final paid = await PaymentDialog.show(appointment,
        balanceDue: due, customMethods: methods);
    if (paid) await _refresh();
  }

  /// Tras un pago la cita cambia (estado de pago y, al primer pago,
  /// confirmada): se lee de nuevo; si no se puede, se recarga la agenda.
  Future<void> _refresh() async {
    final fresh = await controller.fetchLatest(appointment.id);
    fresh == null ? await _agenda.reload() : _agenda.applyChange(fresh);
  }

  // --- Vista ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColors = a.status.colorsOf(context);
    final canPay = AppointmentAccess.canPay() && a.canBePaid;
    final canEdit = AppointmentAccess.canEdit() && !a.isFinal;
    // Solo se completa una cita que ya empezó (7.03, APPOINTMENT_NOT_STARTED).
    final hasStarted = a.canCompleteAt(BusinessTimeZone.now());

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: statusColors.container,
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.clientName,
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: statusColors.onContainer,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 4, children: [
                          AppointmentChip.status(context, a.status),
                          AppointmentChip.payment(context, a.paymentStatus),
                        ]),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: Icon(Icons.close, color: statusColors.onContainer),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoRow(
                      icon: Icons.event_outlined,
                      title: _capitalized(formatLongDate(a.startTime)),
                      subtitle:
                          '${formatTimeRange(a.startTime, a.endTime)} · '
                          '${formatDurationMinutes(a.duration.inMinutes)}',
                    ),
                    if (recordedZoneNote(a) case final note?)
                      Padding(
                        padding: const EdgeInsets.only(left: 40, bottom: 4),
                        child: Text(
                          note,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    FutureBuilder<int>(
                      future: controller.paymentsInReviewOf(a.id),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            key: const Key('detail-review-payments'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Get.toNamed(GetRoutes.paymentsReview);
                            },
                            icon: const Icon(Icons.flag_outlined),
                            label: Text(
                                '${formatCount(count, 'pago en revisión', 'pagos en revisión')}'
                                ': revisar'),
                          ),
                        );
                      },
                    ),
                    if (a.needsReschedule)
                      _Note(
                        '${a.rescheduleReason} Mientras tanto no ocupa la '
                        'hora.${AppointmentAccess.canEdit() ? '' : ' Solo el '
                            'propietario puede moverla.'}',
                        tone: AppTone.warning,
                      ),
                    if (a.isWebBooking)
                      const _InfoRow(
                        icon: Icons.public,
                        title: 'Reserva web',
                        subtitle: 'El cliente la agendó desde el link público '
                            'del negocio.',
                      ),
                    if (!AppointmentAccess.professionalIsFixed())
                      _InfoRow(
                        icon: Icons.person_outline,
                        title: 'Profesional',
                        subtitle: a.professionalName ?? 'Sin nombre',
                      ),
                    const Divider(height: 24),
                    for (var i = 0; i < a.services.length; i++)
                      _ServiceLine(line: a.services[i], color: a.serviceColor(i)),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Total',
                                style: theme.textTheme.titleMedium),
                          ),
                          Text(formatCop(a.totalPrice),
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (a.paymentStatus == AppointmentPaymentStatus.PARTIAL)
                      const _Note(
                        'Tiene un anticipo registrado; al cobrar se propone '
                        'el saldo pendiente.',
                        tone: AppTone.info,
                      ),
                    if (a.notes?.trim().isNotEmpty ?? false) ...[
                      const Divider(height: 24),
                      _InfoRow(
                          icon: Icons.notes, title: 'Notas', subtitle: a.notes!),
                    ],
                    if (a.isCancelled &&
                        (a.cancellationReason?.trim().isNotEmpty ?? false))
                      _InfoRow(
                        icon: Icons.event_busy_outlined,
                        title: 'Motivo de la cancelación',
                        subtitle: a.cancellationReason!,
                      ),
                    if (!a.isFinal && !a.canCancel)
                      const _Note(
                        'Tiene pagos registrados: reembólsalos antes de '
                        'cancelar la cita.',
                        tone: AppTone.warning,
                      ),
                    const SizedBox(height: 16),
                    Obx(() {
                      final busy = controller.isBusy(a.id);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (busy) const LinearProgressIndicator(),
                          if (canPay)
                            FilledButton.icon(
                              onPressed: busy ? null : () => _pay(context),
                              icon: const Icon(Icons.payments_outlined),
                              label: Text(a.paymentStatus ==
                                      AppointmentPaymentStatus.PARTIAL
                                  ? 'Cobrar saldo'
                                  : 'Registrar pago'),
                            ),
                          if (a.canComplete)
                            OutlinedButton.icon(
                              onPressed: busy || !hasStarted
                                  ? null
                                  : () => _complete(context),
                              icon: const Icon(Icons.task_alt),
                              label: Text(hasStarted
                                  ? 'Completar'
                                  : 'Completar (cuando empiece)'),
                            ),
                          if (canEdit)
                            OutlinedButton.icon(
                              onPressed: busy ? null : () => _edit(context),
                              icon: Icon(a.needsReschedule
                                  ? Icons.edit_calendar
                                  : Icons.edit_outlined),
                              label: Text(a.needsReschedule
                                  ? 'Mover a otra hora'
                                  : 'Editar'),
                            ),
                          if (a.canCancel)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                  foregroundColor: scheme.error),
                              onPressed: busy ? null : () => _cancel(context),
                              icon: const Icon(Icons.event_busy_outlined),
                              label: const Text('Cancelar cita'),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _capitalized(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

/// Un servicio con el precio guardado en la cita (2.29).
class _ServiceLine extends StatelessWidget {
  final AppointmentServiceLine line;
  final Color color;

  const _ServiceLine({required this.line, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = line.currentPrice;
    final changed = current != null && (current - line.price).abs() >= 0.01;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 10),
            child: CircleAvatar(radius: 5, backgroundColor: color),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name),
                Text(
                  formatDurationMinutes(line.durationMinutes) +
                      (changed ? ' · hoy cuesta ${formatCop(current)}' : ''),
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(formatCop(line.price)),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  final AppTone tone;

  const _Note(this.text, {required this.tone});

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.tone(tone);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: colors.onContainer)),
    );
  }
}
