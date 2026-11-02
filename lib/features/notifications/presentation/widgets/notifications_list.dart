import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/notifications/domain/entities/app_notification.dart';
import 'package:login_signup/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:login_signup/shared/widgets/app_card.dart';

/// Lista de avisos (los más recientes primero), con "deslizar para
/// refrescar".
class NotificationsList extends GetView<NotificationsController> {
  const NotificationsList({super.key});

  static IconData iconFor(String type) => switch (type) {
        'APPOINTMENT_REMINDER' => Icons.alarm_rounded,
        _ when type.contains('PAYMENT') => Icons.payments_rounded,
        _ when type.contains('APPOINTMENT') => Icons.event_note_rounded,
        _ => Icons.notifications_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Obx(() => ListStateView<AppNotification>(
          isLoading: controller.isLoading.value,
          error: controller.error.value?.message,
          items: controller.notifications.toList(),
          onRetry: controller.load,
          emptyIcon: Icons.notifications_none_rounded,
          emptyMessage: 'No tienes avisos',
          emptySubMessage:
              'Aquí llegan, por ejemplo, los recordatorios automáticos de '
              'tus citas.',
          builder: (context, items) => RefreshIndicator(
            onRefresh: controller.refreshFromServer,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              itemCount: items.length,
              itemBuilder: (context, index) => AppFadeIn(
                index: index,
                child: NotificationTile(notification: items[index]),
              ),
            ),
          ),
        ));
  }
}

/// Un aviso: tarjeta con el ícono de su tipo en una píldora, título (en
/// negrita y con punto si no se ha leído), mensaje y fecha.
class NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final n = notification;
    final date = n.createdAt;
    final unread = !n.read;
    return AppCard(
      depth: unread ? 2 : 1,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: unread ? tokens.primaryGradient : null,
              color: unread ? null : scheme.surfaceContainerHigh,
              borderRadius: AppRadii.chipRadius,
            ),
            child: Icon(NotificationsList.iconFor(n.type),
                size: 22,
                color: unread ? tokens.onGradient : scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(n.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w600)),
                    ),
                    if (date != null) ...[
                      const SizedBox(width: 8),
                      Text('${formatShortDate(date)}\n${formatTime(date)}',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodySmall?.tabular
                              .copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(n.message,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (unread)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Semantics(
                label: 'Sin leer',
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: scheme.primary, shape: BoxShape.circle),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
