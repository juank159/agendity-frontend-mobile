import 'package:get/get.dart';
import '../../domain/entities/stats_range.dart';

/// Base de las pantallas de estadísticas: el período elegido (días del
/// negocio, ambos incluidos; por defecto hoy) y la recarga al cambiarlo.
abstract class StatsPeriodController extends GetxController {
  final DateTime Function() now;

  StatsPeriodController({DateTime Function()? clock})
      : now = clock ?? DateTime.now;

  late final Rx<StatsRange> range = StatsRange.day(today).obs;

  /// Medianoche local de hoy.
  DateTime get today {
    final current = now();
    return DateTime(current.year, current.month, current.day);
  }

  /// Cambia el período y vuelve a cargar con él. Un rango invertido lo
  /// rechazan los use cases (`InvalidStatsQueryFailure`).
  void setRange(StatsRange value) {
    if (value == range.value) return;
    range.value = value;
    onRangeChanged();
  }

  /// Descarta los datos del período anterior y carga los del nuevo.
  void onRangeChanged();
}
