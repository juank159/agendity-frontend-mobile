import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_settings.dart';
import 'package:login_signup/features/reminders/presentation/controllers/reminders_controller.dart';
import 'package:login_signup/features/reminders/presentation/widgets/reminder_rule_dialog.dart';
import 'package:login_signup/features/reminders/presentation/widgets/reminder_ui.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';
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
            icon: const Icon(Icons.history_rounded),
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
              icon: isFinal ? Icons.lock_rounded : Icons.cloud_off_rounded,
              message: controller.loadError.value ?? '',
              onRetry: isFinal ? null : controller.load,
            );
          case RemindersStatus.ready:
            final settings = controller.settings.value!;
            final sections = <Widget>[
              if (settings.isSimulated) const _SimulatedNotice(),
              const _HowItWorks(),
              _GeneralCard(settings: settings),
              _QuotaCard(quota: settings.quota),
              const AppSectionHeader(
                icon: Icons.auto_awesome_rounded,
                title: 'Tipos de recordatorio',
                subtitle: 'Toca una regla para editar su texto o su hora.',
                padding: EdgeInsets.fromLTRB(4, 16, 4, 4),
              ),
              for (final kind in ReminderKind.values) _KindCard(kind: kind),
            ];
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  for (var i = 0; i < sections.length; i++)
                    AppFadeIn(index: i, child: sections[i]),
                ],
              ),
            );
        }
      }),
    );
  }
}

/// Margen entre las tarjetas de la pantalla (la lista ya pone los lados).
const _cardMargin = EdgeInsets.symmetric(vertical: 6);

class _SimulatedNotice extends StatelessWidget {
  const _SimulatedNotice();

  @override
  Widget build(BuildContext context) => const AppNote(
        'Modo prueba: los mensajes no se envían de verdad. Quedan en el '
        'historial para que veas qué se habría enviado.',
        key: Key('reminders-simulated'),
        tone: AppTone.warning,
        icon: Icons.science_rounded,
        margin: EdgeInsets.only(bottom: 10),
      );
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) => const AppNote(
        'Los mensajes automáticos salen del número de WhatsApp de '
        'Agendity con el nombre de tu negocio. Al cliente le llega el '
        'mensaje aprobado de Agendity con sus datos (nombre, fecha, '
        'hora…), y solo si aceptó recibirlos (casilla en su ficha). El '
        'texto propio de cada recordatorio se usa cuando lo envías tú '
        'desde la cita por WhatsApp.',
        tone: AppTone.info,
        icon: Icons.info_rounded,
        margin: EdgeInsets.only(bottom: 10),
      );
}

class _GeneralCard extends GetView<RemindersController> {
  final ReminderSettings settings;

  const _GeneralCard({required this.settings});

  @override
  Widget build(BuildContext context) => Obx(() => _card(context));

  Widget _card(BuildContext context) {
    final theme = Theme.of(context);
    final busy = controller.isSaving.value;
    return AppCard(
      margin: _cardMargin,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(
            padding: EdgeInsets.zero,
            icon: Icons.send_rounded,
            title: 'Envío automático',
          ),
          const SizedBox(height: 8),
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
          const Divider(height: 20),
          Text('Horario de envío',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Fuera de este horario no se envían mensajes (en la hora del '
            'negocio). Si inicio y fin son iguales, se envía todo el día.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
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
    );
  }
}

class _QuotaCard extends StatelessWidget {
  final MessageQuota quota;

  const _QuotaCard({required this.quota});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final exhausted = quota.isExhausted;
    final ratio =
        quota.isUnlimited || quota.limit == 0 ? 0.0 : quota.used / quota.limit;
    final barColor = exhausted
        ? tokens.error.color
        : ratio >= 0.8
            ? tokens.warning.color
            : scheme.primary;
    return AppCard(
      margin: _cardMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(
            padding: EdgeInsets.zero,
            icon: Icons.forum_rounded,
            title: 'Mensajes de este mes',
          ),
          const SizedBox(height: 12),
          Text(
            quota.isUnlimited
                ? '${quota.used} enviados · sin límite'
                : '${quota.used} de ${quota.limit} usados',
            key: const Key('reminders-quota'),
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)
                .tabular,
          ),
          if (!quota.isUnlimited) ...[
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio.clamp(0, 1).toDouble()),
              duration: AppMotion.of(context, AppMotion.slow),
              curve: AppMotion.curve,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                color: barColor,
                backgroundColor: barColor.withValues(alpha: 0.15),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
          if (exhausted) ...[
            const SizedBox(height: 12),
            const AppNote(
              'Se agotaron los mensajes de este mes. Los recordatorios '
              'automáticos se pausan hasta el próximo mes; mientras '
              'tanto, envíalos tú desde cada cita por WhatsApp.',
              key: Key('reminders-quota-exhausted'),
              tone: AppTone.error,
              icon: Icons.block_rounded,
            ),
          ],
        ],
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
        ReminderKind.winBack => 'A los ${rule.daysWithoutVisit} días sin '
            'venir, a las ${_clock(rule.sendTime)}',
        _ => 'A las ${_clock(rule.sendTime)}',
      };

  /// Hora de envío en 12 h (D-23).
  static String _clock(String? hhmm) =>
      hhmm == null ? '—' : formatHhmm(hhmm);

  ReminderRule _newRule() => switch (kind) {
        ReminderKind.beforeAppointment => const ReminderRule(
            kind: ReminderKind.beforeAppointment, minutesBefore: 1440),
        ReminderKind.winBack => const ReminderRule(
            kind: ReminderKind.winBack,
            daysWithoutVisit: 60,
            sendTime: '10:00'),
        _ => ReminderRule(kind: kind, sendTime: '10:00'),
      };

  @override
  Widget build(BuildContext context) => Obx(() => _card(context));

  Widget _card(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rules = controller.rulesOf(kind);
    return AppCard(
      margin: _cardMargin,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppSectionHeader(
                  padding: EdgeInsets.zero,
                  icon: kind.icon,
                  title: kind.label,
                ),
              ),
              if (controller.canAdd(kind))
                TextButton.icon(
                  key: Key('reminder-add-${kind.apiValue}'),
                  onPressed: () => ReminderRuleDialog.show(_newRule()),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Añadir'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(kind.explanation,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          if (rules.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: AppRadii.fieldRadius,
              ),
              child: Row(
                children: [
                  Icon(Icons.do_not_disturb_on_rounded,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text('Sin configurar',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          for (final rule in rules) _RuleTile(rule: rule, title: _subtitle(rule)),
        ],
      ),
    );
  }
}

/// Una regla: tarjeta tonal con su momento, si está activa, el interruptor y
/// borrar. Tocarla abre el diálogo de la regla.
class _RuleTile extends GetView<RemindersController> {
  final ReminderRule rule;
  final String title;

  const _RuleTile({required this.rule, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = rule.isActive;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: active
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : scheme.surfaceContainerLow,
        borderRadius: AppRadii.fieldRadius,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: Key('reminder-rule-${rule.id}'),
          contentPadding: const EdgeInsets.only(left: 12, right: 4),
          leading: Icon(
              active ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
              color: active ? scheme.primary : scheme.onSurfaceVariant),
          title: Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? scheme.onSurface : scheme.onSurfaceVariant)),
          subtitle: Text(active ? 'Activo' : 'Desactivado'),
          onTap: () => ReminderRuleDialog.show(rule),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: active,
                onChanged: (v) => controller.setRuleActive(rule, v),
              ),
              IconButton(
                tooltip: 'Borrar',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => controller.deleteRule(rule),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
