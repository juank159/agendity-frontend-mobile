import 'package:flutter/material.dart';

/// Estado vacío de una lista. Ver también [ListStateView].
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subMessage;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData? actionIcon;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subMessage,
    this.onAction,
    this.actionLabel,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage!,
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              actionIcon == null
                  ? ElevatedButton(onPressed: onAction, child: Text(actionLabel!))
                  : ElevatedButton.icon(
                      onPressed: onAction,
                      icon: Icon(actionIcon),
                      label: Text(actionLabel!),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
