import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:intl/intl.dart';

class DateRangeSelector extends StatefulWidget {
  final DateTimeRange selectedDateRange;
  final Function(DateTimeRange) onDateRangeSelected;

  const DateRangeSelector({
    Key? key,
    required this.selectedDateRange,
    required this.onDateRangeSelected,
  }) : super(key: key);

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  final Rx<String> selectedQuickOptionName = Rx<String>('');
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _determineSelectedOption();
  }

  @override
  void didUpdateWidget(DateRangeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDateRange != widget.selectedDateRange) {
      _determineSelectedOption();
    }
  }

  // Determina qué opción debería estar seleccionada basándose en el rango de fechas actual
  void _determineSelectedOption() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = widget.selectedDateRange.start;
    final endDate = widget.selectedDateRange.end;

    // Comprueba si el rango coincide con alguna de las opciones predefinidas
    if (startDate.year == today.year &&
        startDate.month == today.month &&
        startDate.day == today.day &&
        endDate.year == today.year &&
        endDate.month == today.month &&
        endDate.day == today.day) {
      selectedQuickOptionName.value = 'Hoy';
    } else if (_isThisWeek(startDate, endDate)) {
      selectedQuickOptionName.value = 'Esta semana';
    } else if (_isThisMonth(startDate, endDate)) {
      selectedQuickOptionName.value = 'Este mes';
    } else if (_isLast30Days(startDate, endDate)) {
      selectedQuickOptionName.value = 'Últimos 30 días';
    } else if (_isLast90Days(startDate, endDate)) {
      selectedQuickOptionName.value = 'Últimos 90 días';
    } else {
      selectedQuickOptionName.value = '';
    }

    // Si es la primera vez y no se ha determinado ninguna opción, selecciona "Hoy"
    if (!isInitialized) {
      isInitialized = true;
      if (selectedQuickOptionName.value.isEmpty) {
        // Solo llamamos a _selectToday si no se ha determinado una opción
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _selectToday();
        });
      }
    }
  }

  // Funciones auxiliares para determinar si el rango coincide con alguna opción
  bool _isThisWeek(DateTime start, DateTime end) {
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek =
        DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
    final endOfWeek = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return start.isAtSameMomentAs(startOfWeek) &&
        end.isAtSameMomentAs(endOfWeek);
  }

  bool _isThisMonth(DateTime start, DateTime end) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return start.isAtSameMomentAs(startOfMonth) &&
        end.isAtSameMomentAs(endOfMonth);
  }

  bool _isLast30Days(DateTime start, DateTime end) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final startDate =
        DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return start.isAtSameMomentAs(startDate) && end.isAtSameMomentAs(endDate);
  }

  bool _isLast90Days(DateTime start, DateTime end) {
    final now = DateTime.now();
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));
    final startDate =
        DateTime(ninetyDaysAgo.year, ninetyDaysAgo.month, ninetyDaysAgo.day);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return start.isAtSameMomentAs(startDate) && end.isAtSameMomentAs(endDate);
  }

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
                    'Del ${dateFormat.format(widget.selectedDateRange.start)} al ${dateFormat.format(widget.selectedDateRange.end)}',
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
    return Obx(() {
      final isSelected = selectedQuickOptionName.value == label;

      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: OutlinedButton(
          onPressed: () {
            // Si ya está seleccionado, no hacemos nada para evitar peticiones innecesarias
            if (selectedQuickOptionName.value == label) return;

            selectedQuickOptionName.value = label;
            onPressed();
          },
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.2)
                : null,
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Theme.of(context).primaryColor : null,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
        ),
      );
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: widget.selectedDateRange,
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      helpText: 'Seleccionar período',
    );

    if (picked != null && picked != widget.selectedDateRange) {
      selectedQuickOptionName.value = '';
      widget.onDateRangeSelected(picked);
    }
  }

  void _selectToday() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    selectedQuickOptionName.value = 'Hoy';
    widget.onDateRangeSelected(DateTimeRange(start: startOfDay, end: endOfDay));
  }

  void _selectThisWeek() {
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek =
        DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
    final endOfWeek = DateTime(now.year, now.month, now.day, 23, 59, 59);

    selectedQuickOptionName.value = 'Esta semana';
    widget
        .onDateRangeSelected(DateTimeRange(start: startOfWeek, end: endOfWeek));
  }

  void _selectThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month, now.day, 23, 59, 59);

    selectedQuickOptionName.value = 'Este mes';
    widget.onDateRangeSelected(
        DateTimeRange(start: startOfMonth, end: endOfMonth));
  }

  void _selectLast30Days() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final startDate =
        DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    selectedQuickOptionName.value = 'Últimos 30 días';
    widget.onDateRangeSelected(DateTimeRange(start: startDate, end: endDate));
  }

  void _selectLast90Days() {
    final now = DateTime.now();
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));
    final startDate =
        DateTime(ninetyDaysAgo.year, ninetyDaysAgo.month, ninetyDaysAgo.day);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    selectedQuickOptionName.value = 'Últimos 90 días';
    widget.onDateRangeSelected(DateTimeRange(start: startDate, end: endDate));
  }
}
