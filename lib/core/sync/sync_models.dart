/// Contrato de `/sync` (backend 10.01a/b, D-18).
library;

/// Resultado de una mutación en `POST /sync/push`.
enum MutationStatus {
  applied,
  conflict,
  rejected,
  merged,
  retry;

  static MutationStatus? fromApi(Object? value) {
    for (final status in values) {
      if (status.name == value) return status;
    }
    return null;
  }
}

class MutationResult {
  final String mutationId;
  final MutationStatus status;
  final String? code;
  final String? message;

  /// `conflict` con el registro guardado en el servidor (p. ej. una cita sin
  /// hueco que queda para mover).
  final bool saved;

  /// `merged`: id del registro con el que se fusionó.
  final String? mergedInto;

  const MutationResult({
    required this.mutationId,
    required this.status,
    this.code,
    this.message,
    this.saved = false,
    this.mergedInto,
  });

  factory MutationResult.fromJson(Map<String, dynamic> json) => MutationResult(
        mutationId: json['mutation_id']?.toString() ?? '',
        status: MutationStatus.fromApi(json['status']) ?? MutationStatus.retry,
        code: json['code']?.toString(),
        message: json['message']?.toString(),
        saved: json['saved'] == true,
        mergedInto: json['merged_into']?.toString(),
      );
}

/// Operación de un cambio de la bajada.
enum ChangeOp {
  upsert,
  delete,
  leaveScope;

  static ChangeOp? fromApi(Object? value) => switch (value) {
        'upsert' => upsert,
        'delete' => delete,
        'leave_scope' => leaveScope,
        _ => null,
      };
}

class SyncChange {
  final String entity;
  final String id;
  final ChangeOp op;
  final Map<String, dynamic>? data;

  const SyncChange({
    required this.entity,
    required this.id,
    required this.op,
    this.data,
  });

  /// `null` si el cambio no se entiende (se ignora).
  static SyncChange? fromJson(Map<String, dynamic> json) {
    final op = ChangeOp.fromApi(json['op']);
    final entity = json['entity'];
    final id = json['id'];
    if (op == null || entity is! String || id == null) return null;
    final data = json['data'];
    return SyncChange(
      entity: entity,
      id: id.toString(),
      op: op,
      data: data is Map ? Map<String, dynamic>.from(data) : null,
    );
  }
}

/// Página de `GET /sync/changes`.
class ChangesPage {
  final List<SyncChange> changes;
  final String cursor;
  final bool hasMore;

  const ChangesPage({
    required this.changes,
    required this.cursor,
    required this.hasMore,
  });

  factory ChangesPage.fromJson(Map<String, dynamic> json, String previous) =>
      ChangesPage(
        changes: [
          for (final raw in (json['changes'] as List? ?? const []))
            if (raw is Map)
              if (SyncChange.fromJson(Map<String, dynamic>.from(raw))
                  case final change?)
                change,
        ],
        cursor: json['cursor']?.toString() ?? previous,
        hasMore: json['has_more'] == true,
      );
}

/// Una mutación tal como se envía.
class PushMutation {
  final String mutationId;
  final String type;
  final String? entityId;
  final Map<String, dynamic> payload;
  final String clientTime;

  const PushMutation({
    required this.mutationId,
    required this.type,
    this.entityId,
    required this.payload,
    required this.clientTime,
  });

  Map<String, dynamic> toJson() => {
        'mutation_id': mutationId,
        'type': type,
        if (entityId != null) 'entity_id': entityId,
        'payload': payload,
        'client_time': clientTime,
      };
}
