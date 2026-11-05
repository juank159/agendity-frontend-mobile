import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_actions_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_feedback.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_conflict_ui.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_detail_header.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_form_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_payments_section.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_status_ui.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_tile.dart';
import 'package:login_signup/features/appointments/presentation/widgets/cancel_appointment_dialog.dart';
import 'package:login_signup/features/payments/domain/entities/appointment_balance.dart';
import 'package:login_signup/features/payments/presentation/controllers/payment_controller.dart';
import 'package:login_signup/features/payments/presentation/widgets/payment_dialog.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'package:login_signup/shared/widgets/whatsapp_icon.dart';

/// Nota "Agendada en hora de Bogota: 10:00 a. m." si la cita se guardó en
/// otra zona que la actual del negocio (6.03); `null` si no. Las horas del
/// detalle ya están en la zona actual del negocio.
String? recordedZoneNote(AppointmentEntity a) {
  final zone = a.timeZone;
  if (zone == null || !a.isInOtherTimeZone) return null;
  return 'Agendada en hora de ${formatZoneCity(zone)}: '
      '${formatTime(a.recordStartTime)}';
}

/// Detalle de una cita (12.07): cabecera 3D con el color del primer servicio
/// (cliente con su avatar, día, hora en 12 h y estados), servicios en
/// píldoras con su precio, la sección de pagos del Owner (lo pagado, el
/// saldo con su barra y el historial) y las acciones según el estado y el
/// rol: cobrar y editar o mover (Owner), completar, recordatorio por
/// WhatsApp y cancelar (los dos; el Employee solo ve sus citas). Lo que
/// cambia se refleja en la agenda.
class AppointmentDetailsDialog extends StatefulWidget {
  final AppointmentEntity appointment;

  const AppointmentDetailsDialog({super.key, required this.appointment});

  static Future<void> show(AppointmentEntity appointment) =>
      Get.dialog<void>(AppointmentDetailsDialog(appointment: appointment));

  @override
  State<AppointmentDetailsDialog> createState() =>
      _AppointmentDetailsDialogState();
}

class _AppointmentDetailsDialogState extends State<AppointmentDetailsDialog> {
  AppointmentActionsController get controller =>
      Get.find<AppointmentActionsController>();

  AppointmentsController get _agenda => Get.find<AppointmentsController>();

  AppointmentEntity get a => widget.appointment;

  late final Future<int> _inReview = controller.paymentsInReviewOf(a.id);
  late final Future<AppointmentBalance?> _payments =
      controller.paymentSummaryOf(a);

  /// El recordatorio se acaba de enviar desde aquí.
  bool _reminderSent = false;

  // --- Acciones -------------------------------------------------------------

  Future<void> _complete() async {
    final navigator = Navigator.of(context);
    final confirmed = await AppDialogs.confirm(
      title: '¿Completar la cita?',
      message: a.isFullyPaid
          ? 'La cita quedará como atendida.'
          : 'La cita aún no está pagada del todo. Quedará como atendida y '
              'podrás registrar el pago después.',
      confirmLabel: 'Completar',
      icon: Icons.task_alt_rounded,
    );
    if (!confirmed) return;
    final updated = await controller.complete(a);
    if (updated == null) return;
    navigator.pop();
    _agenda.applyChange(updated);
  }

  Future<void> _cancel() async {
    final navigator = Navigator.of(context);
    final reason = await CancelAppointmentDialog.show(a.clientName);
    if (reason == null) return;
    final updated = await controller.cancel(a, reason: reason);
    if (updated == null) return;
    navigator.pop();
    _agenda.applyChange(updated);
  }

  Future<void> _edit() async {
    Navigator.of(context).pop();
    final saved = await AppointmentFormDialog.edit(a);
    if (saved != null) _agenda.applyChange(saved);
  }

  Future<void> _pay() async {
    final navigator = Navigator.of(context);
    final due = await controller.balanceDue(a);
    if (due == null) return;
    navigator.pop();
    if (due <= 0) {
      AppSnackbar.info('La cita ya está pagada');
      await _refresh();
      return;
    }
    final methods = await Get.find<PaymentController>().loadCustomMethods();
    final paid = await PaymentDialog.show(a,
        balanceDue: due, customMethods: methods);
    if (paid) await _refresh();
  }

