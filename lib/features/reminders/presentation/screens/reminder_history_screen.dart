import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/appointments/presentation/widgets/client_search_selector.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_delivery.dart';
import 'package:login_signup/features/reminders/presentation/controllers/reminder_history_controller.dart';
import 'package:login_signup/features/reminders/presentation/widgets/reminder_ui.dart';

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
                          avatar: const Icon(Icons.person_search, size: 18),
                          label: const Text('Cliente'),
                          onPressed: _pickClient,
                        )
                      : InputChip(
                          avatar: const Icon(Icons.person, size: 18),
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
                  emptyIcon: Icons.mark_chat_unread_outlined,
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
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) =>
                            _DeliveryTile(delivery: items[i]),
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
    final tone = context.tokens.tone(delivery.status.tone);
    final when = delivery.sentAt ?? delivery.scheduledFor ?? delivery.createdAt;
    final reason = deliveryReasonLabel(delivery.reason);
    return ListTile(
      leading: Icon(delivery.kind?.icon ?? Icons.message_outlined),
      title: Text(delivery.kind?.label ?? 'Mensaje'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text([
            if (delivery.phone != null) delivery.phone!,
            if (when != null) '${formatShortDate(when)} · ${formatTime(when)}',
          ].join(' · ')),
          if (reason.isNotEmpty)
            Text(reason,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: tone.container, borderRadius: BorderRadius.circular(12)),
        child: Text(delivery.status.label,
            style: TextStyle(color: tone.onContainer)),
      ),
    );
  }
}
