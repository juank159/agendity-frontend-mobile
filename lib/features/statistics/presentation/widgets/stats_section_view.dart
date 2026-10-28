import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/empty_state.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import '../controllers/stats_section.dart';

/// Pinta un bloque que no es una lista (resumen, comparación, mis
/// estadísticas): carga, error, vacío o el contenido. Las listas usan
/// `ListStateView`.
///
/// Con datos ya cargados, una recarga o un error no los ocultan (el
/// controller avisa con `AppSnackbar`).
class StatsSectionView<T extends Object> extends StatelessWidget {
  final StatsSection<T> section;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final IconData emptyIcon;
  final String emptyMessage;
  final String? emptySubMessage;
  final String? loadingMessage;

  const StatsSectionView({
    super.key,
    required this.section,
    required this.onRetry,
    required this.builder,
    this.isEmpty,
    this.emptyIcon = Icons.insights_outlined,
    this.emptyMessage = 'Sin pagos en este período',
    this.emptySubMessage,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = section.data.value;
      if (data == null) {
        final error = section.error.value;
        if (error != null && !section.isLoading.value) {
          final isFinal = section.errorIsFinal.value;
          return ErrorState(
            title: isFinal ? 'Sin acceso' : 'No se pudo cargar',
            icon: isFinal ? Icons.lock_outline : Icons.error_outline,
            message: error,
            onRetry: isFinal ? null : onRetry,
          );
        }
        return LoadingState(message: loadingMessage);
      }
      if (isEmpty?.call(data) ?? false) {
        return EmptyState(
          icon: emptyIcon,
          message: emptyMessage,
          subMessage: emptySubMessage,
        );
      }
      return builder(context, data);
    });
  }
}
