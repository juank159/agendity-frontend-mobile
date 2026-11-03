import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/features/appointments/presentation/controllers/agenda_slot_finder.dart';
import 'package:login_signup/shared/widgets/app_sheet.dart';

/// Lo que eligió el usuario en [AgendaSlotSheet]: "Ver horas libres"
/// ([suggestion] `null`) o una de las horas sugeridas.
class AgendaSheetChoice {
  final AgendaSuggestion? suggestion;

  const AgendaSheetChoice.freeHours() : suggestion = null;
  const AgendaSheetChoice.suggestion(AgendaSuggestion this.suggestion);
}

/// Explicación al tocar en la agenda una hora que no se puede reservar
/// (D-25): fuera de horario, día cerrado o sin profesionales libres. En
/// palabras simples, con las horas libres más cercanas como chips y "Ver
/// horas libres" (abre "Nueva cita" sin hora elegida). Nunca abre el
/// formulario por su cuenta.
class AgendaSlotSheet extends StatelessWidget {
  final String message;
  final String? detail;
  final List<AgendaSuggestion> suggestions;

  /// Muestra quién está libre en cada hora sugerida (el Owner; la empleada
  /// solo se ve a sí misma).
  final bool showProfessional;

  const AgendaSlotSheet({
    super.key,
    required this.message,
    this.detail,
    this.suggestions = const [],
    this.showProfessional = true,
  });

  static const messageKey = Key('agenda-sheet-message');
  static const freeHoursKey = Key('agenda-free-hours');
  static const dismissKey = Key('agenda-sheet-dismiss');
  static Key suggestionKey(DateTime at) =>
      ValueKey('agenda-suggestion-${at.toIso8601String()}');

  static Future<AgendaSheetChoice?> show(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String message,
    String? detail,
    List<AgendaSuggestion> suggestions = const [],
    bool showProfessional = true,
  }) =>
      AppSheet.show<AgendaSheetChoice>(
        context,
        title: title,
        icon: icon,
        builder: (_) => AgendaSlotSheet(
          message: message,
          detail: detail,
          suggestions: suggestions,
          showProfessional: showProfessional,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final extra = detail;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message,
              key: messageKey,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.45)),
          if (extra != null) ...[
            const SizedBox(height: 8),
            Text(extra,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
          ],
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Horas libres más cercanas',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in suggestions)
                  ActionChip(
                    key: suggestionKey(s.at),
                    avatar: Icon(Icons.schedule_rounded,
                        size: 18, color: scheme.primary),
                    label: Text(
                      showProfessional
                          ? '${formatTime(s.at)} · ${s.professional.name}'
                          : formatTime(s.at),
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700)
                          .tabular,
                    ),
                    onPressed: () => Navigator.of(context)
                        .pop(AgendaSheetChoice.suggestion(s)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          // Botones apilados: "Ver horas libres" cabe entero en un teléfono.
          AppGradientButton(
            key: freeHoursKey,
            label: 'Ver horas libres',
            icon: Icons.event_available_rounded,
            expand: true,
            onPressed: () =>
                Navigator.of(context).pop(const AgendaSheetChoice.freeHours()),
          ),
          const SizedBox(height: 4),
          TextButton(
            key: dismissKey,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
