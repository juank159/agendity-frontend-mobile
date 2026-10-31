import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';

/// Indicador discreto de la sincronización (10.03) para la barra: sin
/// conexión, sincronizando, N pendientes o "requiere atención". Abre
/// "Pendientes".
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SyncController>()) return const SizedBox.shrink();
    final sync = Get.find<SyncController>();
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final status = sync.status.value;
      final IconData icon;
      final String tooltip;
      Color? color;
      int badge = 0;
      if (status.needsAttention > 0) {
        icon = Icons.sync_problem;
        color = tokens.error.color;
        badge = status.needsAttention;
        tooltip = '${status.needsAttention} cambios requieren atención';
      } else if (!status.online) {
        icon = Icons.cloud_off_outlined;
        color = tokens.warning.color;
        badge = status.pending;
        tooltip = status.pending > 0
            ? 'Sin conexión · ${status.pending} pendientes'
            : 'Sin conexión';
      } else if (status.syncing) {
        icon = Icons.sync;
        tooltip = 'Sincronizando';
      } else if (status.pending > 0) {
        icon = Icons.cloud_upload_outlined;
        badge = status.pending;
        tooltip = '${status.pending} pendientes de enviar';
      } else {
        icon = Icons.cloud_done_outlined;
        color = scheme.onSurfaceVariant;
        tooltip = 'Todo sincronizado';
      }
      return IconButton(
        key: const Key('sync-status'),
        tooltip: tooltip,
        onPressed: () => Get.toNamed(GetRoutes.syncPending),
        icon: Badge(
          isLabelVisible: badge > 0,
          label: Text('$badge'),
          child: Icon(icon, color: color),
        ),
      );
    });
  }
}
