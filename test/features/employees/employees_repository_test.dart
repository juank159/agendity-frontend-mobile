import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/repositories/employees_repository_impl.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/features/employees/domain/entities/work_hours.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/usecases/create_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/delete_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/employee_rules.dart';
import 'package:login_signup/features/employees/domain/usecases/get_deleted_employees_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/request_employee_verification_code_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/restore_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/toggle_employee_status_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/update_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/verify_employee_email_usecase.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';
import 'employee_model_test.dart' show backendDeletedEmployee, backendEmployee;

Failure? leftOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => null);

T rightOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('Left: ${leftOf(result)}'));

ResponseBody errorBody(int status, String code, String message) =>
    jsonBody(status, {'statusCode': status, 'code': code, 'message': message});

const form = EmployeeInput(
  name: '  Laura  ',
  lastname: 'Gómez ',
  email: ' laura@example.com ',
  phone: '+57 300-123 4567',
  password: 'Secreta1!',
  services: {
    'svc-1': ServiceAssignment(serviceId: 'svc-1', commissionPercentage: 40),
  },
  schedule: {'monday': WorkHours(start: '09:00:00', end: '18:00')},
);

void main() {
  late FakeHttpClientAdapter adapter;
  late EmployeesRepositoryImpl repository;
  late int expiredSessions;

  setUp(() {
    adapter = FakeHttpClientAdapter((_) => jsonBody(200, {}));
    expiredSessions = 0;
    final dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: MemoryTokenStore('jwt'),
      onSessionExpired: (_) => expiredSessions++,
      httpClientAdapter: adapter,
      retryDelay: (_) => Duration.zero,
      enableLogs: false,
    );
    repository = EmployeesRepositoryImpl(EmployeesRemoteDataSourceImpl(dio));
  });

  group('lectura', () {
    test('GET /auth/employees: entidades, token del núcleo y sin tenant-id',
        () async {
      adapter.handler = (_) => jsonBody(200, [
            backendEmployee(id: 'owner-1', isOwner: true),
            backendEmployee(isActive: false, verified: false),
          ]);

      final employees =
          rightOf(await GetEmployeesUseCase(repository)(NoParams()));
      expect(employees.map((e) => e.isOwner), [true, false]);
      expect(employees.last.status, EmployeeStatus.pendingVerification);

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/auth/employees');
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(request.headers.containsKey('tenant-id'), false);
    });

    test('GET /auth/employees/deleted', () async {
      adapter.handler = (_) => jsonBody(200, [backendDeletedEmployee()]);
      final deleted =
          rightOf(await GetDeletedEmployeesUseCase(repository)(NoParams()));
      expect(deleted.single.isDeleted, true);
      expect(adapter.requests.single.uri.path, '/api/auth/employees/deleted');
    });

    test('GET /auth/employee/:id; ajeno o de baja → NotFoundFailure',
        () async {
      adapter.handler = (_) => jsonBody(200, backendEmployee());
      expect(rightOf(await GetEmployeeByIdUseCase(repository)('emp-1')).id,
          'emp-1');
      expect(adapter.requests.single.uri.path, '/api/auth/employee/emp-1');

      adapter.handler =
          (_) => errorBody(404, 'NOT_FOUND', 'Empleado no encontrado');
      expect(leftOf(await repository.getEmployeeById('emp-x')),
          isA<NotFoundFailure>());
    });

    test('403 del Employee (rutas solo del Owner) → ForbiddenFailure',
        () async {
      adapter.handler = (_) => errorBody(403, 'FORBIDDEN', 'Acceso denegado');
      final failure = leftOf(await repository.getEmployees());
      expect(failure, isA<ForbiddenFailure>());
      expect(failure!.code, 'FORBIDDEN');
      expect(expiredSessions, 0);
    });

    test('sin conexión → NetworkFailure (tras los reintentos del GET)',
        () async {
      adapter.handler = connectionError;
      expect(leftOf(await repository.getEmployees()), isA<NetworkFailure>());
      expect(adapter.requests.length, greaterThan(1));
    });
  });

  group('alta', () {
    test('POST normalizado; nace inactivo y sin verificar; respuesta {user}',
        () async {
      adapter.handler = (_) => jsonBody(201, {
            'user': backendEmployee(isActive: false, verified: false)
              ..remove('services'),
          });

      final created = rightOf(await CreateEmployeeUseCase(repository)(form));
      expect(created.isActive, false);
      expect(created.isEmailVerified, false);
      expect(created.status, EmployeeStatus.pendingVerification);
      expect(created.canBeScheduled, false);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/auth/register/employee');
      expect(request.data, {
        'name': 'Laura',
        'lastname': 'Gómez',
        'email': 'laura@example.com',
        'phone': '3001234567',
        'password': 'Secreta1!',
        'services': [
          {'serviceId': 'svc-1', 'commissionPercentage': 40.0}
        ],
        'schedule': {
          'monday': {'start': '09:00', 'end': '18:00'}
        },
      });
    });

    test('datos inválidos → InvalidEmployeeDataFailure sin red', () async {
      const bad = EmployeeInput(
        name: 'L',
        lastname: 'Gómez3',
        email: 'no-es-email',
        phone: '12345',
        password: 'debil',
        services: {
          'svc-1':
              ServiceAssignment(serviceId: 'svc-1', commissionPercentage: 120)
        },
        schedule: {'monday': WorkHours(start: '18:00', end: '09:00')},
      );
      final failure = leftOf(await CreateEmployeeUseCase(repository)(bad));
      expect(failure, isA<InvalidEmployeeDataFailure>());
      expect(failure!.details, [
        EmployeeRules.nameInvalid,
        EmployeeRules.lastnameInvalid,
        EmployeeRules.emailInvalid,
        EmployeeRules.phoneInvalid,
        EmployeeRules.passwordWeak,
        EmployeeRules.commissionInvalid,
        EmployeeRules.scheduleInvalid,
      ]);
      expect(adapter.requests, isEmpty);
    });

    test('sin contraseña → InvalidEmployeeDataFailure', () async {
      final failure = leftOf(await CreateEmployeeUseCase(repository)(
          EmployeeInput(
              name: form.name,
              lastname: form.lastname,
              email: form.email,
              phone: form.phone)));
      expect(failure!.details, [EmployeeRules.passwordRequired]);
    });

    test('email repetido (409 DUPLICATE_EMAIL) → DuplicateEmailFailure',
        () async {
      adapter.handler = (_) => errorBody(409, 'DUPLICATE_EMAIL',
          'Ya existe un usuario con el email: laura@example.com');
      final failure = leftOf(await CreateEmployeeUseCase(repository)(form));
      expect(failure, isA<DuplicateEmailFailure>());
      expect((failure as DuplicateEmailFailure).email, 'laura@example.com');
      expect(failure.message,
          'Ya existe un usuario con el email: laura@example.com');
    });

    test('teléfono repetido (409 DUPLICATE_PHONE) → DuplicatePhoneFailure',
        () async {
      adapter.handler = (_) => errorBody(409, 'DUPLICATE_PHONE',
          'Ya existe un usuario con el teléfono: 3001234567');
      final failure = leftOf(await CreateEmployeeUseCase(repository)(form));
      expect((failure as DuplicatePhoneFailure).phone, '3001234567');
    });

    test('un POST no se reintenta ante un error de red', () async {
      adapter.handler = connectionError;
      expect(leftOf(await CreateEmployeeUseCase(repository)(form)),
          isA<NetworkFailure>());
      expect(adapter.requests.length, 1);
    });
  });

  group('edición', () {
    test('PATCH sin contraseña si no se cambia', () async {
      adapter.handler = (_) => jsonBody(200, backendEmployee());
      final input = EmployeeInput(
        name: form.name,
        lastname: form.lastname,
        email: form.email,
        phone: form.phone,
        services: form.services,
        schedule: form.schedule,
      );
      final updated = rightOf(await UpdateEmployeeUseCase(repository)(
          UpdateEmployeeParams(id: 'emp-1', input: input)));
      expect(updated.id, 'emp-1');

      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.uri.path, '/api/auth/employee/emp-1');
      expect((request.data as Map).containsKey('password'), false);
      expect((request.data as Map)['lastname'], 'Gómez');
    });

    test('sin id → InvalidEmployeeDataFailure sin red', () async {
      final failure = leftOf(await UpdateEmployeeUseCase(repository)(
          const UpdateEmployeeParams(id: ' ', input: form)));
      expect(failure!.details, contains(UpdateEmployeeUseCase.missingId));
      expect(adapter.requests, isEmpty);
    });

    test('email de otro usuario → DuplicateEmailFailure', () async {
      adapter.handler = (_) => errorBody(409, 'DUPLICATE_EMAIL',
          'Ya existe un usuario con el email: laura@example.com');
      expect(
          leftOf(await UpdateEmployeeUseCase(repository)(
              const UpdateEmployeeParams(id: 'emp-1', input: form))),
          isA<DuplicateEmailFailure>());
    });
  });

  group('estado', () {
    test('activar: PATCH /status con {isActive: true}', () async {
      adapter.handler = (_) => jsonBody(200, backendEmployee());
      final result = await ToggleEmployeeStatusUseCase(repository)(
          const ToggleEmployeeStatusParams(employeeId: 'emp-1', isActive: true));
      expect(rightOf(result), unit);

      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.uri.path, '/api/auth/employee/emp-1/status');
      expect(request.data, {'isActive': true});
    });

    test('activar sin el email verificado (409) → EmployeeEmailNotVerifiedFailure',
        () async {
      adapter.handler = (_) => errorBody(409, 'EMAIL_NOT_VERIFIED',
          'El profesional debe verificar su email antes de activarse');
      final failure = leftOf(await ToggleEmployeeStatusUseCase(repository)(
          const ToggleEmployeeStatusParams(employeeId: 'emp-1', isActive: true)));
      expect(failure, isA<EmployeeEmailNotVerifiedFailure>());
      expect(failure, isA<ConflictFailure>());
      expect(failure!.message,
          'El profesional debe verificar su email antes de activarse');
    });

    test('otro 409 (CONFLICT) se queda genérico', () async {
      adapter.handler = (_) => errorBody(409, 'CONFLICT', 'Conflicto');
      final failure = leftOf(await repository.setEmployeeActive('emp-1', true));
      expect(failure.runtimeType, ConflictFailure);
    });
  });

  group('baja y restauración', () {
    test('DELETE con motivo recortado (soft-delete)', () async {
      adapter.handler = (_) => jsonBody(200, {
            'message': 'Profesional eliminado correctamente',
            'id': 'emp-1',
            'deletedAt': '2026-10-27T10:00:00.000-05:00',
            'reason': 'Renuncia',
          });
      final result = await DeleteEmployeeUseCase(repository)(
          const DeleteEmployeeParams(employeeId: 'emp-1', reason: ' Renuncia '));
      expect(rightOf(result), unit);

      final request = adapter.requests.single;
      expect(request.method, 'DELETE');
      expect(request.uri.path, '/api/auth/employee/emp-1');
      expect(request.data, {'reason': 'Renuncia'});
    });

    test('DELETE sin motivo no envía cuerpo', () async {
      await DeleteEmployeeUseCase(repository)(
          const DeleteEmployeeParams(employeeId: 'emp-1', reason: '  '));
      expect(adapter.requests.single.data, isNull);
    });

    test('ya dado de baja, o el Owner (404) → NotFoundFailure', () async {
      adapter.handler =
          (_) => errorBody(404, 'NOT_FOUND', 'Empleado no encontrado');
      expect(leftOf(await repository.deleteEmployee('owner-1')),
          isA<NotFoundFailure>());
    });

    test('OWNER_NOT_DELETABLE con su HTTP legado (403) decide por code',
        () async {
      adapter.handler = (_) => errorBody(
          403, 'OWNER_NOT_DELETABLE', 'No se puede eliminar al dueño del negocio');
      final failure = leftOf(await repository.deleteEmployee('owner-1'));
      expect(failure, isA<ConflictFailure>());
      expect(failure!.message, 'No se puede eliminar al dueño del negocio');
    });

    test('restaurar sin email verificado → queda inactivo', () async {
      adapter.handler = (_) => jsonBody(200, {
            'message':
                'Empleado restaurado. Debe verificar su email para activarse',
            'id': 'emp-9',
            'isActive': false,
            'restoredAt': '2026-10-27T10:00:00.000-05:00',
          });
      final restoration =
          rightOf(await RestoreEmployeeUseCase(repository)('emp-9'));
      expect(restoration.isActive, false);
      expect(restoration.needsEmailVerification, true);

      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.uri.path, '/api/auth/employee/emp-9/restore');
    });

    test('restaurar uno que no está dado de baja (404) → NotFoundFailure',
        () async {
      adapter.handler = (_) =>
          errorBody(404, 'NOT_FOUND', 'Empleado eliminado no encontrado');
      expect(leftOf(await RestoreEmployeeUseCase(repository)('emp-1')),
          isA<NotFoundFailure>());
    });
  });

  group('verificación del email', () {
    test('pedir código: ruta pública, sin token', () async {
      adapter.handler =
          (_) => jsonBody(201, {'message': 'Código de verificación enviado'});
      expect(
          rightOf(await RequestEmployeeVerificationCodeUseCase(repository)(
              ' laura@example.com ')),
          unit);

      final request = adapter.requests.single;
      expect(request.uri.path, '/api/auth/verify/request-code');
      expect(request.data, {'email': 'laura@example.com'});
      expect(request.headers.containsKey('Authorization'), false);
    });

    test('pedir código con un email inválido → sin red', () async {
      expect(
          leftOf(await RequestEmployeeVerificationCodeUseCase(repository)('x')),
          isA<InvalidEmployeeDataFailure>());
      expect(adapter.requests, isEmpty);
    });

    test('demasiadas peticiones (429) → TooManyRequestsFailure', () async {
      adapter.handler = (_) =>
          errorBody(429, 'TOO_MANY_REQUESTS', 'Demasiadas solicitudes');
      expect(
          leftOf(await RequestEmployeeVerificationCodeUseCase(repository)(
              'laura@example.com')),
          isA<TooManyRequestsFailure>());
    });

    test('verificar: POST con employee_id y code, con la sesión del Owner',
        () async {
      adapter.handler = (_) => jsonBody(201, {
            'message': 'Email verificado y empleado activado correctamente',
            'is_verified': true,
          });
      final result = await VerifyEmployeeEmailUseCase(repository)(
          const VerifyEmployeeEmailParams(employeeId: 'emp-1', code: '123456'));
      expect(rightOf(result), unit);

      final request = adapter.requests.single;
      expect(request.uri.path, '/api/auth/verify/employee-email');
      expect(request.data, {'employee_id': 'emp-1', 'code': '123456'});
      expect(request.headers['Authorization'], 'Bearer jwt');
    });

    test('código incorrecto (400 INVALID_VERIFICATION_CODE) → failure propio',
        () async {
      adapter.handler = (_) => errorBody(400, 'INVALID_VERIFICATION_CODE',
          'El código de verificación ha expirado');
      final failure = leftOf(await VerifyEmployeeEmailUseCase(repository)(
          const VerifyEmployeeEmailParams(employeeId: 'emp-1', code: '000000')));
      expect(failure, isA<InvalidVerificationCodeFailure>());
      expect(failure!.message, 'El código de verificación ha expirado');
      expect(failure.code, 'INVALID_VERIFICATION_CODE');
      expect(expiredSessions, 0);
    });

    test('código con formato inválido → sin red', () async {
      final failure = leftOf(await VerifyEmployeeEmailUseCase(repository)(
          const VerifyEmployeeEmailParams(employeeId: 'emp-1', code: '12a')));
      expect(failure!.message, EmployeeRules.codeInvalid);
      expect(adapter.requests, isEmpty);
    });
  });

  test('un 401 al verificar es la sesión vencida: avisa y no es "código inválido"',
      () async {
    adapter.handler = (_) => errorBody(401, 'UNAUTHORIZED', 'No autorizado');
    final failure = leftOf(await VerifyEmployeeEmailUseCase(repository)(
        const VerifyEmployeeEmailParams(employeeId: 'emp-1', code: '123456')));
    expect(failure, isA<UnauthorizedFailure>());
    expect(expiredSessions, 1);
  });

  test('un 401 normal (token vencido) sí avisa de la sesión expirada',
      () async {
    adapter.handler = (_) => errorBody(401, 'UNAUTHORIZED', 'No autorizado');
    expect(leftOf(await repository.getEmployees()),
        isA<UnauthorizedFailure>());
    expect(expiredSessions, 1);
  });
}
