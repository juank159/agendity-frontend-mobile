import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/role_entity.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/common/entities/work_hours.dart';

/// Profesional tal como lo devuelve `/auth/employee*` (usuario sin secretos +
/// `roles: [{name}]`).
///
/// Las rutas no traen todas lo mismo:
/// - `GET /auth/employees`: `isOwner`, `services` (`{id, name,
///   commissionPercentage, customPrice}`), `schedule_slots` (13.04: `{monday:
///   [{start, end}, …]}`, todas las franjas) y `schedule` (formato anterior,
///   solo la primera franja: `{monday: {start, end}}`); `GET
///   /auth/employee/:id` y `PATCH`, igual sin `isOwner`.
/// - `GET /auth/employees/deleted` y la base local: las relaciones crudas
///   `userServices` (`{serviceId, commissionPercentage, customPrice, service:
///   {name}}`) y `schedules` (`{day_of_week, start_time, end_time,
///   is_available}`, una fila por franja).
/// - alta y cambio de estado: sin servicios.
///
/// Los `decimal` de Postgres llegan como texto y las horas como `"09:00:00"`.
class EmployeeModel {
  final String id;
  final String name;
  final String lastname;
  final String email;
  final String phone;
  final String? image;
  final bool isActive;
  final bool isEmailVerified;
  final bool isOwner;
  final List<String> roles;
  final Map<String, ServiceAssignment> services;
  final Map<String, List<WorkHours>> schedule;

  /// `commission_percentage` (decimal como texto; 8.02). Sin él, 0.
  final double commissionPercentage;
  final DateTime? deletedAt;
  final String? deletionReason;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.lastname,
    required this.email,
    this.phone = '',
    this.image,
    required this.isActive,
    this.isEmailVerified = false,
    this.isOwner = false,
    this.roles = const [],
    this.services = const {},
    this.schedule = const {},
    this.commissionPercentage = 0,
    this.deletedAt,
    this.deletionReason,
  });

  static const _dayOfWeek = {
    1: 'monday',
    2: 'tuesday',
    3: 'wednesday',
    4: 'thursday',
    5: 'friday',
    6: 'saturday',
    7: 'sunday',
  };

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final roles = [
      for (final role in JsonRead.asMapList(json['roles']))
        if (JsonRead.asOptionalString(role['name']) case final name?) name,
    ];
    return EmployeeModel(
      id: JsonRead.asString(json['id']),
      name: JsonRead.asString(json['name']),
      lastname: JsonRead.asString(json['lastname']),
      email: JsonRead.asString(json['email']),
      phone: JsonRead.asString(json['phone']),
      image: JsonRead.asOptionalString(json['image']),
      isActive: JsonRead.asBool(json['isActive'], fallback: false),
      isEmailVerified:
          JsonRead.asBool(json['is_email_verified'], fallback: false),
      isOwner: JsonRead.asBool(json['isOwner'], fallback: false) ||
          roles.contains(RoleEntity.owner),
      roles: roles,
      services: _readServices(json),
      schedule: _readSchedule(json),
      commissionPercentage: JsonRead.asDouble(json['commission_percentage']),
      deletedAt: DateCodec.tryDecode(json['deletedAt']),
      deletionReason: JsonRead.asOptionalString(json['deletionReason']),
    );
  }

  static Map<String, ServiceAssignment> _readServices(
      Map<String, dynamic> json) {
    final flat = json['services'] is List;
    final rows = JsonRead.asMapList(flat ? json['services'] : json['userServices']);
    final services = <String, ServiceAssignment>{};
    for (final row in rows) {
      final id = JsonRead.asOptionalString(
          flat ? (row['id'] ?? row['serviceId']) : row['serviceId']);
      if (id == null) continue;
      final customPrice = row['customPrice'];
      final commission = row['commissionPercentage'];
      services[id] = ServiceAssignment(
        serviceId: id,
        serviceName: JsonRead.asOptionalString(
            flat ? row['name'] : JsonRead.asMap(row['service'])?['name']),
        // 8.02: null = sin excepción (usa la general).
        commissionPercentage:
            commission == null ? null : JsonRead.asDouble(commission),
        customPrice: customPrice == null ? null : JsonRead.asDouble(customPrice),
        isActive: JsonRead.asBool(row['isActive'], fallback: true),
      );
    }
    return services;
  }

  /// Horario por día, con todas sus franjas ordenadas por inicio (13.05).
  /// Prioridad: `schedule_slots` → `schedule` (formato anterior, una franja
  /// por día) → filas crudas `schedules` (todas las del día con
  /// `is_available`; las de no disponibilidad no son horario de trabajo).
  static Map<String, List<WorkHours>> _readSchedule(
      Map<String, dynamic> json) {
    final slots = JsonRead.asMap(json['schedule_slots']);
    if (slots != null) {
      return _sorted({
        for (final entry in slots.entries)
          if (WorkHours.weekdays.contains(entry.key))
            entry.key: [
              for (final slot in JsonRead.asMapList(entry.value))
                _hours(slot['start'], slot['end']),
            ],
      });
    }
    final byDay = JsonRead.asMap(json['schedule']);
    if (byDay != null && byDay.isNotEmpty) {
      return _sorted({
        for (final entry in byDay.entries)
          if (WorkHours.weekdays.contains(entry.key))
            entry.key: [
              // Formato anterior `{start, end}`; una lista, por si acaso.
              if (JsonRead.asMap(entry.value) case final slot?)
                _hours(slot['start'], slot['end'])
              else
                for (final slot in JsonRead.asMapList(entry.value))
                  _hours(slot['start'], slot['end']),
            ],
      });
    }
    final grouped = <String, List<WorkHours>>{};
    for (final row in JsonRead.asMapList(json['schedules'])) {
      if (!JsonRead.asBool(row['is_available'], fallback: true)) continue;
      final day = _dayOfWeek[JsonRead.asInt(row['day_of_week'])];
      if (day == null) continue;
      (grouped[day] ??= []).add(_hours(row['start_time'], row['end_time']));
    }
    return _sorted(grouped);
  }

  /// Sin días vacíos y con las franjas por hora de inicio.
  static Map<String, List<WorkHours>> _sorted(
          Map<String, List<WorkHours>> byDay) =>
      {
        for (final entry in byDay.entries)
          if (entry.value.isNotEmpty)
            entry.key: List.unmodifiable(
                [...entry.value]..sort((a, b) => a.start.compareTo(b.start))),
      };

  static WorkHours _hours(Object? start, Object? end) => WorkHours(
        start: WorkHours.normalize(JsonRead.asString(start)),
        end: WorkHours.normalize(JsonRead.asString(end)),
      );

  EmployeeEntity toEntity() => EmployeeEntity(
        id: id,
        name: name,
        lastname: lastname,
        email: email,
        phone: phone,
        image: image,
        isActive: isActive,
        isEmailVerified: isEmailVerified,
        isOwner: isOwner,
        roles: [for (final role in roles) RoleEntity(role)],
        serviceAssignments: services,
        schedule: schedule,
        commissionPercentage: commissionPercentage,
        deletedAt: deletedAt,
        deletionReason: deletionReason,
      );
}
