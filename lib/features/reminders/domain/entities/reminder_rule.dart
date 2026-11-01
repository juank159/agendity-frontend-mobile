/// Tipo de recordatorio (backend `REMINDER_KINDS`).
enum ReminderKind {
  beforeAppointment('before_appointment'),
  maintenance('maintenance'),
  birthday('birthday'),
  winBack('win_back');

  final String apiValue;
  const ReminderKind(this.apiValue);

  /// Categoría de Meta que le corresponde: solo el de cita es `utility`.
  ReminderCategory get defaultCategory => this == beforeAppointment
      ? ReminderCategory.utility
      : ReminderCategory.marketing;

  static ReminderKind? fromApi(Object? value) {
    for (final kind in values) {
      if (kind.apiValue == value) return kind;
    }
    return null;
  }
}

/// Categoría de Meta (precio y consentimiento): `utility` o `marketing`.
enum ReminderCategory {
  utility('utility'),
  marketing('marketing');

  final String apiValue;
  const ReminderCategory(this.apiValue);

  static ReminderCategory? fromApi(Object? value) {
    for (final c in values) {
      if (c.apiValue == value) return c;
    }
    return null;
  }
}

/// Regla de recordatorio del negocio (Fase 11). Campos por tipo:
/// - cita: [minutesBefore] (5 a 10 080); puede haber varias (24 h y 30 min);
/// - mantenimiento y cumpleaños: [sendTime];
/// - "te extrañamos": [daysWithoutVisit] (7 a 730) y [sendTime].
/// De los tres últimos, una por negocio. [template] usa las variables
/// `{cliente} {negocio} {servicio} {fecha} {hora} {profesional} {link_reserva}`.
class ReminderRule {
  /// `null` = aún no creada.
  final String? id;
  final ReminderKind kind;
  final bool isActive;
  final int? minutesBefore;
  final int? daysWithoutVisit;

  /// `HH:mm` en la zona del negocio.
  final String? sendTime;
  final String template;
  final ReminderCategory category;

  /// Plantilla propia ya aprobada por Meta (opcional).
  final String? metaTemplateName;

  const ReminderRule({
    this.id,
    required this.kind,
    this.isActive = true,
    this.minutesBefore,
    this.daysWithoutVisit,
    this.sendTime,
    this.template = '',
    ReminderCategory? category,
    this.metaTemplateName,
  }) : category = category ??
            (kind == ReminderKind.beforeAppointment
                ? ReminderCategory.utility
                : ReminderCategory.marketing);

  ReminderRule copyWith({
    bool? isActive,
    int? minutesBefore,
    int? daysWithoutVisit,
    String? sendTime,
    String? template,
    ReminderCategory? category,
    String? metaTemplateName,
  }) =>
      ReminderRule(
        id: id,
        kind: kind,
        isActive: isActive ?? this.isActive,
        minutesBefore: minutesBefore ?? this.minutesBefore,
        daysWithoutVisit: daysWithoutVisit ?? this.daysWithoutVisit,
        sendTime: sendTime ?? this.sendTime,
        template: template ?? this.template,
        category: category ?? this.category,
        metaTemplateName: metaTemplateName ?? this.metaTemplateName,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderRule &&
          other.id == id &&
          other.kind == kind &&
          other.isActive == isActive &&
          other.minutesBefore == minutesBefore &&
          other.daysWithoutVisit == daysWithoutVisit &&
          other.sendTime == sendTime &&
          other.template == template &&
          other.category == category &&
          other.metaTemplateName == metaTemplateName;

  @override
  int get hashCode => Object.hash(id, kind, isActive, minutesBefore,
      daysWithoutVisit, sendTime, template, category, metaTemplateName);
}
