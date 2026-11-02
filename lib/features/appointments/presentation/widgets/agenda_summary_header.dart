import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/presentation/controllers/agenda_summary_controller.dart';
import 'package:login_signup/shared/widgets/app_card.dart';

/// Cabecera de la agenda (12.04): "Hola, {nombre}", la fecha del negocio y
/// las tarjetas "Citas hoy", "Por cobrar" y, solo el Owner, "Ingresos hoy".
/// Se pliega a una línea para dejarle alto al calendario. Los números los
/// calcula `AgendaSummaryController`; este widget solo los pinta. Sin el
/// controller registrado no ocupa espacio.
class AgendaSummaryHeader extends StatelessWidget {
  const AgendaSummaryHeader({super.key});

  /// "Lunes, 2 de noviembre".
  static String dateLabel(DateTime day) {
    final text = DateFormat("EEEE, d 'de' MMMM", 'es').format(day);
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AgendaSummaryController>()) {
      return const SizedBox.shrink();
    }
    final c = Get.find<AgendaSummaryController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Obx(() {
      final expanded = c.expanded.value;
      final summary = c.summary.value;
      final loaded = c.isLoaded.value;
      final date = dateLabel(c.today);
      final subtitle = expanded || !loaded
          ? date
          : '$date · ${formatCount(summary.appointments, 'cita', 'citas')}';
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 4, 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.greeting,
                        key: const Key('summary-greeting'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        subtitle,
                        key: const Key('summary-date'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('summary-toggle'),
                  tooltip: expanded ? 'Ocultar resumen' : 'Mostrar resumen',
                  icon: AnimatedRotation(
                    turns: expanded ? 0 : 0.5,
                    duration: AppMotion.of(context),
                    curve: AppMotion.curve,
                    child: const Icon(Icons.expand_less_rounded),
                  ),
                  onPressed: c.toggleExpanded,
                ),
              ],
            ),
            AnimatedSize(
              duration: AppMotion.of(context),
              curve: AppMotion.curve,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding:
                          const EdgeInsets.only(top: 2, right: 12, bottom: 4),
                      child: _Stats(
                        summary: summary,
                        loaded: loaded,
                        showsIncome: c.showsIncome,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      );
    });
  }
}

class _Stats extends StatelessWidget {
  final AgendaSummary summary;
  final bool loaded;
  final bool showsIncome;

  const _Stats({
    required this.summary,
    required this.loaded,
    required this.showsIncome,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    String value(String text) => loaded ? text : '—';
    final tiles = <Widget>[
      _StatCard(
        key: const Key('summary-appointments'),
        icon: Icons.event_available_rounded,
        label: 'Citas hoy',
        value: value('${summary.appointments}'),
        highlighted: true,
      ),
      _StatCard(
        key: const Key('summary-to-collect'),
        icon: Icons.hourglass_bottom_rounded,
        label: 'Por cobrar',
        value: value(formatCop(summary.toCollect)),
        tone: tokens.warning,
      ),
      if (showsIncome)
        _StatCard(
          key: const Key('summary-income'),
          icon: Icons.trending_up_rounded,
          label: 'Ingresos hoy',
          value: value(formatCop(summary.collected)),
          tone: tokens.success,
        ),
    ];
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

/// Tarjeta pequeña con ícono, cifra y etiqueta. [highlighted] = con el
/// degradado de la paleta (la principal).
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlighted;
  final ToneColors? tone;

  const _StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final foreground = highlighted ? tokens.onGradient : scheme.onSurface;
    final muted = highlighted
        ? tokens.onGradient.withValues(alpha: 0.85)
        : scheme.onSurfaceVariant;
    final iconColor =
        highlighted ? tokens.onGradient : (tone?.color ?? scheme.primary);
    final iconBackground = highlighted
        ? tokens.onGradient.withValues(alpha: 0.18)
        : (tone?.container ?? scheme.primaryContainer);

    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
        depth: highlighted ? 2 : 1,
        gradient: highlighted ? tokens.primaryGradient : null,
        tint: highlighted ? tokens.gradientEnd : null,
        borderRadius: BorderRadius.circular(AppRadii.field + 2),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(
                              color: foreground, fontWeight: FontWeight.w800)
                          .tabular,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
