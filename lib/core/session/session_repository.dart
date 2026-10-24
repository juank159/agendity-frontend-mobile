import 'dart:convert';

import 'package:login_signup/core/session/token_store.dart';

/// Roles que firma el backend (`backend/src/auth/jwt/jwt.role.ts`).
abstract final class SessionRole {
  static const admin = 'Admin';
  static const owner = 'Owner';
  static const employee = 'Employee';
}

/// Datos de la sesión sacados del JWT. Inmutable y sin Flutter.
///
/// `tenantId`/`ownerId` son `null` en tokens anteriores a la 2.01: la app no
/// los necesita para hablar con el backend (los saca de la BD); solo son
/// informativos.
class Session {
  final String token;
  final String userId;
  final String? name;
  final String? email;
  final List<String> roles;
  final String? tenantId;
  final String? ownerId;
  final DateTime? expiresAt;

  const Session({
    required this.token,
    required this.userId,
    this.name,
    this.email,
    this.roles = const [],
    this.tenantId,
    this.ownerId,
    this.expiresAt,
  });

  bool hasRole(String role) => roles.contains(role);
  bool get isOwner => hasRole(SessionRole.owner);
  bool get isAdmin => hasRole(SessionRole.admin);

  /// Employee que no es Owner (misma regla que `isOnlyEmployee` del backend).
  bool get isOnlyEmployee => hasRole(SessionRole.employee) && !isOwner;

  /// Sin `exp` no se considera vencido (lo decide el backend con un 401).
  bool isExpiredAt(DateTime now) =>
      expiresAt != null && !now.isBefore(expiresAt!);

  @override
  bool operator ==(Object other) => other is Session && other.token == token;

  @override
  int get hashCode => token.hashCode;

  @override
  String toString() => 'Session(userId: $userId, roles: $roles, '
      'tenantId: $tenantId, expiresAt: $expiresAt)';
}

/// **Único** sitio que decodifica el JWT (no verifica la firma: eso es del
/// backend). Decodifica una sola vez por token y guarda el resultado.
class SessionRepository {
  final TokenStore _tokenStore;
  final DateTime Function() _now;

  String? _cachedToken;
  Session? _cachedSession;

  SessionRepository(this._tokenStore, {DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  /// Sesión del token guardado, también si está vencida (mirar `isExpiredAt`).
  /// `null` si no hay token o está malformado.
  Future<Session?> readSession() async {
    final token = await _tokenStore.readToken();
    if (token == null) return _cache(null, null);
    if (token == _cachedToken) return _cachedSession;
    return _cache(token, decode(token));
  }

  /// Sesión usable: existe, se puede leer y no ha vencido.
  Future<Session?> activeSession() async {
    final session = await readSession();
    if (session == null || session.isExpiredAt(_now())) return null;
    return session;
  }

  Session? _cache(String? token, Session? session) {
    _cachedToken = token;
    _cachedSession = session;
    return session;
  }

  /// Decodifica el payload de un JWT. `null` si no es un JWT válido o no
  /// trae el id del usuario.
  static Session? decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final Object? payload;
    try {
      payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    } on FormatException {
      return null;
    }
    if (payload is! Map) return null;

    final userId = _string(payload['id']) ?? _string(payload['sub']);
    if (userId == null) return null;

    final exp = payload['exp'];
    return Session(
      token: token,
      userId: userId,
      name: _string(payload['name']),
      email: _string(payload['email']),
      roles: _roles(payload['roles']),
      tenantId: _string(payload['tenantId']),
      ownerId: _string(payload['ownerId']),
      expiresAt: exp is num
          ? DateTime.fromMillisecondsSinceEpoch((exp * 1000).round(),
              isUtc: true)
          : null,
    );
  }

  static String? _string(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  /// `roles` es una lista de nombres; tokens muy viejos pueden traer un texto
  /// suelto o una lista de `{name}`.
  static List<String> _roles(Object? raw) {
    if (raw is String) return raw.isEmpty ? const [] : [raw];
    if (raw is! List) return const [];
    return List.unmodifiable(raw
        .map((role) => role is Map ? role['name'] : role)
        .whereType<String>());
  }
}
