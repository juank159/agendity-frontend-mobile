import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/sync/outbox_store.dart';

/// Cómo aplica una feature los cambios de una entidad del feed en su tabla
/// local (10.02). La registra la feature en su `<f>_dependencies.dart`
/// (`SyncEngine.register`); core no conoce las features.
abstract class SyncEntityHandler {
  /// Nombre de la entidad en el feed (`clients`, `appointments`…).
  String get entity;

  /// Fila nueva o cambiada del servidor ([data] con la forma de la API).
  Future<void> upsert(AppDatabase db, String id, Map<String, dynamic> data);

  /// Borrada en el servidor.
  Future<void> delete(AppDatabase db, String id);

  /// Ya no es visible para este usuario (p. ej. una cita que pasó a otro
  /// profesional): se quita de la base local.
  Future<void> leaveScope(AppDatabase db, String id) => delete(db, id);

  /// Vuelve a aplicar en local una operación aún pendiente, después de que
  /// una bajada pisó la fila (lo local = servidor + lo pendiente).
  Future<void> replay(AppDatabase db, OutboxEntry entry);

  /// Un registro de [entity] cambió de id (`merged`): actualiza la propia
  /// fila (si es de esta entidad) y las referencias a él.
  Future<void> remap(
      AppDatabase db, String entity, String fromId, String toId) async {}

  /// Deja la fila como está en el servidor tras un `rejected` o un
  /// `conflict` sin guardar (deshace lo optimista). Puede usar la red; si
  /// falla, la siguiente bajada la corregirá cuando cambie.
  Future<void> restore(AppDatabase db, String id) async {}
}
