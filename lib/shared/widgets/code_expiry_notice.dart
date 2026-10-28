import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';

/// "El código vence en mm:ss" (tono de advertencia del tema). Se pinta con
/// el `formatted` de un `CodeCountdown` activo.
class CodeExpiryNotice extends StatelessWidget {
  final String remaining;

  const CodeExpiryNotice({super.key, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final warning = context.tokens.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: warning.container,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, color: warning.color, size: 18),
          const SizedBox(width: 8),
          Text(
            'El código vence en $remaining',
            style: TextStyle(
              color: warning.onContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
