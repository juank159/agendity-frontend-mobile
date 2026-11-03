import 'package:flutter/material.dart';
import 'package:login_signup/features/appointments/presentation/controllers/agenda_slot_finder.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_form_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_hours_text.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_slot_sheet.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_form_dialog.dart';

/// Tocar una hora en la vista de día (D-25):
///
/// - **Fuera de horario o día cerrado:** no abre el formulario; explica en
///   palabras simples y ofrece "Ver horas libres".
/// - **Dentro del horario:** abre "Nueva cita" con esa hora y con un
///   profesional libre a esa hora (la empleada, solo ella).
/// - **Nadie libre (o ya pasó):** lo dice y sugiere las horas libres más
///   cercanas.
Future<void> openAgendaCell(
    BuildContext context, AppointmentsController agenda, DateTime date) async {
  if (agenda.isFinding.value) return;
  final hours = agenda.hours.value;
  final day = agenda.dayHours(date);
  final today = agenda.now();
  final minute = date.hour * 60 + date.minute;
  final who = agenda.isEmployeeView ? '' : agenda.filteredProfessionalName;

  if (!day.isOpenAt(minute)) {
    final choice = await AgendaSlotSheet.show(
      context,
      title: day.isClosed ? 'Día cerrado' : 'Fuera del horario',
      icon: Icons.storefront_rounded,
      message: AgendaHoursText.closedAt(hours, day, minute, today, who: who),
    );
    if (choice == null) return;
    // "Ver horas libres": ese día o, si no se atiende, el próximo que sí.
    final closedAllDay = day.open.isEmpty;
    final next = closedAllDay
        ? hours.nextOpening(day.day, forProfessional: true)?.$1
        : null;
    final target = next ?? day.day;
    final todayDate = DateTime(today.year, today.month, today.day);
    await startNewAppointment(agenda,
        day: target.isBefore(todayDate) ? todayDate : target);
    return;
  }

  // La celda de la hora en curso: desde el próximo cuarto de hora.
  var at = date;
  final cellEnd = date.add(const Duration(minutes: 30));
  if (at.isBefore(today)) {
    final next = DateTime(today.year, today.month, today.day, today.hour,
        (today.minute ~/ 15 + 1) * 15);
    if (next.isBefore(cellEnd) &&
        day.isOpenAt(next.hour * 60 + next.minute) &&
        next.day == date.day) {
      at = next;
    }
  }
  final isPast = at.isBefore(today);

  if (!isPast && !await agenda.canStartAppointment()) return;
  if (!context.mounted) return;
  final finder = agenda.slotFinder;
  if (finder == null) {
    if (isPast) return _explainPast(context, agenda, date, day.day);
    await startNewAppointment(agenda, at: at, checked: true);
    return;
  }
  agenda.isFinding.value = true;
  final FreeAtResult result;
  try {
    result = await finder.freeAt(at, agenda.bookingCandidates);
  } finally {
    agenda.isFinding.value = false;
  }
  if (!context.mounted) return;

  if (!isPast && (!result.checked || result.free.isNotEmpty)) {
    final first = result.free.isEmpty ? null : result.free.first;
    await startNewAppointment(
      agenda,
      at: at,
      checked: true,
      professional: first == null
          ? null
          : SelectedProfessional(id: first.id, name: first.name),
    );
    return;
  }

  final choice = await AgendaSlotSheet.show(
    context,
    title: isPast ? 'Esa hora ya pasó' : 'Sin profesionales libres',
    icon: isPast ? Icons.history_rounded : Icons.event_busy_rounded,
    message: isPast
        ? 'Las citas se agendan solo a futuro.'
        : agenda.isEmployeeView
            ? 'A las ${AgendaHoursText.clock(minute)} ya tienes la agenda '
                'ocupada.'
            : 'A las ${AgendaHoursText.clock(minute)} no hay profesionales '
                'libres.',
    detail: result.suggestions.isEmpty
        ? 'Toca "Ver horas libres" para elegir otro día u otra hora.'
        : 'Elige una de las horas libres más cercanas o toca "Ver horas '
            'libres".',
    suggestions: result.suggestions,
    showProfessional: !agenda.isEmployeeView,
  );
  if (choice == null) return;
  final suggestion = choice.suggestion;
  if (suggestion == null) {
    await startNewAppointment(agenda, day: day.day, checked: !isPast);
    return;
  }
  await startNewAppointment(
    agenda,
    at: suggestion.at,
    checked: !isPast,
    professional: SelectedProfessional(
        id: suggestion.professional.id, name: suggestion.professional.name),
  );
}

/// Sin buscador (p. ej. en pruebas): la hora pasada solo se explica.
Future<void> _explainPast(BuildContext context, AppointmentsController agenda,
    DateTime date, DateTime day) async {
  final choice = await AgendaSlotSheet.show(
    context,
    title: 'Esa hora ya pasó',
    icon: Icons.history_rounded,
    message: 'Las citas se agendan solo a futuro.',
    detail: 'Toca "Ver horas libres" para elegir otra hora.',
  );
  if (choice != null) await startNewAppointment(agenda, day: day);
}
