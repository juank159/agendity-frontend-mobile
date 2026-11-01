import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';

/// Reglas del backend para recordatorios (`reminder.dto.ts`,
/// `reminder-template.ts`), comprobadas antes de enviar.
abstract final class ReminderRules {
  static const minMinutesBefore = 5;
  static const maxMinutesBefore = 7 * 24 * 60;
  static const minDaysWithoutVisit = 7;
  static const maxDaysWithoutVisit = 730;
  static const templateMaxLength = 1024;

  /// Variables que acepta una plantilla.
  static const templateVariables = [
    'cliente',
    'negocio',
    'servicio',
    'fecha',
    'hora',
    'profesional',
    'link_reserva',
  ];

  static final _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  static final _metaName = RegExp(r'^[a-z0-9_]{1,100}$');
  static final _variable = RegExp(r'\{([a-z_]+)\}');

  static bool isTime(String? value) => value != null && _hhmm.hasMatch(value);

  /// Problemas de la plantilla (vacío si vale). Una plantilla vacía en una
  /// regla vale: el backend pone la de su tipo.
  static List<String> templateProblems(String template,
      {bool allowEmpty = false}) {
    if (template.trim().isEmpty) {
      return allowEmpty ? const [] : ['La plantilla no puede estar vacía'];
    }
    final unknown = {
      for (final m in _variable.allMatches(template))
        if (!templateVariables.contains(m.group(1))) '{${m.group(1)}}',
    };
    return [
      if (template.length > templateMaxLength)
        'La plantilla admite hasta $templateMaxLength caracteres',
      if (unknown.isNotEmpty)
        'Variables desconocidas: ${unknown.join(', ')}. Usa '
            '${templateVariables.map((v) => '{$v}').join(', ')}',
    ];
  }

  /// Problemas de la regla (vacío si vale).
  static List<String> check(ReminderRule rule) => [
        if (rule.kind == ReminderKind.beforeAppointment &&
            (rule.minutesBefore == null ||
                rule.minutesBefore! < minMinutesBefore ||
                rule.minutesBefore! > maxMinutesBefore))
          'Los minutos antes de la cita van de $minMinutesBefore a '
              '$maxMinutesBefore (una semana)',
        if (rule.kind == ReminderKind.winBack &&
            (rule.daysWithoutVisit == null ||
                rule.daysWithoutVisit! < minDaysWithoutVisit ||
                rule.daysWithoutVisit! > maxDaysWithoutVisit))
          'Los días sin visitar van de $minDaysWithoutVisit a '
              '$maxDaysWithoutVisit',
        if (rule.kind != ReminderKind.beforeAppointment &&
            rule.sendTime != null &&
            !isTime(rule.sendTime))
          'La hora de envío debe tener el formato HH:mm',
        if (rule.kind != ReminderKind.beforeAppointment &&
            rule.category == ReminderCategory.utility)
          'Cumpleaños, mantenimiento y "te extrañamos" son de categoría marketing',
        if (rule.metaTemplateName != null &&
            !_metaName.hasMatch(rule.metaTemplateName!))
          'El nombre de la plantilla de Meta solo admite minúsculas, números '
              'y guion bajo',
        ...templateProblems(rule.template, allowEmpty: true),
      ];
}
