import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/notifications/domain/entities/app_notification.dart';
import 'package:login_signup/features/notifications/presentation/controllers/notifications_controller.dart';

/// Lista de avisos (los más recientes primero), con "deslizar para
/// refrescar".
class NotificationsList extends GetView<NotificationsController> {
  const NotificationsList({super.key});

  static IconData iconFor(String type) => switch (type) {
        'APPOINTMENT_REMINDER' => Icons.alarm,
        _ when type.contains('PAYMENT') => Icons.payments_outlined,
        _ when type.contains('APPOINTMENT') => Icons.event_note,
        _ => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() => ListStateView<AppNotification>(
          isLoading: controller.isLoading.value,
          error: controller.error.value?.message,
          items: controller.notifications.toList(),
          onRetry: controller.load,
          emptyIcon: Icons.notifications_none,
          emptyMessage: 'No tienes avisos',
          emptySubMessage:
              'Aquí llegan, por ejemplo, los recordatorios automáticos de '
              'tus citas.',
          builder: (context, items) => RefreshIndicator(
            onRefresh: controller.refreshFromServer,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = items[index];
                final date = n.createdAt;
                return ListTile(
                  leading: Icon(iconFor(n.type),
                      color: n.read
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary),
                  title: Text(n.title,
                      style: TextStyle(
                          fontWeight:
                              n.read ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text(n.message),
                  trailing: date == null
                      ? null
                      : Text('${formatShortDate(date)}\n${formatTime(date)}',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodySmall),
                );
              },
            ),
          ),
        ));
  }
}
