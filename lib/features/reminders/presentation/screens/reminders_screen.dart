import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_settings.dart';
import 'package:login_signup/features/reminders/presentation/controllers/reminders_controller.dart';
import 'package:login_signup/features/reminders/presentation/widgets/reminder_rule_dialog.dart';
import 'package:login_signup/features/reminders/presentation/widgets/reminder_ui.dart';
import 'package:login_signup/shared/widgets/time_of_day_button.dart';

/// "Recordatorios" (Fase 11, solo Owner): mensajes automáticos por WhatsApp
/// desde el número de Agendity, con el nombre del negocio (D-20); solo a
/// clientes que aceptaron (D-21) y dentro del cupo del mes.
class RemindersScreen extends GetView<RemindersController> {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        actions: [
          IconButton(
            tooltip: 'Historial de envíos',
            icon: const Icon(Icons.history),
            onPressed: () => Get.toNamed(GetRoutes.reminderHistory),
          ),
        ],
      ),
      body: Obx(() {
        switch (controller.status.value) {
          case RemindersStatus.loading:
            return const LoadingState(message: 'Cargando recordatorios…');
          case RemindersStatus.error:
            final isFinal = controller.loadErrorIsFinal.value;
            return ErrorState(
              title: isFinal ? 'Sin acceso' : 'No se pudo cargar',
              icon: isFinal ? Icons.lock_outline : Icons.error_outline,
              message: controller.loadError.value ?? '',
              onRetry: isFinal ? null : controller.load,
            );
          case RemindersStatus.ready:
            final settings = controller.settings.value!;
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (settings.isSimulated) const _SimulatedNotice(),
                  const _HowItWorks(),
                  _GeneralCard(settings: settings),
                  _QuotaCard(quota: settings.quota),
                  for (final kind in ReminderKind.values) _KindCard(kind: kind),
                ],
              ),
            );
        }
      }),
    );
  }
}

class _Note extends StatelessWidget {
  final AppTone tone;
  final IconData icon;
  final String text;
  final Key? noteKey;

  const _Note(
      {required this.tone, required this.icon, required this.text, this.noteKey});

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.tone(tone);
    return Container(
      key: noteKey,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: colors.container, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.onContainer),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: TextStyle(color: colors.onContainer))),
        ],
      ),
    );
  }
}

class _SimulatedNotice extends StatelessWidget {
  const _SimulatedNotice();

  @override
  Widget build(BuildContext context) => const _Note(
        noteKey: Key('reminders-simulated'),
        tone: AppTone.warning,
        icon: Icons.science_outlined,
        text: 'Modo prueba: los mensajes no se envían de verdad. Quedan en el '
            'historial para que veas qué se habría enviado.',
      );
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) => const _Note(
        tone: AppTone.info,
        icon: Icons.info_outline,
        text: 'Los mensajes automáticos salen del número de WhatsApp de '
            'Agendity con el nombre de tu negocio. Al cliente le llega el '
            'mensaje aprobado de Agendity con sus datos (nombre, fecha, '
            'hora…), y solo si aceptó recibirlos (casilla en su ficha). El '
            'texto propio de cada recordatorio se usa cuando lo envías tú '
            'desde la cita por WhatsApp.',
      );
}

class _GeneralCard extends GetView<RemindersController> {
  final ReminderSettings settings;

  const _GeneralCard({required this.settings});

  @override
  Widget build(BuildContext context) => Obx(() => _card(context));

  Widget _card(BuildContext context) {
    final busy = controller.isSaving.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              key: const Key('reminders-enabled'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Enviar recordatorios automáticos'),
              subtitle: Text(settings.enabled
                  ? 'Activos'
                  : 'Apagados: no se envía ningún mensaje automático'),
              value: settings.enabled,
              onChanged: busy ? null : controller.setEnabled,
            ),
            const Divider(),
            const Text('Horario de envío'),
            const SizedBox(height: 4),
            Text(
              'Fuera de este horario no se envían mensajes (en la hora del '
              'negocio). Si inicio y fin son iguales, se envía todo el día.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TimeOfDayButton(
                  label: 'Desde',
                  value: settings.sendWindowStart,
                  semantics: 'Inicio del horario de envío',
                  onPicked: controller.setWindowStart,
                ),
                TimeOfDayButton(
                  label: 'Hasta',
                  value: settings.sendWindowEnd,
                  semantics: 'Fin del horario de envío',
                  onPicked: controller.setWindowEnd,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  final MessageQuota quota;

  const _QuotaCard({required this.quota});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final exhausted = quota.isExhausted;
    final ratio =
        quota.isUnlimited || quota.limit == 0 ? 0.0 : quota.used / quota.limit;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mensajes de este mes', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              quota.isUnlimited
                  ? '${quota.used} enviados · sin límite'
                  : '${quota.used} de ${quota.limit} usados',
              key: const Key('reminders-quota'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (!quota.isUnlimited) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: ratio.clamp(0, 1).toDouble(),
                color: exhausted
                    ? tokens.error.color
                    : ratio >= 0.8
                        ? tokens.warning.color
                        : null,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            if (exhausted) ...[
              const SizedBox(height: 12),
              const _Note(
                noteKey: Key('reminders-quota-exhausted'),
                tone: AppTone.error,
                icon: Icons.block,
                text: 'Se agotaron los mensajes de este mes. Los recordatorios '
                    'automáticos se pausan hasta el próximo mes; mientras '
                    'tanto, envíalos tú desde cada cita por WhatsApp.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KindCard extends GetView<RemindersController> {
  final ReminderKind kind;

  const _KindCard({required this.kind});

  String _subtitle(ReminderRule rule) => switch (kind) {
        ReminderKind.beforeAppointment =>
          minutesBeforeLabel(rule.minutesBefore ?? 0),
        ReminderKind.winBack =>
          'A los ${rule.daysWithoutVisit} días sin venir, a las ${rule.sendTime}',
        _ => 'A las ${rule.sendTime ?? '—'}',
      };

  ReminderRule _newRule() => switch (kind) {
        ReminderKind.beforeAppointment =>
          const ReminderRule(kind: ReminderKind.beforeAppointment, minutesBefore: 1440),
        ReminderKind.winBack =>
          const ReminderRule(kind: ReminderKind.winBack, daysWithoutVisit: 60, sendTime: '10:00'),
        _ => ReminderRule(kind: kind, sendTime: '10:00'),
      };

  @override
  Widget build(BuildContext context) => Obx(() => _card(context));

  Widget _card(BuildContext context) {
    final theme = Theme.of(context);
    final rules = controller.rulesOf(kind);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(kind.icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(kind.label,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (controller.canAdd(kind))
                  TextButton.icon(
                    key: Key('reminder-add-${kind.apiValue}'),
                    onPressed: () => ReminderRuleDialog.show(_newRule()),
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir'),
                  ),
              ],
            ),
            Text(kind.explanation, style: theme.textTheme.bodySmall),
            if (rules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Sin configurar',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            for (final rule in rules)
              ListTile(
                key: Key('reminder-rule-${rule.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(_subtitle(rule)),
                subtitle: Text(rule.isActive ? 'Activo' : 'Desactivado'),
                onTap: () => ReminderRuleDialog.show(rule),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: rule.isActive,
                      onChanged: (v) => controller.setRuleActive(rule, v),
                    ),
                    IconButton(
                      tooltip: 'Borrar',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => controller.deleteRule(rule),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
