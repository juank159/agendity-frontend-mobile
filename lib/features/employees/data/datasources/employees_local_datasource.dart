import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/employees/data/models/employee_model.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';

/// Profesionales en la base local (10.02b): cada usuario (`users`) con sus
/// servicios (`user_services` + nombre del servicio) y su horario
/// (`schedules`), armados con la misma forma que `GET /auth/employees/deleted`
/// para que los lea [EmployeeModel].
class EmployeesLocalDataSource {
  const EmployeesLocalDataSource();

  /// Activos e inactivos, con el Owner; sin los dados de baja. Por nombre.
  Future<List<EmployeeEntity>> employees(AppDatabase db,
      {bool deleted = false}) async {
    final services = {
      for (final s in await DocumentStore.list(db, 'services')) s['id']: s,
    };
    final result = <EmployeeEntity>[];
    for (final user in await DocumentStore.list(db, SharedDocs.users.entity)) {
      final isDeleted = JsonRead.asOptionalString(user['deletedAt']) != null;
      if (isDeleted != deleted) continue;
      result.add(await _compose(db, user, services));
    }
    return result
      ..sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
  }

  Future<EmployeeEntity?> employee(AppDatabase db, String id) async {
    final user = await DocumentStore.get(db, SharedDocs.users.entity, id);
    if (user == null) return null;
    final services = {
      for (final s in await DocumentStore.list(db, 'services')) s['id']: s,
    };
    return _compose(db, user, services);
  }

  Future<EmployeeEntity> _compose(AppDatabase db, Map<String, dynamic> user,
      Map<Object?, Map<String, dynamic>> services) async {
    final id = JsonRead.asString(user['id']);
    final assignments = await DocumentStore.list(
        db, SharedDocs.userServices.entity,
        ref1: id);
    final schedules =
        await DocumentStore.list(db, SharedDocs.schedules.entity, ref1: id);
    return EmployeeModel.fromJson({
      ...user,
      'isOwner': SharedDocs.isOwner(user),
      'userServices': [
        for (final a in assignments)
          {
            ...a,
            'service': {'name': services[a['serviceId']]?['name']},
          },
      ],
      'schedules': schedules,
    }).toEntity();
  }
}
