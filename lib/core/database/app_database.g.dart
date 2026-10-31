// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
      'seq', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _mutationIdMeta =
      const VerificationMeta('mutationId');
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
      'mutation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
      'entity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _clientTimeMeta =
      const VerificationMeta('clientTime');
  @override
  late final GeneratedColumn<String> clientTime = GeneratedColumn<String>(
      'client_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        seq,
        mutationId,
        type,
        entity,
        entityId,
        payload,
        clientTime,
        status,
        code,
        message,
        attempts
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
          _seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    }
    if (data.containsKey('mutation_id')) {
      context.handle(
          _mutationIdMeta,
          mutationId.isAcceptableOrUnknown(
              data['mutation_id']!, _mutationIdMeta));
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(_entityMeta,
          entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('client_time')) {
      context.handle(
          _clientTimeMeta,
          clientTime.isAcceptableOrUnknown(
              data['client_time']!, _clientTimeMeta));
    } else if (isInserting) {
      context.missing(_clientTimeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      seq: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}seq'])!,
      mutationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mutation_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      entity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id']),
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      clientTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_time'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code']),
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message']),
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int seq;

  /// UUID v7: idempotencia en el servidor (`sync_mutations`).
  final String mutationId;

  /// Operación de negocio (`client.create`, `appointment.cancel`…).
  final String type;

  /// Entidad del feed (`clients`, `appointments`…) y su id.
  final String entity;
  final String? entityId;

  /// JSON con los campos de la ruta online de esa operación.
  final String payload;

  /// Instante en que se hizo (ISO UTC): el servidor decide "solo a futuro"
  /// con él.
  final String clientTime;

  /// `pending` (se envía), `rejected` o `conflict` (esperan al usuario).
  final String status;
  final String? code;
  final String? message;
  final int attempts;
  const OutboxRow(
      {required this.seq,
      required this.mutationId,
      required this.type,
      required this.entity,
      this.entityId,
      required this.payload,
      required this.clientTime,
      required this.status,
      this.code,
      this.message,
      required this.attempts});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['mutation_id'] = Variable<String>(mutationId);
    map['type'] = Variable<String>(type);
    map['entity'] = Variable<String>(entity);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    map['payload'] = Variable<String>(payload);
    map['client_time'] = Variable<String>(clientTime);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      seq: Value(seq),
      mutationId: Value(mutationId),
      type: Value(type),
      entity: Value(entity),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      payload: Value(payload),
      clientTime: Value(clientTime),
      status: Value(status),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      attempts: Value(attempts),
    );
  }

  factory OutboxRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      seq: serializer.fromJson<int>(json['seq']),
      mutationId: serializer.fromJson<String>(json['mutationId']),
      type: serializer.fromJson<String>(json['type']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      payload: serializer.fromJson<String>(json['payload']),
      clientTime: serializer.fromJson<String>(json['clientTime']),
      status: serializer.fromJson<String>(json['status']),
      code: serializer.fromJson<String?>(json['code']),
      message: serializer.fromJson<String?>(json['message']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'mutationId': serializer.toJson<String>(mutationId),
      'type': serializer.toJson<String>(type),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String?>(entityId),
      'payload': serializer.toJson<String>(payload),
      'clientTime': serializer.toJson<String>(clientTime),
      'status': serializer.toJson<String>(status),
      'code': serializer.toJson<String?>(code),
      'message': serializer.toJson<String?>(message),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  OutboxRow copyWith(
          {int? seq,
          String? mutationId,
          String? type,
          String? entity,
          Value<String?> entityId = const Value.absent(),
          String? payload,
          String? clientTime,
          String? status,
          Value<String?> code = const Value.absent(),
          Value<String?> message = const Value.absent(),
          int? attempts}) =>
      OutboxRow(
        seq: seq ?? this.seq,
        mutationId: mutationId ?? this.mutationId,
        type: type ?? this.type,
        entity: entity ?? this.entity,
        entityId: entityId.present ? entityId.value : this.entityId,
        payload: payload ?? this.payload,
        clientTime: clientTime ?? this.clientTime,
        status: status ?? this.status,
        code: code.present ? code.value : this.code,
        message: message.present ? message.value : this.message,
        attempts: attempts ?? this.attempts,
      );
  OutboxRow copyWithCompanion(OutboxCompanion data) {
    return OutboxRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      mutationId:
          data.mutationId.present ? data.mutationId.value : this.mutationId,
      type: data.type.present ? data.type.value : this.type,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payload: data.payload.present ? data.payload.value : this.payload,
      clientTime:
          data.clientTime.present ? data.clientTime.value : this.clientTime,
      status: data.status.present ? data.status.value : this.status,
      code: data.code.present ? data.code.value : this.code,
      message: data.message.present ? data.message.value : this.message,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('seq: $seq, ')
          ..write('mutationId: $mutationId, ')
          ..write('type: $type, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('clientTime: $clientTime, ')
          ..write('status: $status, ')
          ..write('code: $code, ')
          ..write('message: $message, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(seq, mutationId, type, entity, entityId,
      payload, clientTime, status, code, message, attempts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.seq == this.seq &&
          other.mutationId == this.mutationId &&
          other.type == this.type &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.payload == this.payload &&
          other.clientTime == this.clientTime &&
          other.status == this.status &&
          other.code == this.code &&
          other.message == this.message &&
          other.attempts == this.attempts);
}

class OutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> seq;
  final Value<String> mutationId;
  final Value<String> type;
  final Value<String> entity;
  final Value<String?> entityId;
  final Value<String> payload;
  final Value<String> clientTime;
  final Value<String> status;
  final Value<String?> code;
  final Value<String?> message;
  final Value<int> attempts;
  const OutboxCompanion({
    this.seq = const Value.absent(),
    this.mutationId = const Value.absent(),
    this.type = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payload = const Value.absent(),
    this.clientTime = const Value.absent(),
    this.status = const Value.absent(),
    this.code = const Value.absent(),
    this.message = const Value.absent(),
    this.attempts = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String mutationId,
    required String type,
    required String entity,
    this.entityId = const Value.absent(),
    this.payload = const Value.absent(),
    required String clientTime,
    this.status = const Value.absent(),
    this.code = const Value.absent(),
    this.message = const Value.absent(),
    this.attempts = const Value.absent(),
  })  : mutationId = Value(mutationId),
        type = Value(type),
        entity = Value(entity),
        clientTime = Value(clientTime);
  static Insertable<OutboxRow> custom({
    Expression<int>? seq,
    Expression<String>? mutationId,
    Expression<String>? type,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? payload,
    Expression<String>? clientTime,
    Expression<String>? status,
    Expression<String>? code,
    Expression<String>? message,
    Expression<int>? attempts,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (mutationId != null) 'mutation_id': mutationId,
      if (type != null) 'type': type,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (payload != null) 'payload': payload,
      if (clientTime != null) 'client_time': clientTime,
      if (status != null) 'status': status,
      if (code != null) 'code': code,
      if (message != null) 'message': message,
      if (attempts != null) 'attempts': attempts,
    });
  }

  OutboxCompanion copyWith(
      {Value<int>? seq,
      Value<String>? mutationId,
      Value<String>? type,
      Value<String>? entity,
      Value<String?>? entityId,
      Value<String>? payload,
      Value<String>? clientTime,
      Value<String>? status,
      Value<String?>? code,
      Value<String?>? message,
      Value<int>? attempts}) {
    return OutboxCompanion(
      seq: seq ?? this.seq,
      mutationId: mutationId ?? this.mutationId,
      type: type ?? this.type,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      clientTime: clientTime ?? this.clientTime,
      status: status ?? this.status,
      code: code ?? this.code,
      message: message ?? this.message,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (clientTime.present) {
      map['client_time'] = Variable<String>(clientTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('mutationId: $mutationId, ')
          ..write('type: $type, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('clientTime: $clientTime, ')
          ..write('status: $status, ')
          ..write('code: $code, ')
          ..write('message: $message, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(Insertable<SyncMetaRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaRow extends DataClass implements Insertable<SyncMetaRow> {
  final String key;
  final String value;
  const SyncMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SyncMetaRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncMetaRow copyWith({String? key, String? value}) => SyncMetaRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SyncMetaRow copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SyncMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SyncMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IdRemapsTable extends IdRemaps
    with TableInfo<$IdRemapsTable, IdRemapRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdRemapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
      'entity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fromIdMeta = const VerificationMeta('fromId');
  @override
  late final GeneratedColumn<String> fromId = GeneratedColumn<String>(
      'from_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toIdMeta = const VerificationMeta('toId');
  @override
  late final GeneratedColumn<String> toId = GeneratedColumn<String>(
      'to_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [entity, fromId, toId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'id_remaps';
  @override
  VerificationContext validateIntegrity(Insertable<IdRemapRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(_entityMeta,
          entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('from_id')) {
      context.handle(_fromIdMeta,
          fromId.isAcceptableOrUnknown(data['from_id']!, _fromIdMeta));
    } else if (isInserting) {
      context.missing(_fromIdMeta);
    }
    if (data.containsKey('to_id')) {
      context.handle(
          _toIdMeta, toId.isAcceptableOrUnknown(data['to_id']!, _toIdMeta));
    } else if (isInserting) {
      context.missing(_toIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, fromId};
  @override
  IdRemapRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IdRemapRow(
      entity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity'])!,
      fromId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_id'])!,
      toId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_id'])!,
    );
  }

  @override
  $IdRemapsTable createAlias(String alias) {
    return $IdRemapsTable(attachedDatabase, alias);
  }
}

class IdRemapRow extends DataClass implements Insertable<IdRemapRow> {
  final String entity;
  final String fromId;
  final String toId;
  const IdRemapRow(
      {required this.entity, required this.fromId, required this.toId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['from_id'] = Variable<String>(fromId);
    map['to_id'] = Variable<String>(toId);
    return map;
  }

  IdRemapsCompanion toCompanion(bool nullToAbsent) {
    return IdRemapsCompanion(
      entity: Value(entity),
      fromId: Value(fromId),
      toId: Value(toId),
    );
  }

  factory IdRemapRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IdRemapRow(
      entity: serializer.fromJson<String>(json['entity']),
      fromId: serializer.fromJson<String>(json['fromId']),
      toId: serializer.fromJson<String>(json['toId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'fromId': serializer.toJson<String>(fromId),
      'toId': serializer.toJson<String>(toId),
    };
  }

  IdRemapRow copyWith({String? entity, String? fromId, String? toId}) =>
      IdRemapRow(
        entity: entity ?? this.entity,
        fromId: fromId ?? this.fromId,
        toId: toId ?? this.toId,
      );
  IdRemapRow copyWithCompanion(IdRemapsCompanion data) {
    return IdRemapRow(
      entity: data.entity.present ? data.entity.value : this.entity,
      fromId: data.fromId.present ? data.fromId.value : this.fromId,
      toId: data.toId.present ? data.toId.value : this.toId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IdRemapRow(')
          ..write('entity: $entity, ')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, fromId, toId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdRemapRow &&
          other.entity == this.entity &&
          other.fromId == this.fromId &&
          other.toId == this.toId);
}

class IdRemapsCompanion extends UpdateCompanion<IdRemapRow> {
  final Value<String> entity;
  final Value<String> fromId;
  final Value<String> toId;
  final Value<int> rowid;
  const IdRemapsCompanion({
    this.entity = const Value.absent(),
    this.fromId = const Value.absent(),
    this.toId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdRemapsCompanion.insert({
    required String entity,
    required String fromId,
    required String toId,
    this.rowid = const Value.absent(),
  })  : entity = Value(entity),
        fromId = Value(fromId),
        toId = Value(toId);
  static Insertable<IdRemapRow> custom({
    Expression<String>? entity,
    Expression<String>? fromId,
    Expression<String>? toId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (fromId != null) 'from_id': fromId,
      if (toId != null) 'to_id': toId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdRemapsCompanion copyWith(
      {Value<String>? entity,
      Value<String>? fromId,
      Value<String>? toId,
      Value<int>? rowid}) {
    return IdRemapsCompanion(
      entity: entity ?? this.entity,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (fromId.present) {
      map['from_id'] = Variable<String>(fromId.value);
    }
    if (toId.present) {
      map['to_id'] = Variable<String>(toId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdRemapsCompanion(')
          ..write('entity: $entity, ')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalClientsTable extends LocalClients
    with TableInfo<$LocalClientsTable, LocalClientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalClientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastnameMeta =
      const VerificationMeta('lastname');
  @override
  late final GeneratedColumn<String> lastname = GeneratedColumn<String>(
      'lastname', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
      'image', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFromDeviceMeta =
      const VerificationMeta('isFromDevice');
  @override
  late final GeneratedColumn<bool> isFromDevice = GeneratedColumn<bool>(
      'is_from_device', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_from_device" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deviceContactIdMeta =
      const VerificationMeta('deviceContactId');
  @override
  late final GeneratedColumn<String> deviceContactId = GeneratedColumn<String>(
      'device_contact_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastVisitMeta =
      const VerificationMeta('lastVisit');
  @override
  late final GeneratedColumn<String> lastVisit = GeneratedColumn<String>(
      'last_visit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _birthdayMeta =
      const VerificationMeta('birthday');
  @override
  late final GeneratedColumn<String> birthday = GeneratedColumn<String>(
      'birthday', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _showNotesMeta =
      const VerificationMeta('showNotes');
  @override
  late final GeneratedColumn<bool> showNotes = GeneratedColumn<bool>(
      'show_notes', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("show_notes" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        lastname,
        email,
        phone,
        image,
        address,
        isFromDevice,
        deviceContactId,
        lastVisit,
        isActive,
        createdAt,
        updatedAt,
        notes,
        birthday,
        showNotes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_clients';
  @override
  VerificationContext validateIntegrity(Insertable<LocalClientRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('lastname')) {
      context.handle(_lastnameMeta,
          lastname.isAcceptableOrUnknown(data['lastname']!, _lastnameMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('image')) {
      context.handle(
          _imageMeta, image.isAcceptableOrUnknown(data['image']!, _imageMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('is_from_device')) {
      context.handle(
          _isFromDeviceMeta,
          isFromDevice.isAcceptableOrUnknown(
              data['is_from_device']!, _isFromDeviceMeta));
    }
    if (data.containsKey('device_contact_id')) {
      context.handle(
          _deviceContactIdMeta,
          deviceContactId.isAcceptableOrUnknown(
              data['device_contact_id']!, _deviceContactIdMeta));
    }
    if (data.containsKey('last_visit')) {
      context.handle(_lastVisitMeta,
          lastVisit.isAcceptableOrUnknown(data['last_visit']!, _lastVisitMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('birthday')) {
      context.handle(_birthdayMeta,
          birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta));
    }
    if (data.containsKey('show_notes')) {
      context.handle(_showNotesMeta,
          showNotes.isAcceptableOrUnknown(data['show_notes']!, _showNotesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalClientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalClientRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      lastname: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lastname'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      image: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      isFromDevice: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_from_device'])!,
      deviceContactId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}device_contact_id']),
      lastVisit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_visit']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      birthday: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}birthday']),
      showNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_notes'])!,
    );
  }

  @override
  $LocalClientsTable createAlias(String alias) {
    return $LocalClientsTable(attachedDatabase, alias);
  }
}

class LocalClientRow extends DataClass implements Insertable<LocalClientRow> {
  final String id;
  final String name;
  final String lastname;
  final String? email;
  final String phone;
  final String? image;
  final String? address;
  final bool isFromDevice;
  final String? deviceContactId;
  final String? lastVisit;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;
  final String? notes;
  final String? birthday;
  final bool showNotes;
  const LocalClientRow(
      {required this.id,
      required this.name,
      required this.lastname,
      this.email,
      required this.phone,
      this.image,
      this.address,
      required this.isFromDevice,
      this.deviceContactId,
      this.lastVisit,
      required this.isActive,
      this.createdAt,
      this.updatedAt,
      this.notes,
      this.birthday,
      required this.showNotes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['lastname'] = Variable<String>(lastname);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || image != null) {
      map['image'] = Variable<String>(image);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['is_from_device'] = Variable<bool>(isFromDevice);
    if (!nullToAbsent || deviceContactId != null) {
      map['device_contact_id'] = Variable<String>(deviceContactId);
    }
    if (!nullToAbsent || lastVisit != null) {
      map['last_visit'] = Variable<String>(lastVisit);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || birthday != null) {
      map['birthday'] = Variable<String>(birthday);
    }
    map['show_notes'] = Variable<bool>(showNotes);
    return map;
  }

  LocalClientsCompanion toCompanion(bool nullToAbsent) {
    return LocalClientsCompanion(
      id: Value(id),
      name: Value(name),
      lastname: Value(lastname),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      phone: Value(phone),
      image:
          image == null && nullToAbsent ? const Value.absent() : Value(image),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      isFromDevice: Value(isFromDevice),
      deviceContactId: deviceContactId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceContactId),
      lastVisit: lastVisit == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVisit),
      isActive: Value(isActive),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      birthday: birthday == null && nullToAbsent
          ? const Value.absent()
          : Value(birthday),
      showNotes: Value(showNotes),
    );
  }

  factory LocalClientRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalClientRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      lastname: serializer.fromJson<String>(json['lastname']),
      email: serializer.fromJson<String?>(json['email']),
      phone: serializer.fromJson<String>(json['phone']),
      image: serializer.fromJson<String?>(json['image']),
      address: serializer.fromJson<String?>(json['address']),
      isFromDevice: serializer.fromJson<bool>(json['isFromDevice']),
      deviceContactId: serializer.fromJson<String?>(json['deviceContactId']),
      lastVisit: serializer.fromJson<String?>(json['lastVisit']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      birthday: serializer.fromJson<String?>(json['birthday']),
      showNotes: serializer.fromJson<bool>(json['showNotes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'lastname': serializer.toJson<String>(lastname),
      'email': serializer.toJson<String?>(email),
      'phone': serializer.toJson<String>(phone),
      'image': serializer.toJson<String?>(image),
      'address': serializer.toJson<String?>(address),
      'isFromDevice': serializer.toJson<bool>(isFromDevice),
      'deviceContactId': serializer.toJson<String?>(deviceContactId),
      'lastVisit': serializer.toJson<String?>(lastVisit),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
      'notes': serializer.toJson<String?>(notes),
      'birthday': serializer.toJson<String?>(birthday),
      'showNotes': serializer.toJson<bool>(showNotes),
    };
  }

  LocalClientRow copyWith(
          {String? id,
          String? name,
          String? lastname,
          Value<String?> email = const Value.absent(),
          String? phone,
          Value<String?> image = const Value.absent(),
          Value<String?> address = const Value.absent(),
          bool? isFromDevice,
          Value<String?> deviceContactId = const Value.absent(),
          Value<String?> lastVisit = const Value.absent(),
          bool? isActive,
          Value<String?> createdAt = const Value.absent(),
          Value<String?> updatedAt = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<String?> birthday = const Value.absent(),
          bool? showNotes}) =>
      LocalClientRow(
        id: id ?? this.id,
        name: name ?? this.name,
        lastname: lastname ?? this.lastname,
        email: email.present ? email.value : this.email,
        phone: phone ?? this.phone,
        image: image.present ? image.value : this.image,
        address: address.present ? address.value : this.address,
        isFromDevice: isFromDevice ?? this.isFromDevice,
        deviceContactId: deviceContactId.present
            ? deviceContactId.value
            : this.deviceContactId,
        lastVisit: lastVisit.present ? lastVisit.value : this.lastVisit,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        notes: notes.present ? notes.value : this.notes,
        birthday: birthday.present ? birthday.value : this.birthday,
        showNotes: showNotes ?? this.showNotes,
      );
  LocalClientRow copyWithCompanion(LocalClientsCompanion data) {
    return LocalClientRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      lastname: data.lastname.present ? data.lastname.value : this.lastname,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      image: data.image.present ? data.image.value : this.image,
      address: data.address.present ? data.address.value : this.address,
      isFromDevice: data.isFromDevice.present
          ? data.isFromDevice.value
          : this.isFromDevice,
      deviceContactId: data.deviceContactId.present
          ? data.deviceContactId.value
          : this.deviceContactId,
      lastVisit: data.lastVisit.present ? data.lastVisit.value : this.lastVisit,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      birthday: data.birthday.present ? data.birthday.value : this.birthday,
      showNotes: data.showNotes.present ? data.showNotes.value : this.showNotes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalClientRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('lastname: $lastname, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('image: $image, ')
          ..write('address: $address, ')
          ..write('isFromDevice: $isFromDevice, ')
          ..write('deviceContactId: $deviceContactId, ')
          ..write('lastVisit: $lastVisit, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notes: $notes, ')
          ..write('birthday: $birthday, ')
          ..write('showNotes: $showNotes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      lastname,
      email,
      phone,
      image,
      address,
      isFromDevice,
      deviceContactId,
      lastVisit,
      isActive,
      createdAt,
      updatedAt,
      notes,
      birthday,
      showNotes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalClientRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.lastname == this.lastname &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.image == this.image &&
          other.address == this.address &&
          other.isFromDevice == this.isFromDevice &&
          other.deviceContactId == this.deviceContactId &&
          other.lastVisit == this.lastVisit &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.notes == this.notes &&
          other.birthday == this.birthday &&
          other.showNotes == this.showNotes);
}

class LocalClientsCompanion extends UpdateCompanion<LocalClientRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> lastname;
  final Value<String?> email;
  final Value<String> phone;
  final Value<String?> image;
  final Value<String?> address;
  final Value<bool> isFromDevice;
  final Value<String?> deviceContactId;
  final Value<String?> lastVisit;
  final Value<bool> isActive;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<String?> notes;
  final Value<String?> birthday;
  final Value<bool> showNotes;
  final Value<int> rowid;
  const LocalClientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.lastname = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.image = const Value.absent(),
    this.address = const Value.absent(),
    this.isFromDevice = const Value.absent(),
    this.deviceContactId = const Value.absent(),
    this.lastVisit = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.birthday = const Value.absent(),
    this.showNotes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalClientsCompanion.insert({
    required String id,
    required String name,
    this.lastname = const Value.absent(),
    this.email = const Value.absent(),
    required String phone,
    this.image = const Value.absent(),
    this.address = const Value.absent(),
    this.isFromDevice = const Value.absent(),
    this.deviceContactId = const Value.absent(),
    this.lastVisit = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.birthday = const Value.absent(),
    this.showNotes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        phone = Value(phone);
  static Insertable<LocalClientRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? lastname,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? image,
    Expression<String>? address,
    Expression<bool>? isFromDevice,
    Expression<String>? deviceContactId,
    Expression<String>? lastVisit,
    Expression<bool>? isActive,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? notes,
    Expression<String>? birthday,
    Expression<bool>? showNotes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (lastname != null) 'lastname': lastname,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (image != null) 'image': image,
      if (address != null) 'address': address,
      if (isFromDevice != null) 'is_from_device': isFromDevice,
      if (deviceContactId != null) 'device_contact_id': deviceContactId,
      if (lastVisit != null) 'last_visit': lastVisit,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (notes != null) 'notes': notes,
      if (birthday != null) 'birthday': birthday,
      if (showNotes != null) 'show_notes': showNotes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalClientsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? lastname,
      Value<String?>? email,
      Value<String>? phone,
      Value<String?>? image,
      Value<String?>? address,
      Value<bool>? isFromDevice,
      Value<String?>? deviceContactId,
      Value<String?>? lastVisit,
      Value<bool>? isActive,
      Value<String?>? createdAt,
      Value<String?>? updatedAt,
      Value<String?>? notes,
      Value<String?>? birthday,
      Value<bool>? showNotes,
      Value<int>? rowid}) {
    return LocalClientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      address: address ?? this.address,
      isFromDevice: isFromDevice ?? this.isFromDevice,
      deviceContactId: deviceContactId ?? this.deviceContactId,
      lastVisit: lastVisit ?? this.lastVisit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      birthday: birthday ?? this.birthday,
      showNotes: showNotes ?? this.showNotes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lastname.present) {
      map['lastname'] = Variable<String>(lastname.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (image.present) {
      map['image'] = Variable<String>(image.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (isFromDevice.present) {
      map['is_from_device'] = Variable<bool>(isFromDevice.value);
    }
    if (deviceContactId.present) {
      map['device_contact_id'] = Variable<String>(deviceContactId.value);
    }
    if (lastVisit.present) {
      map['last_visit'] = Variable<String>(lastVisit.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (birthday.present) {
      map['birthday'] = Variable<String>(birthday.value);
    }
    if (showNotes.present) {
      map['show_notes'] = Variable<bool>(showNotes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalClientsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('lastname: $lastname, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('image: $image, ')
          ..write('address: $address, ')
          ..write('isFromDevice: $isFromDevice, ')
          ..write('deviceContactId: $deviceContactId, ')
          ..write('lastVisit: $lastVisit, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notes: $notes, ')
          ..write('birthday: $birthday, ')
          ..write('showNotes: $showNotes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  late final $IdRemapsTable idRemaps = $IdRemapsTable(this);
  late final $LocalClientsTable localClients = $LocalClientsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [outbox, syncMeta, idRemaps, localClients];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  required String mutationId,
  required String type,
  required String entity,
  Value<String?> entityId,
  Value<String> payload,
  required String clientTime,
  Value<String> status,
  Value<String?> code,
  Value<String?> message,
  Value<int> attempts,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  Value<String> mutationId,
  Value<String> type,
  Value<String> entity,
  Value<String?> entityId,
  Value<String> payload,
  Value<String> clientTime,
  Value<String> status,
  Value<String?> code,
  Value<String?> message,
  Value<int> attempts,
});

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientTime => $composableBuilder(
      column: $table.clientTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientTime => $composableBuilder(
      column: $table.clientTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get clientTime => $composableBuilder(
      column: $table.clientTime, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$OutboxTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OutboxTable,
    OutboxRow,
    $$OutboxTableFilterComposer,
    $$OutboxTableOrderingComposer,
    $$OutboxTableAnnotationComposer,
    $$OutboxTableCreateCompanionBuilder,
    $$OutboxTableUpdateCompanionBuilder,
    (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
    OutboxRow,
    PrefetchHooks Function()> {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> seq = const Value.absent(),
            Value<String> mutationId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> entity = const Value.absent(),
            Value<String?> entityId = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> clientTime = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> code = const Value.absent(),
            Value<String?> message = const Value.absent(),
            Value<int> attempts = const Value.absent(),
          }) =>
              OutboxCompanion(
            seq: seq,
            mutationId: mutationId,
            type: type,
            entity: entity,
            entityId: entityId,
            payload: payload,
            clientTime: clientTime,
            status: status,
            code: code,
            message: message,
            attempts: attempts,
          ),
          createCompanionCallback: ({
            Value<int> seq = const Value.absent(),
            required String mutationId,
            required String type,
            required String entity,
            Value<String?> entityId = const Value.absent(),
            Value<String> payload = const Value.absent(),
            required String clientTime,
            Value<String> status = const Value.absent(),
            Value<String?> code = const Value.absent(),
            Value<String?> message = const Value.absent(),
            Value<int> attempts = const Value.absent(),
          }) =>
              OutboxCompanion.insert(
            seq: seq,
            mutationId: mutationId,
            type: type,
            entity: entity,
            entityId: entityId,
            payload: payload,
            clientTime: clientTime,
            status: status,
            code: code,
            message: message,
            attempts: attempts,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OutboxTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OutboxTable,
    OutboxRow,
    $$OutboxTableFilterComposer,
    $$OutboxTableOrderingComposer,
    $$OutboxTableAnnotationComposer,
    $$OutboxTableCreateCompanionBuilder,
    $$OutboxTableUpdateCompanionBuilder,
    (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
    OutboxRow,
    PrefetchHooks Function()>;
typedef $$SyncMetaTableCreateCompanionBuilder = SyncMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncMetaTableUpdateCompanionBuilder = SyncMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncMetaTable,
    SyncMetaRow,
    $$SyncMetaTableFilterComposer,
    $$SyncMetaTableOrderingComposer,
    $$SyncMetaTableAnnotationComposer,
    $$SyncMetaTableCreateCompanionBuilder,
    $$SyncMetaTableUpdateCompanionBuilder,
    (SyncMetaRow, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaRow>),
    SyncMetaRow,
    PrefetchHooks Function()> {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetaCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetaCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncMetaTable,
    SyncMetaRow,
    $$SyncMetaTableFilterComposer,
    $$SyncMetaTableOrderingComposer,
    $$SyncMetaTableAnnotationComposer,
    $$SyncMetaTableCreateCompanionBuilder,
    $$SyncMetaTableUpdateCompanionBuilder,
    (SyncMetaRow, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaRow>),
    SyncMetaRow,
    PrefetchHooks Function()>;
typedef $$IdRemapsTableCreateCompanionBuilder = IdRemapsCompanion Function({
  required String entity,
  required String fromId,
  required String toId,
  Value<int> rowid,
});
typedef $$IdRemapsTableUpdateCompanionBuilder = IdRemapsCompanion Function({
  Value<String> entity,
  Value<String> fromId,
  Value<String> toId,
  Value<int> rowid,
});

class $$IdRemapsTableFilterComposer
    extends Composer<_$AppDatabase, $IdRemapsTable> {
  $$IdRemapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromId => $composableBuilder(
      column: $table.fromId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toId => $composableBuilder(
      column: $table.toId, builder: (column) => ColumnFilters(column));
}

class $$IdRemapsTableOrderingComposer
    extends Composer<_$AppDatabase, $IdRemapsTable> {
  $$IdRemapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromId => $composableBuilder(
      column: $table.fromId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toId => $composableBuilder(
      column: $table.toId, builder: (column) => ColumnOrderings(column));
}

class $$IdRemapsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IdRemapsTable> {
  $$IdRemapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get fromId =>
      $composableBuilder(column: $table.fromId, builder: (column) => column);

  GeneratedColumn<String> get toId =>
      $composableBuilder(column: $table.toId, builder: (column) => column);
}

class $$IdRemapsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IdRemapsTable,
    IdRemapRow,
    $$IdRemapsTableFilterComposer,
    $$IdRemapsTableOrderingComposer,
    $$IdRemapsTableAnnotationComposer,
    $$IdRemapsTableCreateCompanionBuilder,
    $$IdRemapsTableUpdateCompanionBuilder,
    (IdRemapRow, BaseReferences<_$AppDatabase, $IdRemapsTable, IdRemapRow>),
    IdRemapRow,
    PrefetchHooks Function()> {
  $$IdRemapsTableTableManager(_$AppDatabase db, $IdRemapsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdRemapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdRemapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdRemapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> entity = const Value.absent(),
            Value<String> fromId = const Value.absent(),
            Value<String> toId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IdRemapsCompanion(
            entity: entity,
            fromId: fromId,
            toId: toId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String entity,
            required String fromId,
            required String toId,
            Value<int> rowid = const Value.absent(),
          }) =>
              IdRemapsCompanion.insert(
            entity: entity,
            fromId: fromId,
            toId: toId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IdRemapsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IdRemapsTable,
    IdRemapRow,
    $$IdRemapsTableFilterComposer,
    $$IdRemapsTableOrderingComposer,
    $$IdRemapsTableAnnotationComposer,
    $$IdRemapsTableCreateCompanionBuilder,
    $$IdRemapsTableUpdateCompanionBuilder,
    (IdRemapRow, BaseReferences<_$AppDatabase, $IdRemapsTable, IdRemapRow>),
    IdRemapRow,
    PrefetchHooks Function()>;
typedef $$LocalClientsTableCreateCompanionBuilder = LocalClientsCompanion
    Function({
  required String id,
  required String name,
  Value<String> lastname,
  Value<String?> email,
  required String phone,
  Value<String?> image,
  Value<String?> address,
  Value<bool> isFromDevice,
  Value<String?> deviceContactId,
  Value<String?> lastVisit,
  Value<bool> isActive,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<String?> notes,
  Value<String?> birthday,
  Value<bool> showNotes,
  Value<int> rowid,
});
typedef $$LocalClientsTableUpdateCompanionBuilder = LocalClientsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> lastname,
  Value<String?> email,
  Value<String> phone,
  Value<String?> image,
  Value<String?> address,
  Value<bool> isFromDevice,
  Value<String?> deviceContactId,
  Value<String?> lastVisit,
  Value<bool> isActive,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<String?> notes,
  Value<String?> birthday,
  Value<bool> showNotes,
  Value<int> rowid,
});

class $$LocalClientsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalClientsTable> {
  $$LocalClientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastname => $composableBuilder(
      column: $table.lastname, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFromDevice => $composableBuilder(
      column: $table.isFromDevice, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceContactId => $composableBuilder(
      column: $table.deviceContactId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastVisit => $composableBuilder(
      column: $table.lastVisit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get birthday => $composableBuilder(
      column: $table.birthday, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showNotes => $composableBuilder(
      column: $table.showNotes, builder: (column) => ColumnFilters(column));
}

class $$LocalClientsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalClientsTable> {
  $$LocalClientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastname => $composableBuilder(
      column: $table.lastname, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFromDevice => $composableBuilder(
      column: $table.isFromDevice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceContactId => $composableBuilder(
      column: $table.deviceContactId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastVisit => $composableBuilder(
      column: $table.lastVisit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get birthday => $composableBuilder(
      column: $table.birthday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showNotes => $composableBuilder(
      column: $table.showNotes, builder: (column) => ColumnOrderings(column));
}

class $$LocalClientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalClientsTable> {
  $$LocalClientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get lastname =>
      $composableBuilder(column: $table.lastname, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get image =>
      $composableBuilder(column: $table.image, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<bool> get isFromDevice => $composableBuilder(
      column: $table.isFromDevice, builder: (column) => column);

  GeneratedColumn<String> get deviceContactId => $composableBuilder(
      column: $table.deviceContactId, builder: (column) => column);

  GeneratedColumn<String> get lastVisit =>
      $composableBuilder(column: $table.lastVisit, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get birthday =>
      $composableBuilder(column: $table.birthday, builder: (column) => column);

  GeneratedColumn<bool> get showNotes =>
      $composableBuilder(column: $table.showNotes, builder: (column) => column);
}

class $$LocalClientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalClientsTable,
    LocalClientRow,
    $$LocalClientsTableFilterComposer,
    $$LocalClientsTableOrderingComposer,
    $$LocalClientsTableAnnotationComposer,
    $$LocalClientsTableCreateCompanionBuilder,
    $$LocalClientsTableUpdateCompanionBuilder,
    (
      LocalClientRow,
      BaseReferences<_$AppDatabase, $LocalClientsTable, LocalClientRow>
    ),
    LocalClientRow,
    PrefetchHooks Function()> {
  $$LocalClientsTableTableManager(_$AppDatabase db, $LocalClientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalClientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalClientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalClientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> lastname = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String?> image = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<bool> isFromDevice = const Value.absent(),
            Value<String?> deviceContactId = const Value.absent(),
            Value<String?> lastVisit = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> updatedAt = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> birthday = const Value.absent(),
            Value<bool> showNotes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalClientsCompanion(
            id: id,
            name: name,
            lastname: lastname,
            email: email,
            phone: phone,
            image: image,
            address: address,
            isFromDevice: isFromDevice,
            deviceContactId: deviceContactId,
            lastVisit: lastVisit,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            notes: notes,
            birthday: birthday,
            showNotes: showNotes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> lastname = const Value.absent(),
            Value<String?> email = const Value.absent(),
            required String phone,
            Value<String?> image = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<bool> isFromDevice = const Value.absent(),
            Value<String?> deviceContactId = const Value.absent(),
            Value<String?> lastVisit = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> updatedAt = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> birthday = const Value.absent(),
            Value<bool> showNotes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalClientsCompanion.insert(
            id: id,
            name: name,
            lastname: lastname,
            email: email,
            phone: phone,
            image: image,
            address: address,
            isFromDevice: isFromDevice,
            deviceContactId: deviceContactId,
            lastVisit: lastVisit,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            notes: notes,
            birthday: birthday,
            showNotes: showNotes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalClientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalClientsTable,
    LocalClientRow,
    $$LocalClientsTableFilterComposer,
    $$LocalClientsTableOrderingComposer,
    $$LocalClientsTableAnnotationComposer,
    $$LocalClientsTableCreateCompanionBuilder,
    $$LocalClientsTableUpdateCompanionBuilder,
    (
      LocalClientRow,
      BaseReferences<_$AppDatabase, $LocalClientsTable, LocalClientRow>
    ),
    LocalClientRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
  $$IdRemapsTableTableManager get idRemaps =>
      $$IdRemapsTableTableManager(_db, _db.idRemaps);
  $$LocalClientsTableTableManager get localClients =>
      $$LocalClientsTableTableManager(_db, _db.localClients);
}
