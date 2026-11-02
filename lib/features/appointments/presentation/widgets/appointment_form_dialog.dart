import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_form_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_tile.dart';
import 'package:login_signup/features/appointments/presentation/widgets/client_search_selector.dart';
import 'package:login_signup/features/appointments/presentation/widgets/professional_selector_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/service_selector_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/slot_picker.dart';
import 'package:login_signup/shared/utils/color_hex.dart';
import 'package:login_signup/shared/widgets/app_dialog_title.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';

/// **Único** formulario de cita: nueva (Owner y Employee) y edición (Owner).
/// Crea su `AppointmentFormController` al abrirse y lo borra al cerrarse.
/// Devuelve la cita guardada o `null`.
class AppointmentFormDialog extends StatefulWidget {
  final AppointmentFormController Function() createController;

  const AppointmentFormDialog({super.key, required this.createController});

  /// Cita nueva; [initialStart] = hora tocada en el calendario (se elige si
  /// está libre).
  static Future<AppointmentEntity?> create({DateTime? initialStart}) =>
      Get.dialog<AppointmentEntity>(
        AppointmentFormDialog(
          createController: () => AppointmentFormController.fromDependencies(
              initialStart: initialStart),
        ),
        barrierDismissible: false,
      );

  static Future<AppointmentEntity?> edit(AppointmentEntity appointment) =>
      Get.dialog<AppointmentEntity>(
        AppointmentFormDialog(
          createController: () =>
              AppointmentFormController.fromDependencies(original: appointment),
        ),
        barrierDismissible: false,
      );

  @override
  State<AppointmentFormDialog> createState() => _AppointmentFormDialogState();
}

class _AppointmentFormDialogState extends State<AppointmentFormDialog> {
  late final String _tag = 'appointment-form-${identityHashCode(this)}';
  late final AppointmentFormController c;

  @override
  void initState() {
    super.initState();
    c = Get.put(widget.createController(), tag: _tag);
  }

  @override
  void dispose() {
    Get.delete<AppointmentFormController>(tag: _tag);
    super.dispose();
  }

  Future<void> _pickProfessional() async {
    final chosen = await ProfessionalSelectorDialog.show(c.professionals,
        selectedId: c.professional.value?.id);
    if (chosen != null) c.selectProfessional(chosen);
  }

  Future<void> _pickServices() async {
    final ids =
        await ServiceSelectorDialog.show(c.offeredCatalog,
        selectedIds: c.serviceIds);
    if (ids != null) c.setServices(ids);
  }

  Future<void> _pickClient() async {
    final client = await ClientSearchSelector.show();
    if (client != null) c.selectClient(client);
  }

