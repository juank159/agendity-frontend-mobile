import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/widgets/time_of_day_button.dart';

/// Una franja de horas de un día: tarjeta con la barra en degradado, los dos
/// botones de hora en 12 h ([TimeOfDayButton] → `AppTimePicker`) y, si hay
/// [onRemove], el botón de quitarla. La usan el horario de apertura de "Mi
/// negocio" ("Abre"/"Cierra") y el horario de los profesionales
/// ("Inicio"/"Fin"); cada uno decide sus etiquetas y su `Semantics` (los
/// integration_test los buscan por ese texto).
class TimeRangeCard extends StatelessWidget {
  final String startLabel;
  final String endLabel;

  /// Horas en `HH:mm`.
  final String start;
  final String end;

  /// Etiqueta accesible de cada botón (también el título del selector).
  final String startSemantics;
  final String endSemantics;

  final ValueChanged<String> onStart;
  final ValueChanged<String> onEnd;

  /// Quitar la franja; `null` = sin botón.
  final VoidCallback? onRemove;
  final String? removeTooltip;
  final Key? removeKey;

  /// Borde en rojo: la franja está mal (fin antes del inicio o se cruza con
  /// otra). El texto del problema lo pone quien la usa.
  final bool invalid;

  const TimeRangeCard({
    super.key,
    required this.startLabel,
    required this.endLabel,
    required this.start,
    required this.end,
    required this.startSemantics,
    required this.endSemantics,
    required this.onStart,
    required this.onEnd,
    this.onRemove,
    this.removeTooltip,
    this.removeKey,
    this.invalid = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Container(
      margin: const EdgeInsets.only(top: 6, right: 6),
      padding: EdgeInsets.fromLTRB(8, 8, onRemove == null ? 8 : 2, 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadii.fieldRadius,
        border: Border.all(
            color: invalid
                ? scheme.error
                : scheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: tokens.elevation1(),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              gradient: tokens.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TimeOfDayButton(
                  label: startLabel,
                  value: start,
                  semantics: startSemantics,
                  onPicked: onStart,
                ),
                TimeOfDayButton(
                  label: endLabel,
                  value: end,
                  semantics: endSemantics,
                  onPicked: onEnd,
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              key: removeKey,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              color: scheme.error,
              tooltip: removeTooltip,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
