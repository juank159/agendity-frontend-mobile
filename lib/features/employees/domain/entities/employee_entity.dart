import 'package:login_signup/core/utils/deep_equality.dart';
import 'package:login_signup/features/employees/domain/entities/role_entity.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/features/employees/domain/entities/work_hours.dart';

/// Estado de un profesional para el negocio (CLAUDE.md §1).
enum EmployeeStatus {
  /// Puede iniciar sesión y recibir citas.
  active,

  /// Nació inactivo y aún no verificó su email (2.16). Solo se activa al
  /// verificar; activarlo a mano da `EMAIL_NOT_VERIFIED`.
  pendingVerification,

  /// Desactivado por el Owner (con el email ya verificado).
  inactive,

  /// Dado de baja (soft-delete); se puede restaurar.
  deleted,
}

/// Profesional del negocio: el Owner o uno de sus empleados.
///
/// `GET /auth/employees` devuelve también al Owner ([isOwner]), que no se
/// puede borrar ni desactivar desde la gestión de empleados.
class EmployeeEntity {
  final String id;
  final String name;
  final String lastname;
  final String email;

  /// Vacío si la cuenta no tiene teléfono (alta con Google).
  final String phone;
  final String? image;
  final bool isActive;
  final bool isEmailVerified;
  final bool isOwner;
  final List<RoleEntity> roles;

  /// Servicios que atiende, por id de servicio. Vacío si la respuesta no los
  /// trae (alta y cambio de estado).
  final Map<String, ServiceAssignment> serviceAssignments;

  /// Horario semanal por día (`WorkHours.weekdays`). Vacío = sin horario.
  final Map<String, WorkHours> schedule;

  /// Fecha de la baja (soft-delete); `null` si no está borrado.
  final DateTime? deletedAt;
  final String? deletionReason;

  const EmployeeEntity({
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
    this.serviceAssignments = const {},
    this.schedule = const {},
    this.deletedAt,
    this.deletionReason,
  });

  String get fullName => '$name $lastname'.trim();

  List<String> get serviceIds => serviceAssignments.keys.toList();

  bool get isDeleted => deletedAt != null;

  /// Se le pueden agendar citas: activo y sin baja. Un inactivo da
  /// `PROFESSIONAL_INACTIVE` y uno borrado, `NOT_FOUND` (ARQUITECTURA §3).
  bool get canBeScheduled => isActive && !isDeleted;

  /// Empleado que aún debe verificar su email para poder activarse (el Owner
  /// puede trabajar sin verificarlo).
  bool get needsEmailVerification => !isOwner && !isEmailVerified;

  EmployeeStatus get status {
    if (isDeleted) return EmployeeStatus.deleted;
    if (isActive) return EmployeeStatus.active;
    if (needsEmailVerification) return EmployeeStatus.pendingVerification;
    return EmployeeStatus.inactive;
  }

  /// Copia tras la baja: inactivo, con fecha y motivo (lo mismo que guarda
  /// `DELETE /auth/employee/:id`).
  EmployeeEntity markDeleted({required DateTime at, String? reason}) =>
      EmployeeEntity(
        id: id,
        name: name,
        lastname: lastname,
        email: email,
        phone: phone,
        image: image,
        isActive: false,
        isEmailVerified: isEmailVerified,
        isOwner: isOwner,
        roles: roles,
        serviceAssignments: serviceAssignments,
        schedule: schedule,
        deletedAt: at,
        deletionReason: reason,
      );

  /// Copia tras restaurar: sin baja y con el estado que decidió el backend
  /// (inactivo si no ha verificado el email).
  EmployeeEntity markRestored({required bool isActive}) => EmployeeEntity(
        id: id,
        name: name,
        lastname: lastname,
        email: email,
        phone: phone,
        image: image,
        isActive: isActive,
        isEmailVerified: isEmailVerified,
        isOwner: isOwner,
        roles: roles,
        serviceAssignments: serviceAssignments,
        schedule: schedule,
      );

  /// Los opcionales no se pueden poner a `null` con [copyWith]: para la baja y
  /// la restauración están [markDeleted] y [markRestored].
  EmployeeEntity copyWith({
    String? id,
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? image,
    bool? isActive,
    bool? isEmailVerified,
    bool? isOwner,
    List<RoleEntity>? roles,
    Map<String, ServiceAssignment>? serviceAssignments,
    Map<String, WorkHours>? schedule,
    DateTime? deletedAt,
    String? deletionReason,
  }) =>
      EmployeeEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        lastname: lastname ?? this.lastname,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        image: image ?? this.image,
        isActive: isActive ?? this.isActive,
        isEmailVerified: isEmailVerified ?? this.isEmailVerified,
        isOwner: isOwner ?? this.isOwner,
        roles: roles ?? this.roles,
        serviceAssignments: serviceAssignments ?? this.serviceAssignments,
        schedule: schedule ?? this.schedule,
        deletedAt: deletedAt ?? this.deletedAt,
        deletionReason: deletionReason ?? this.deletionReason,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeEntity &&
          other.id == id &&
          other.name == name &&
          other.lastname == lastname &&
          other.email == email &&
          other.phone == phone &&
          other.image == image &&
          other.isActive == isActive &&
          other.isEmailVerified == isEmailVerified &&
          other.isOwner == isOwner &&
          DeepEquality.lists(other.roles, roles) &&
          DeepEquality.maps(other.serviceAssignments, serviceAssignments) &&
          DeepEquality.maps(other.schedule, schedule) &&
          other.deletedAt == deletedAt &&
          other.deletionReason == deletionReason;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        lastname,
        email,
        phone,
        image,
        isActive,
        isEmailVerified,
        isOwner,
        Object.hashAll(roles),
        DeepEquality.mapHash(serviceAssignments),
        DeepEquality.mapHash(schedule),
        deletedAt,
        deletionReason,
      );

  @override
  String toString() => 'EmployeeEntity($id, $fullName, $status)';
}