  Future<void> _pickDay() async {
    final today = BusinessTimeZone.today();
    final current = c.day.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: current.isBefore(today) ? current : today,
      lastDate: DateTime(today.year + 1, today.month, today.day),
      currentDate: today,
    );
    if (picked != null) c.selectDay(picked);
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final saved = await c.submit();
    if (saved != null && mounted) navigator.pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDialogTitle(
                icon: c.isEditing
                    ? Icons.edit_calendar_rounded
                    : Icons.event_available_rounded,
                title: c.isEditing ? 'Editar cita' : 'Nueva cita',
                subtitle: c.isEditing
                    ? 'Cambia lo que necesites y guarda.'
                    : 'Profesional, servicios, cliente y hora.',
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FieldTile(
                            key: const Key('appointment-professional'),
                            icon: Icons.person_rounded,
                            label: 'Profesional',
                            value: c.professional.value?.name,
                            placeholder: 'Elegir profesional',
                            onTap: c.professionalIsFixed
                                ? null
                                : _pickProfessional,
                          ),
                          _FieldTile(
                            key: const Key('appointment-services'),
                            icon: Icons.spa_rounded,
                            label: 'Servicios',
                            placeholder: c.isLoadingCatalog.value
                                ? 'Cargando servicios…'
                                : 'Elegir servicios',
                            content: c.serviceIds.isEmpty
                                ? null
                                : Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final id in c.serviceIds)
                                        AppointmentServicePill(
                                          name: c.nameOf(id),
                                          color: colorFromHex(c.colorOf(id)),
                                          foreground:
                                              theme.colorScheme.onSurface,
                                          onSurface: true,
                                        ),
                                    ],
                                  ),
                            onTap: c.isLoadingCatalog.value
                                ? null
                                : _pickServices,
                          ),
                          _FieldTile(
                            key: const Key('appointment-client'),
                            icon: Icons.face_rounded,
                            label: 'Cliente',
                            value: c.client.value?.fullName,
                            placeholder: 'Elegir cliente',
                            onTap: _pickClient,
                          ),
                          _FieldTile(
                            key: const Key('appointment-day'),
                            icon: Icons.event_rounded,
                            label: 'Día',
                            value: _capitalized(formatLongDate(c.day.value)),
                            onTap: _pickDay,
                          ),
                          const AppSectionHeader(
                            icon: Icons.schedule_rounded,
                            title: 'Hora',
                            subtitle: 'Solo las horas libres del profesional.',
                            padding: EdgeInsets.fromLTRB(0, 12, 0, 10),
                          ),
                          SlotPicker(controller: c),
                          const SizedBox(height: 16),
                          TextField(
                            key: const Key('appointment-notes'),
                            controller: c.notes,
                            maxLines: 3,
                            minLines: 1,
                            decoration: const InputDecoration(
                              labelText: 'Notas (opcional)',
                              prefixIcon: Icon(Icons.notes_rounded),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      )),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => c.serviceIds.isEmpty
                  ? const SizedBox.shrink()
                  : _TotalSummary(
                      count: c.serviceIds.length,
                      total: c.totalPrice,
                      minutes: c.totalMinutes,
                    )),
              const SizedBox(height: 12),
              Obx(() => Row(
                    children: [
                      TextButton(
                        onPressed: c.isSaving.value
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppGradientButton(
                          label: c.isEditing ? 'Guardar cambios' : 'Agendar',
                          icon: Icons.check_rounded,
                          expand: true,
                          loading: c.isSaving.value,
                          onPressed: c.canSubmit ? _save : null,
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  static String _capitalized(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

/// Un dato del formulario que se elige en otro diálogo: tarjeta tonal con
/// ícono, etiqueta y el valor (o [content], p. ej. las píldoras de los
/// servicios). Sin [onTap] queda fija (el Employee no cambia de
/// profesional). Por dentro es un `ListTile` (los tests leen su `onTap`).
class _FieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? content;
  final String? placeholder;
  final VoidCallback? onTap;

  const _FieldTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.content,
    this.placeholder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shown = content;
    final empty = shown == null && (value == null || value!.isEmpty);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.fieldRadius,
          side: BorderSide(
              color: empty
                  ? scheme.outlineVariant.withValues(alpha: 0.6)
                  : scheme.primary.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 2, 8, 2),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppRadii.chipRadius,
            ),
            child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
          ),
          title: Text(label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: shown ??
                Text(
                  empty ? placeholder ?? '' : value!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: empty ? FontWeight.w500 : FontWeight.w600,
                    color: empty ? scheme.onSurfaceVariant : scheme.onSurface,
                  ),
                ),
          ),
          trailing: onTap == null
              ? null
              : Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Resumen de la cita al pie del formulario: número de servicios y el total
/// con su duración en **un solo texto** (`$ 160.000 · 1 h 5 min`; lo leen
/// los integration_test).
class _TotalSummary extends StatelessWidget {
  final int count;
  final double total;
  final int minutes;

  const _TotalSummary({
    required this.count,
    required this.total,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final on = tokens.onGradient;
    return Container(
      key: const Key('appointment-total'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: tokens.primaryGradient,
        borderRadius: AppRadii.fieldRadius,
        border: Border.all(color: tokens.innerBorder),
        boxShadow: tokens.elevation1(tint: tokens.gradientEnd),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: AppRadii.fieldRadius,
        gradient: tokens.sheenGradient,
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, color: on, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Total · ${formatCount(count, 'servicio', 'servicios')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: on.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${formatCop(total)} · ${formatDurationMinutes(minutes)}',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: on, fontWeight: FontWeight.w800)
                .tabular,
          ),
        ],
      ),
    );
  }
}

/// Abre el formulario de una cita nueva desde la agenda (botón "+" o una
/// hora tocada en el calendario) y muestra la cita creada. Antes comprueba
/// el plan: si ya no admite citas, sale el diálogo de suscripción.
Future<void> startNewAppointment(AppointmentsController agenda,
    {DateTime? at}) async {
  if (!await agenda.canStartAppointment()) return;
  final created = await AppointmentFormDialog.create(
      initialStart: at ?? agenda.newAppointmentStart);
  if (created != null) agenda.focusOn(created);
}
