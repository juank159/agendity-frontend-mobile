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
      Widget item(String text, IconData icon, String route, Key key) => InkWell(
            key: key,
            borderRadius: AppRadii.fieldRadius,
            onTap: () async {
              await Get.toNamed(route);
              await c.load();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: tone.color.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: tone.onContainer),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(text,
                        style: TextStyle(
                            color: tone.onContainer,
                            fontWeight: FontWeight.w700)),
                  ),
                  Icon(Icons.chevron_right_rounded, color: tone.onContainer),
                ],
              ),
            ),
          );
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadii.fieldRadius,
            boxShadow: context.tokens.elevation1(tint: tone.color),
          ),
          child: Material(
            color: tone.container,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.fieldRadius,
              side: BorderSide(color: tone.color.withValues(alpha: 0.35)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (reschedule > 0)
                  item(
                      formatCount(
                          reschedule, 'cita por mover', 'citas por mover'),
                      Icons.event_repeat_rounded,
                      GetRoutes.appointmentsToReschedule,
                      const Key('banner-reschedule')),
                if (review > 0)
                  item(
                      formatCount(
                          review, 'pago por revisar', 'pagos por revisar'),
                      Icons.flag_rounded,
                      GetRoutes.paymentsReview,
                      const Key('banner-review')),
              ],
            ),
          ),
        ),
      );
    });
  }
}
