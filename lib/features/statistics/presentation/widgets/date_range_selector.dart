import 'package:flutter/material.dart';
import 'package:login_signup/core/utils/formatters.dart';
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
    final active = StatsPeriodPreset.matching(selected, today);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Período', style: theme.textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _describe(selected),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.date_range),
                  tooltip: 'Elegir fechas',
                  onPressed: () => _pickRange(context),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final preset in StatsPeriodPreset.values)
                  ChoiceChip(
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
