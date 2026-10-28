import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';

/// Aviso de una línea "Horas en la zona del negocio: America/Caracas
/// (UTC-04:00)" (D-15). Solo se pinta si el reloj del dispositivo marca otra
/// hora que el del negocio; si no, no ocupa espacio. Se actualiza cuando la
/// sesión cambia de zona.
class BusinessTimeZoneNotice extends StatelessWidget {
  const BusinessTimeZoneNotice({super.key});

  /// Texto del aviso para la zona [zone].
  static String describe(String zone) =>
      'Horas en la zona del negocio: $zone '
      '(${formatUtcOffset(BusinessTimeZone.utcOffset(zone))})';

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SessionController>()) return _build(context);
    final session = Get.find<SessionController>();
    return Obx(() {
      session.session.value; // se repinta al cambiar la zona
      return _build(context);
    });
  }

  Widget _build(BuildContext context) {
    if (!BusinessTimeZone.differsFromDevice) return const SizedBox.shrink();
    final tone = context.tokens.tone(AppTone.info);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: tone.container,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.public, size: 16, color: tone.onContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                describe(BusinessTimeZone.current),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: tone.onContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
