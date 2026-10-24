import 'package:flutter/material.dart';

import 'empty_state.dart';
import 'error_state.dart';
import 'loading_state.dart';

/// Decide qué pintar en una lista: carga, error, vacío o el contenido.
///
/// Pensado para los controllers de GetX (`isLoading`, `error`, `items`):
/// ```dart
/// Obx(() => ListStateView<Client>(
///       isLoading: controller.isLoading.value,
///       error: controller.error.value,
///       items: controller.clients,
///       onRetry: controller.load,
///       emptyIcon: Icons.people_outline,
///       emptyMessage: 'Aún no tienes clientes',
///       builder: (context, clients) => ListView(...),
///     ))
/// ```
/// Con elementos ya cargados, una recarga o un error no ocultan la lista
/// (el error se avisa con `AppSnackbar`).
class ListStateView<T> extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<T> items;
  final Widget Function(BuildContext context, List<T> items) builder;
  final VoidCallback? onRetry;
  final String? loadingMessage;
  final IconData emptyIcon;
  final String emptyMessage;
  final String? emptySubMessage;
  final String? emptyActionLabel;
  final IconData? emptyActionIcon;
  final VoidCallback? onEmptyAction;

  const ListStateView({
    super.key,
    required this.isLoading,
    required this.items,
    required this.builder,
    required this.emptyMessage,
    this.error,
    this.onRetry,
    this.loadingMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptySubMessage,
    this.emptyActionLabel,
    this.emptyActionIcon,
    this.onEmptyAction,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      if (isLoading) return LoadingState(message: loadingMessage);
      final message = error;
      if (message != null && message.isNotEmpty) {
        return ErrorState(message: message, onRetry: onRetry);
      }
      return EmptyState(
        icon: emptyIcon,
        message: emptyMessage,
        subMessage: emptySubMessage,
        actionLabel: emptyActionLabel,
        actionIcon: emptyActionIcon,
        onAction: onEmptyAction,
      );
    }
    return builder(context, items);
  }
}
