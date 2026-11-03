import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_conflict_ui.dart';

/// Texto simple del motivo de un choque al agendar o mover (13.05, D-25),
/// con las horas en 12 h (D-23, `formatClock`).
void main() {
  String clock(int h, [int m = 0]) => formatClock(h, m);

  group('SlotProblemText.of', () {
    test('fuera del horario del profesional: con su nombre y sus franjas', () {
      const failure = SlotUnavailableFailure(
        reason: SlotUnavailableReason.professionalOffSchedule,
        hours: [
          WorkHours(start: '09:00', end: '13:00'),
          WorkHours(start: '14:00', end: '18:00'),
        ],
      );
      expect(
          SlotProblemText.of(failure, professionalName: 'Ana'),
          'Ana no trabaja a esa hora (atiende de ${clock(9)} a ${clock(13)} '
          'y de ${clock(14)} a ${clock(18)})');
      // Sin nombre en esa capa.
      expect(SlotProblemText.of(failure),
          startsWith('La profesional no trabaja a esa hora'));
      expect(SlotProblemText.of(failure, professionalName: '  '),
          startsWith('La profesional'));
    });

    test('fuera del horario del profesional sin franjas ese día', () {
      expect(
          SlotProblemText.of(
              const SlotUnavailableFailure(
                  reason: SlotUnavailableReason.professionalOffSchedule),
              professionalName: 'Ana'),
          'Ana no trabaja ese día');
    });

    test('bloqueo, otra cita, día cerrado y apertura', () {
      expect(
          SlotProblemText.of(const SlotUnavailableFailure(
              reason: SlotUnavailableReason.timeBlock)),
          'Ese horario está bloqueado');
      expect(
          SlotProblemText.of(const SlotUnavailableFailure(
              reason: SlotUnavailableReason.appointmentOverlap)),
          'Ya hay una cita a esa hora');
      expect(
          SlotProblemText.of(const OutsideBusinessHoursFailure(
              reason: OutsideBusinessHoursReason.businessClosedDay)),
          'El negocio está cerrado ese día');
      expect(
          SlotProblemText.of(const OutsideBusinessHoursFailure(
              reason: OutsideBusinessHoursReason.outsideOpeningHours,
              hours: [WorkHours(start: '08:30', end: '12:00')])),
          'El negocio atiende de ${clock(8, 30)} a ${clock(12)}');
    });

    test(
        'OUTSIDE_OPENING_HOURS (D-26): dice las horas que manda el servidor; '
        'en la app, un solo tramo', () {
      expect(
          SlotProblemText.of(const OutsideBusinessHoursFailure(
              reason: OutsideBusinessHoursReason.outsideOpeningHours,
              hours: [WorkHours(start: '08:00', end: '19:00')])),
          'El negocio atiende de ${clock(8)} a ${clock(19)}');
      // No recorta ni junta lo que llega: si vinieran franjas, las lista.
      expect(
          SlotProblemText.of(const OutsideBusinessHoursFailure(
              reason: OutsideBusinessHoursReason.outsideOpeningHours,
              hours: [
                WorkHours(start: '08:00', end: '12:00'),
                WorkHours(start: '14:00', end: '19:00'),
              ])),
          'El negocio atiende de ${clock(8)} a ${clock(12)} y de '
          '${clock(14)} a ${clock(19)}');
    });

    test('sin motivo (backend anterior a 13.04) u otro failure → null', () {
      expect(SlotProblemText.of(const SlotUnavailableFailure()), isNull);
      expect(SlotProblemText.of(const OutsideBusinessHoursFailure()), isNull);
      expect(SlotProblemText.of(const NetworkFailure()), isNull);
    });

    test('los textos no usan 24 h', () {
      final text = SlotProblemText.of(
          const SlotUnavailableFailure(
              reason: SlotUnavailableReason.professionalOffSchedule,
              hours: [WorkHours(start: '14:00', end: '18:00')]),
          professionalName: 'Ana')!;
      expect(text, isNot(contains('14:00')));
      expect(text, contains('p.'));
    });
  });

  test('enum de motivos: valores del backend; desconocido → null', () {
    expect(SlotUnavailableReason.fromApi('TIME_BLOCK'),
        SlotUnavailableReason.timeBlock);
    expect(SlotUnavailableReason.fromApi('NUEVO'), isNull);
    expect(OutsideBusinessHoursReason.fromApi('BUSINESS_CLOSED_DAY'),
        OutsideBusinessHoursReason.businessClosedDay);
    expect(OutsideBusinessHoursReason.fromApi(null), isNull);
  });
}
