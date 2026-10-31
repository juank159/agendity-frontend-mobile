import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/presentation/controllers/sync_attention_controller.dart';

/// Aviso de la agenda con lo que la sincronización dejó para resolver
/// (10.03): "N citas por mover" y, al Owner, "N pagos por revisar". No ocupa
/// espacio si no hay nada.
class SyncAttentionBanner extends StatelessWidget {
  const SyncAttentionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SyncAttentionController>()) {
      return const SizedBox.shrink();
    }
    final c = Get.find<SyncAttentionController>();
    final tone = context.tokens.warning;
    return Obx(() {
      final reschedule = c.toRescheduleCount.value;
      final review = c.inReviewCount.value;
      if (reschedule == 0 && review == 0) return const SizedBox.shrink();
      Widget item(String text, IconData icon, String route, Key key) =>
          InkWell(
            key: key,
            onTap: () async {
              await Get.toNamed(route);
              await c.load();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: tone.onContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(text,
                        style: TextStyle(
                            color: tone.onContainer,
                            fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.chevron_right, color: tone.onContainer),
                ],
              ),
            ),
          );
      return Material(
        color: tone.container,
        child: Column(
          children: [
            if (reschedule > 0)
              item(formatCount(reschedule, 'cita por mover', 'citas por mover'),
                  Icons.event_repeat, GetRoutes.appointmentsToReschedule,
                  const Key('banner-reschedule')),
            if (review > 0)
              item(
                  formatCount(review, 'pago por revisar', 'pagos por revisar'),
                  Icons.flag_outlined,
                  GetRoutes.paymentsReview,
                  const Key('banner-review')),
          ],
        ),
      );
    });
  }
}
