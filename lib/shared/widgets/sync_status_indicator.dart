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
        icon = Icons.sync_problem_rounded;
        color = tokens.error.color;
        badge = status.needsAttention;
        tooltip = '${status.needsAttention} cambios requieren atención';
      } else if (!status.online) {
        icon = Icons.cloud_off_rounded;
        color = tokens.warning.color;
        badge = status.pending;
        tooltip = status.pending > 0
            ? 'Sin conexión · ${status.pending} pendientes'
            : 'Sin conexión';
      } else if (status.syncing) {
        icon = Icons.sync_rounded;
        tooltip = 'Sincronizando';
      } else if (status.pending > 0) {
        icon = Icons.cloud_upload_rounded;
        badge = status.pending;
        tooltip = '${status.pending} pendientes de enviar';
      } else {
        icon = Icons.cloud_done_rounded;
        color = scheme.onSurfaceVariant;
        tooltip = 'Todo sincronizado';
      }
      final iconWidget = Icon(icon, key: ValueKey(icon), color: color);
      return IconButton(
        key: const Key('sync-status'),
        tooltip: tooltip,
        onPressed: () => Get.toNamed(GetRoutes.syncPending),
        icon: Badge(
          isLabelVisible: badge > 0,
          backgroundColor: color ?? scheme.primary,
          textColor: color == null ? scheme.onPrimary : scheme.surface,
          label: Text('$badge'),
          child: AnimatedSwitcher(
            duration: AppMotion.of(context),
            switchInCurve: AppMotion.curve,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            // Sincronizando: el ícono gira.
            child: status.syncing && AppMotion.enabled(context)
                ? _Spinning(key: const ValueKey('syncing'), child: iconWidget)
                : iconWidget,
          ),
        ),
      );
    });
  }
}

/// Gira [child] sin parar mientras está en pantalla (el ícono de
/// "Sincronizando").
class _Spinning extends StatefulWidget {
  final Widget child;

  const _Spinning({super.key, required this.child});

  @override
  State<_Spinning> createState() => _SpinningState();
}

class _SpinningState extends State<_Spinning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turns = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _turns, child: widget.child);
}
