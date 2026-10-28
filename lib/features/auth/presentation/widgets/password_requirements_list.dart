import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/auth/presentation/controllers/password_policy.dart';

/// Lista de requisitos de la contraseña con su estado (registro y cambio de
/// contraseña). No se muestra hasta que se empieza a escribir.
class PasswordRequirementsList extends StatelessWidget {
  final RxMap<PasswordRequirement, bool> checks;

  const PasswordRequirementsList({super.key, required this.checks});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Obx(() {
      if (checks.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Requisitos de la contraseña',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final requirement in PasswordRequirement.values)
              _RequirementRow(
                label: requirement.label,
                met: checks[requirement] ?? false,
                color: (checks[requirement] ?? false)
                    ? tokens.success.color
                    : scheme.error,
              ),
          ],
        ),
      );
    });
  }
}

class _RequirementRow extends StatelessWidget {
  final String label;
  final bool met;
  final Color color;

  const _RequirementRow({
    required this.label,
    required this.met,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle : Icons.cancel, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }
}
