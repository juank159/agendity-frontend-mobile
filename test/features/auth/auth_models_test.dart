import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/features/auth/data/models/user_model.dart';
import 'package:login_signup/features/auth/domain/entities/user_entity.dart';

/// `user` de las respuestas de auth (`transformUserResponse` del backend).
Map<String, dynamic> backendUser({
  String id = 'own-1',
  Object? phone = '3001234567',
  List<Object?> roles = const [
    {'name': 'Owner'}
  ],
}) =>
    {
      'id': id,
      'name': 'Ana',
      'lastname': 'Pérez',
      'email': 'ana@example.com',
      'phone': phone,
      'image': null,
      'is_email_verified': false,
      'isActive': true,
      'is_google_account': false,
      'tenant_id': id,
      'created_at': '2026-10-21T08:00:00.000-05:00',
      'roles': roles,
    };

/// `{user, token}` de login, registro y Google.
Map<String, dynamic> backendAuth(String token, {Map<String, dynamic>? user}) =>
    {'user': user ?? backendUser(), 'token': token};

void main() {
  test('UserModel: usuario tipado con roles por nombre', () {
    final entity = UserModel.fromJson(backendUser()).toEntity();
    expect(
        entity,
        const UserEntity(
          id: 'own-1',
          name: 'Ana',
          lastname: 'Pérez',
          email: 'ana@example.com',
          phone: '3001234567',
          roles: ['Owner'],
        ));
    expect(entity.fullName, 'Ana Pérez');
  });

  test('UserModel: cuenta de Google sin teléfono y roles en texto', () {
    final entity = UserModel.fromJson({
      ...backendUser(phone: null, roles: ['Owner', null, '  ']),
      'is_email_verified': true,
    }).toEntity();
    expect(entity.phone, isNull);
    expect(entity.roles, ['Owner']);
    expect(entity.isEmailVerified, true);
  });

  group('AuthResponseModel', () {
    test('user + token', () {
      final model = AuthResponseModel.fromJson(backendAuth('jwt.x.y'));
      expect(model.token, 'jwt.x.y');
      expect(model.user.id, 'own-1');
    });

    test('sin token o sin usuario → FormatException', () {
      expect(() => AuthResponseModel.fromJson({'user': backendUser()}),
          throwsFormatException);
      expect(() => AuthResponseModel.fromJson({'token': 'a.b.c'}),
          throwsFormatException);
      expect(
          () => AuthResponseModel.fromJson(
              backendAuth('a.b.c', user: backendUser(id: ''))),
          throwsFormatException);
      expect(() => AuthResponseModel.fromJson(null), throwsFormatException);
    });
  });
}