  Future<void> _sendReminder() async {
    if (!await controller.sendReminder(a)) return;
    if (mounted) setState(() => _reminderSent = true);
    final fresh = await controller.fetchLatest(a.id);
    if (fresh != null) _agenda.applyChange(fresh);
  }

  /// Tras un pago la cita cambia (estado de pago y, al primer pago,
  /// confirmada): se lee de nuevo; si no se puede, se recarga la agenda.
  Future<void> _refresh() async {
    final fresh = await controller.fetchLatest(a.id);
    fresh == null ? await _agenda.reload() : _agenda.applyChange(fresh);
  }

  // --- Vista ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final now = BusinessTimeZone.now();
    final isOwner = AppointmentAccess.canPay();
    final canPay = isOwner && a.canBePaid;
    final canEdit = AppointmentAccess.canEdit() && !a.isFinal;
    // Completa solo el Owner (D-27) y una cita que ya empezó (7.03,
    // APPOINTMENT_NOT_STARTED).
    final canComplete = AppointmentAccess.canComplete() && a.canComplete;
    final hasStarted = a.canCompleteAt(now);
    final showPayments = isOwner &&
        !(a.isCancelled &&
            a.paymentStatus == AppointmentPaymentStatus.PENDING);
    final canRemind = !_reminderSent && controller.canSendReminder(a, now);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppointmentDetailHeader(
              appointment: a,
              onClose: () => Navigator.of(context).pop(),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (recordedZoneNote(a) case final note?)
                      AppNote(
                        note,
                        tone: AppTone.info,
                        icon: Icons.public_rounded,
                        margin: const EdgeInsets.only(bottom: 10),
                      ),
                    _reviewButton(),
                    if (a.needsReschedule)
                      AppNote(
                        '${a.rescheduleReason} Mientras tanto no ocupa la '
                        'hora.${AppointmentAccess.canEdit() ? '' : ' Solo el '
                            'propietario puede moverla.'}',
                        tone: AppTone.warning,
                        icon: Icons.report_problem_rounded,
                        margin: const EdgeInsets.only(bottom: 10),
                      ),
                    if (a.isWebBooking)
                      const _InfoRow(
                        icon: Icons.public_rounded,
                        title: 'Reserva web',
                        subtitle: 'El cliente la agendó desde el link público '
                            'del negocio.',
                      ),
                    if (!AppointmentAccess.professionalIsFixed())
                      _InfoRow(
                        title: 'Profesional',
                        subtitle: a.professionalName ?? 'Sin nombre',
                        leading: AppAvatar(
                            name: a.professionalName ?? '?', radius: 18),
                      ),
                    _ServicesSection(appointment: a),
                    if (showPayments)
                      FutureBuilder<AppointmentBalance?>(
                        future: _payments,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const AppointmentPaymentsSkeleton();
                          }
                          final balance = snapshot.data;
                          return balance == null
                              ? const SizedBox.shrink()
                              : AppointmentPaymentsSection(balance: balance);
                        },
                      ),
                    if (a.notes?.trim().isNotEmpty ?? false)
                      _InfoRow(
                          icon: Icons.notes_rounded,
                          title: 'Notas',
                          subtitle: a.notes!),
                    if (a.isCancelled &&
                        (a.cancellationReason?.trim().isNotEmpty ?? false))
                      _InfoRow(
                        icon: Icons.event_busy_rounded,
                        title: 'Motivo de la cancelación',
                        subtitle: a.cancellationReason!,
                      ),
                    if (a.reminderSent || _reminderSent)
                      const _InfoRow(
                        icon: Icons.mark_chat_read_rounded,
                        title: 'Recordatorio enviado',
                        subtitle: 'Ya se le escribió al cliente por WhatsApp.',
                      ),
                    if (!AppointmentAccess.canComplete() && a.canComplete)
                      const AppNote(
                        'Cuando el negocio marque esta cita como completada, '
                        'tu comisión pasa a Ganado en "Mis ganancias".',
                        tone: AppTone.info,
                        icon: Icons.savings_rounded,
                        margin: EdgeInsets.only(top: 10),
                        key: Key('detail-owner-completes'),
                      ),
                    if (!a.isFinal && !a.canCancel)
                      const AppNote(
                        'Tiene pagos registrados: reembólsalos antes de '
                        'cancelar la cita.',
                        tone: AppTone.warning,
                        icon: Icons.warning_amber_rounded,
                        margin: EdgeInsets.only(top: 10),
                      ),
                    const SizedBox(height: 16),
                    Obx(() {
                      final busy = controller.isBusy(a.id);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (busy)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: LinearProgressIndicator(),
                            ),
                          if (canPay) ...[
                            AppGradientButton(
                              icon: Icons.payments_rounded,
                              expand: true,
                              onPressed: busy ? null : _pay,
                              label: a.paymentStatus ==
                                      AppointmentPaymentStatus.PARTIAL
                                  ? 'Cobrar saldo'
                                  : 'Registrar pago',
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (canComplete) ...[
                            OutlinedButton.icon(
                              onPressed:
                                  busy || !hasStarted ? null : _complete,
                              icon: const Icon(Icons.task_alt_rounded),
                              label: Text(hasStarted
                                  ? 'Completar'
                                  : 'Completar (cuando empiece)'),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (canEdit) ...[
                            OutlinedButton.icon(
                              onPressed: busy ? null : _edit,
                              icon: Icon(a.needsReschedule
                                  ? Icons.edit_calendar_rounded
                                  : Icons.edit_rounded),
                              label: Text(a.needsReschedule
                                  ? 'Mover a otra hora'
                                  : 'Editar'),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (canRemind) ...[
                            OutlinedButton.icon(
                              key: const Key('detail-reminder'),
                              onPressed: busy ? null : _sendReminder,
                              icon: const WhatsappIcon(size: 20),
                              label: const Text('Recordatorio por WhatsApp'),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (a.canCancel)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error),
                              onPressed: busy ? null : _cancel,
                              icon: const Icon(Icons.event_busy_rounded),
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

  /// "N pagos en revisión: revisar" (10.03, solo Owner).
  Widget _reviewButton() => FutureBuilder<int>(
        future: _inReview,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          if (count == 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              key: const Key('detail-review-payments'),
              onPressed: () {
                Navigator.of(context).pop();
                Get.toNamed(GetRoutes.paymentsReview);
              },
              icon: const Icon(Icons.flag_rounded),
              label: Text(
                  '${formatCount(count, 'pago en revisión', 'pagos en revisión')}'
                  ': revisar'),
            ),
          );
        },
      );
}

/// Dato del detalle: ícono (o [leading]) en una píldora tonal, título y
/// texto.
class _InfoRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String subtitle;

  const _InfoRow({
    this.icon,
    this.leading,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading ??
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: AppRadii.chipRadius,
                ),
                child: Icon(icon, size: 19, color: scheme.onPrimaryContainer),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                Text(subtitle,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Servicios de la cita en píldoras con su color, duración y el precio
/// guardado en la cita (2.29), y el total.
class _ServicesSection extends StatelessWidget {
  final AppointmentEntity appointment;

  const _ServicesSection({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          icon: Icons.spa_rounded,
          title: 'Servicios',
          subtitle: formatCount(a.services.length, 'servicio', 'servicios'),
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
        ),
        for (var i = 0; i < a.services.length; i++)
          _ServiceLine(line: a.services[i], color: a.serviceColor(i)),
        const Divider(height: 18),
        Row(
          children: [
            Expanded(
              child: Text('Total',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Text(formatCop(a.totalPrice),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)
                    .tabular),
          ],
        ),
      ],
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = line.currentPrice;
    final changed = current != null && (current - line.price).abs() >= 0.01;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppointmentServicePill(
                  name: line.name,
                  color: color,
                  foreground: scheme.onSurface,
                  onSurface: true,
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    formatDurationMinutes(line.durationMinutes) +
                        (changed ? ' · hoy cuesta ${formatCop(current)}' : ''),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(formatCop(line.price),
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)
                  .tabular),
        ],
      ),
    );
  }
}

