import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_form_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/client_search_selector.dart';
import 'package:login_signup/features/appointments/presentation/widgets/professional_selector_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/service_selector_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/slot_picker.dart';

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
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(c.isEditing ? 'Editar cita' : 'Nueva cita',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FieldTile(
                            key: const Key('appointment-professional'),
                            icon: Icons.person_outline,
                            label: 'Profesional',
                            value: c.professional.value?.name,
                            placeholder: 'Elegir profesional',
                            onTap: c.professionalIsFixed
                                ? null
                                : _pickProfessional,
                          ),
                          _FieldTile(
                            key: const Key('appointment-services'),
                            icon: Icons.spa_outlined,
                            label: 'Servicios',
                            value: c.serviceIds.isEmpty
                                ? null
                                : c.serviceIds.map(c.nameOf).join(', '),
                            detail: c.serviceIds.isEmpty
                                ? null
                                : '${formatCop(c.totalPrice)} · '
                                    '${formatDurationMinutes(c.totalMinutes)}',
                            placeholder: c.isLoadingCatalog.value
                                ? 'Cargando servicios…'
                                : 'Elegir servicios',
                            onTap: c.isLoadingCatalog.value
                                ? null
                                : _pickServices,
                          ),
                          _FieldTile(
                            key: const Key('appointment-client'),
                            icon: Icons.face_outlined,
                            label: 'Cliente',
                            value: c.client.value?.fullName,
                            placeholder: 'Elegir cliente',
                            onTap: _pickClient,
                          ),
                          _FieldTile(
                            key: const Key('appointment-day'),
                            icon: Icons.event_outlined,
                            label: 'Día',
                            value: formatLongDate(c.day.value),
                            onTap: _pickDay,
                          ),
                          const SizedBox(height: 8),
                          Text('Hora', style: theme.textTheme.titleSmall),
                          SlotPicker(controller: c),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('appointment-notes'),
                            controller: c.notes,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notas (opcional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      )),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: c.isSaving.value
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: c.canSubmit ? _save : null,
                        child: c.isSaving.value
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Text(c.isEditing ? 'Guardar cambios' : 'Agendar'),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un dato del formulario que se elige en otro diálogo.
class _FieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? detail;
  final String? placeholder;
  final VoidCallback? onTap;

  const _FieldTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.detail,
    this.placeholder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final empty = value == null || value!.isEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: scheme.primary),
      title: Text(label,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      subtitle: Text(
        empty
            ? placeholder ?? ''
            : detail == null
                ? value!
                : '$value\n$detail',
        style: TextStyle(
          fontSize: 16,
          color: empty ? scheme.onSurfaceVariant : scheme.onSurface,
        ),
      ),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
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
