import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import '../../domain/entities/stats_range.dart';

/// Períodos rápidos del selector. Todos terminan hoy (incluido).
enum StatsPeriodPreset {
  today('Hoy'),
  thisWeek('Esta semana'),
  thisMonth('Este mes'),
  last30Days('Últimos 30 días'),
  last90Days('Últimos 90 días');

  final String label;
  const StatsPeriodPreset(this.label);

  /// Rango del período respecto a [today] (hoy en el calendario del negocio).
  StatsRange rangeFor(DateTime today) {
    switch (this) {
      case StatsPeriodPreset.today:
        return StatsRange.day(today);
      case StatsPeriodPreset.thisWeek:
        return StatsRange(
            start: DateTime(today.year, today.month,
                today.day - (today.weekday - DateTime.monday)),
            end: today);
      case StatsPeriodPreset.thisMonth:
        return StatsRange(start: DateTime(today.year, today.month), end: today);
      case StatsPeriodPreset.last30Days:
        return StatsRange(
            start: DateTime(today.year, today.month, today.day - 29),
            end: today);
      case StatsPeriodPreset.last90Days:
        return StatsRange(
            start: DateTime(today.year, today.month, today.day - 89),
            end: today);
    }
  }

  /// Período rápido que coincide con [range], o `null` si es a medida.
  static StatsPeriodPreset? matching(StatsRange range, DateTime today) {
    for (final preset in values) {
      if (preset.rangeFor(today) == range) return preset;
    }
    return null;
  }
}

/// Período de las estadísticas: texto del rango, accesos rápidos y
/// calendario para un rango a medida.
class DateRangeSelector extends StatelessWidget {
  final StatsRange selected;
  final DateTime today;
  final ValueChanged<StatsRange> onChanged;

  const DateRangeSelector({
    super.key,
    required this.selected,
    required this.today,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = StatsPeriodPreset.matching(selected, today);
    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      depth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: AppRadii.chipRadius,
                ),
                child: Icon(Icons.calendar_month_rounded,
                    size: 18, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Período',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    Text(
                      _describe(selected),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)
                          .tabular,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.date_range_rounded),
                tooltip: 'Elegir fechas',
                onPressed: () => _pickRange(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in StatsPeriodPreset.values)
                ChoiceChip(
                  showCheckmark: false,
                  label: Text(preset.label),
                  selected: preset == active,
                  onSelected: (_) {
                    if (preset != active) onChanged(preset.rangeFor(today));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _describe(StatsRange range) {
    final start = formatDate(range.start);
    final end = formatDate(range.end);
    return start == end ? start : 'Del $start al $end';
  }

  Future<void> _pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      currentDate: today,
      initialDateRange: DateTimeRange(
        start: selected.start.isAfter(today) ? today : selected.start,
        end: selected.end.isAfter(today) ? today : selected.end,
      ),
      helpText: 'Elegir período',
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null) return;
    onChanged(StatsRange(start: picked.start, end: picked.end));
  }
}
