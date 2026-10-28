import 'package:login_signup/core/errors/failures.dart';

/// Consulta de estadísticas inválida, detectada antes de llamar al backend
/// (la producen los use cases).
class InvalidStatsQueryFailure extends ValidationFailure {
  static const invalidRangeMessage =
      'La fecha de inicio no puede ser posterior a la fecha de fin';
  static const invalidLimitMessage = 'El límite debe ser mayor que cero';

  const InvalidStatsQueryFailure({required String super.message});
}
