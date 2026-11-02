import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/appointments/presentation/widgets/client_search_selector.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_delivery.dart';
import 'package:login_signup/features/reminders/presentation/controllers/reminder_history_controller.dart';
import 'package:login_signup/features/reminders/presentation/widgets/reminder_ui.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';

/// Historial de envíos (lo más reciente primero): estado y motivo en
/// lenguaje humano, con filtros por estado y por cliente.
class ReminderHistoryScreen extends GetView<ReminderHistoryController> {
  const ReminderHistoryScreen({super.key});

  Future<void> _pickClient() async {
    final client = await ClientSearchSelector.show();
    if (client != null) controller.setClient(client);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de envíos')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Obx(() {
              final selected = controller.statusFilter.value;
              final client = controller.clientFilter.value;
              return Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: selected == null,
                    onSelected: (_) => controller.setStatus(null),
                  ),
                  for (final status in DeliveryStatus.values) ...[
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(status.label),
                      selected: selected == status,
                      onSelected: (_) => controller.setStatus(status),
                    ),
                  ],
                  const SizedBox(width: 12),
                  client == null
                      ? ActionChip(
                          avatar: const Icon(Icons.person_search_rounded, size: 18),
                          label: const Text('Cliente'),
                          onPressed: _pickClient,
                        )
                      : InputChip(
                          avatar: const Icon(Icons.person_rounded, size: 18),
                          label: Text(client.fullName),
                          onDeleted: () => controller.setClient(null),
                        ),
                ],
              );
            }),
          ),
          Expanded(
            child: Obx(() => ListStateView<ReminderDelivery>(
                  isLoading: controller.isLoading.value,
                  error: controller.error.value?.message,
                  items: controller.deliveries.toList(),
                  onRetry: controller.load,
                  emptyIcon: Icons.mark_chat_unread_rounded,
                  emptyMessage: 'Sin envíos',
                  emptySubMessage: 'Aquí verás cada recordatorio enviado o '
                      'el motivo por el que no se envió.',
                  builder: (context, items) => RefreshIndicator(
                    onRefresh: controller.load,
                    child: NotificationListener<ScrollEndNotification>(
                      onNotification: (n) {
                        if (n.metrics.extentAfter < 200) controller.loadMore();
                        return false;
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                        itemCount: items.length,
                        itemBuilder: (context, i) => AppFadeIn(
                            index: i, child: _DeliveryTile(delivery: items[i])),
                      ),
                    ),
                  ),
                )),
          ),
        ],
      ),
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  final ReminderDelivery delivery;

  const _DeliveryTile({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = context.tokens.tone(delivery.status.tone);
    final when = delivery.sentAt ?? delivery.scheduledFor ?? delivery.createdAt;
    final reason = deliveryReasonLabel(delivery.reason);
    return AppCard(
      depth: 1,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppRadii.chipRadius,
            ),
            child: Icon(delivery.kind?.icon ?? Icons.message_rounded,
                size: 20, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(delivery.kind?.label ?? 'Mensaje',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      label: delivery.status.label,
                      icon: delivery.status.icon,
                      colors: tone,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (delivery.phone != null) delivery.phone!,
                    if (when != null)
                      '${formatShortDate(when)} · ${formatTime(when)}',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.tabular
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(reason, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
