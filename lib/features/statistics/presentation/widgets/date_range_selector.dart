import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeSelector extends StatelessWidget {
  final DateTimeRange selectedDateRange;
  final Function(DateTimeRange) onDateRangeSelected;
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  DateRangeSelector({
    Key? key,
    required this.selectedDateRange,
    required this.onDateRangeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Período seleccionado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Del ${dateFormat.format(selectedDateRange.start)} al ${dateFormat.format(selectedDateRange.end)}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () => _selectDateRange(context),
                  tooltip: 'Cambiar período',
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickSelectButton(
                    context,
                    'Hoy',
                    () => _selectToday(),
                  ),
                  _buildQuickSelectButton(
                    context,
                    'Esta semana',
                    () => _selectThisWeek(),
                  ),
                  _buildQuickSelectButton(
                    context,
                    'Este mes',
                    () => _selectThisMonth(),
                  ),
                  _buildQuickSelectButton(
                    context,
                    'Últimos 30 días',
                    () => _selectLast30Days(),
                  ),
                  _buildQuickSelectButton(
                    context,
                    'Últimos 90 días',
                    () => _selectLast90Days(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      helpText: 'Seleccionar período',
    );

    if (picked != null && picked != selectedDateRange) {
      onDateRangeSelected(picked);
    }
  }

  void _selectToday() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    onDateRangeSelected(DateTimeRange(start: startOfDay, end: endOfDay));
  }

  void _selectThisWeek() {
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek =
        DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
    final endOfWeek = DateTime(now.year, now.month, now.day, 23, 59, 59);
    onDateRangeSelected(DateTimeRange(start: startOfWeek, end: endOfWeek));
  }

  void _selectThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month, now.day, 23, 59, 59);
    onDateRangeSelected(DateTimeRange(start: startOfMonth, end: endOfMonth));
  }

  void _selectLast30Days() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final startDate =
        DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    onDateRangeSelected(DateTimeRange(start: startDate, end: endDate));
  }

  void _selectLast90Days() {
    final now = DateTime.now();
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));
    final startDate =
        DateTime(ninetyDaysAgo.year, ninetyDaysAgo.month, ninetyDaysAgo.day);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    onDateRangeSelected(DateTimeRange(start: startDate, end: endDate));
  }
}
