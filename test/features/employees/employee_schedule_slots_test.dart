import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/features/employees/data/datasources/employees_local_datasource.dart';
import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/models/employee_input_model.dart';
import 'package:login_signup/features/employees/data/models/employee_model.dart';
import 'package:login_signup/features/employees/data/repositories/employees_repository_impl.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/employee_rules.dart';
import 'package:login_signup/features/employees/domain/usecases/update_employee_usecase.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';
import '../../core/sync/fake_sync_api.dart';
import 'employee_model_test.dart' show backendEmployee;

const morning = WorkHours(start: '10:00', end: '12:00');
const afternoon = WorkHours(start: '16:00', end: '18:00');

/// Horario del empleado con varias franjas por día (13.05, backend 13.04).
void main() {
  group('EmployeeModel: lectura del horario', () {
    test('schedule_slots (todas las franjas) gana a schedule (la primera)', () {
      final employee = EmployeeModel.fromJson({
        ...backendEmployee(),
        'schedule_slots': {
          'monday': [
            {'start': '16:00', 'end': '18:00'},
            {'start': '10:00:00', 'end': '12:00:00'},
          ],
          'tuesday': [],
          'otro': [
            {'start': '09:00', 'end': '10:00'}
          ],
        },
        'schedule': {
          'monday': {'start': '10:00', 'end': '12:00'},
        },
      }).toEntity();

      // Ordenadas por inicio; sin días vacíos ni desconocidos.
      expect(employee.schedule, {
        'monday': [morning, afternoon],
      });
      expect(employee.hoursOn('monday'), [morning, afternoon]);
      expect(employee.hoursOn('tuesday'), isEmpty);
    });

    test('schedule_slots vacío = sin horario (no cae al formato anterior)', () {
      final employee = EmployeeModel.fromJson({
        ...backendEmployee(),
        'schedule_slots': <String, dynamic>{},
        'schedule': <String, dynamic>{},
      }).toEntity();
      expect(employee.schedule, isEmpty);
    });

    test('solo schedule (backend anterior a 13.04): una franja por día', () {
      final employee = EmployeeModel.fromJson(backendEmployee()).toEntity();
      expect(employee.schedule, {
        'monday': [const WorkHours(start: '09:00', end: '18:00')],
        'saturday': [const WorkHours(start: '08:00', end: '12:30')],
      });
    });

    test(
        'filas crudas (base local, /deleted): todas las del día, sin las de '
        'is_available = false', () {
      final employee = EmployeeModel.fromJson({
        'id': 'emp-1',
        'name': 'Laura',
        'lastname': 'Gómez',
        'email': 'laura@example.com',
        'isActive': true,
        'schedules': [
          {
            'day_of_week': 1,
            'start_time': '16:00:00',
            'end_time': '18:00:00',
            'is_available': true,
          },
          {
            'day_of_week': 1,
            'start_time': '10:00:00',
            'end_time': '12:00:00',
            'is_available': true,
          },
          // No disponibilidad: no es horario de trabajo.
          {
            'day_of_week': 1,
            'start_time': '12:00:00',
            'end_time': '16:00:00',
            'is_available': false,
          },
          {
            'day_of_week': 3,
            'start_time': '09:00:00',
            'end_time': '13:00:00',
            'is_available': false,
          },
          // Sin la columna (respuesta antigua de /deleted) cuenta como sí.
          {'day_of_week': 2, 'start_time': '09:00:00', 'end_time': '13:00:00'},
          {'day_of_week': 9, 'start_time': '09:00:00', 'end_time': '13:00:00'},
        ],
      }).toEntity();

      expect(employee.schedule, {
        'monday': [morning, afternoon],
        'tuesday': [const WorkHours(start: '09:00', end: '13:00')],
      });
    });

    test('base local: los documentos de schedules arman las dos franjas',
        () async {
      final databases = memoryDatabases();
      addTearDown(databases.close);
      final db = await databases.require();
      await DocumentStore.put(db, SharedDocs.users, 'emp-1', {
        'id': 'emp-1',
        'name': 'Laura',
        'lastname': 'Gómez',
        'isActive': true,
        'roles': [
          {'name': 'Employee'}
        ],
      });
      var n = 0;
      for (final (start, end, available) in [
        ('10:00:00', '12:00:00', true),
        ('16:00:00', '18:00:00', true),
        ('12:00:00', '16:00:00', false),
      ]) {
        await DocumentStore.put(db, SharedDocs.schedules, 'sch-${++n}', {
          'id': 'sch-$n',
          'user': 'emp-1',
          'day_of_week': 1,
          'start_time': start,
          'end_time': end,
          'is_available': available,
        });
      }

      final laura =
          await const EmployeesLocalDataSource().employee(db, 'emp-1');
      expect(laura!.schedule, {
        'monday': [morning, afternoon],
      });
    });
  });

  group('EmployeeInputModel: el PATCH envía las franjas', () {
    test('siete días: la lista exacta de cada uno, [] = libre', () {
      final json = EmployeeInputModel.fromEntity(const EmployeeInput(
        name: 'Laura',
        lastname: 'Gómez',
        email: 'laura@example.com',
        phone: '3001234567',
        schedule: {
          'monday': [morning, afternoon],
          'friday': [WorkHours(start: '09:00', end: '13:00')],
        },
      )).toUpdateJson();

      expect(json['schedule'], {
        'monday': [
          {'start': '10:00', 'end': '12:00'},
          {'start': '16:00', 'end': '18:00'},
        ],
        'tuesday': [],
        'wednesday': [],
        'thursday': [],
        'friday': [
          {'start': '09:00', 'end': '13:00'},
        ],
        'saturday': [],
        'sunday': [],
      });
    });

    test(
        'editar solo el nombre de un empleado con 10–12 y 16–18 conserva la '
        'tarde (repositorio → PATCH)', () async {
      final adapter = FakeHttpClientAdapter((_) => jsonBody(200, {
            ...backendEmployee(),
            'schedule_slots': {
              'monday': [
                {'start': '10:00', 'end': '12:00'},
                {'start': '16:00', 'end': '18:00'},
              ],
            },
          }));
      final dio = buildApiClient(
        baseUrl: 'http://api.test/api',
        tokenStore: MemoryTokenStore('jwt'),
        httpClientAdapter: adapter,
        retryDelay: (_) => Duration.zero,
        enableLogs: false,
      );
      final databases = memoryDatabases();
      addTearDown(databases.close);
      final repository = EmployeesRepositoryImpl(
        EmployeesRemoteDataSourceImpl(dio),
        store: OfflineStore(databases: databases),
        refresh: () async {},
      );
      const current = EmployeeEntity(
        id: 'emp-1',
        name: 'Laura',
        lastname: 'Gómez',
        email: 'laura@example.com',
        phone: '3001234567',
        isActive: true,
        serviceAssignments: {
          'svc-1': ServiceAssignment(serviceId: 'svc-1'),
        },
        schedule: {
          'monday': [morning, afternoon],
        },
      );

      // Lo que hace el formulario: los mismos datos con otro nombre.
      final result = await UpdateEmployeeUseCase(repository)(
        UpdateEmployeeParams(
          id: current.id,
          input: EmployeeInput(
            name: 'Laurita',
            lastname: current.lastname,
            email: current.email,
            phone: current.phone,
            services: current.serviceAssignments,
            schedule: current.schedule,
          ),
        ),
      );

      expect(result.isRight(), isTrue);
      final body = adapter.requests.single.data as Map;
      expect(body['name'], 'Laurita');
      expect((body['schedule'] as Map)['monday'], [
        {'start': '10:00', 'end': '12:00'},
        {'start': '16:00', 'end': '18:00'},
      ]);
      expect(
          result.getOrElse(() => throw StateError('left')).hoursOn('monday'),
          [morning, afternoon]);
    });
  });

  group('EmployeeRules: franjas', () {
    EmployeeInput input(Map<String, List<WorkHours>> schedule) => EmployeeInput(
          name: 'Laura',
          lastname: 'Gómez',
          email: 'laura@example.com',
          phone: '3001234567',
          schedule: schedule,
        );

    List<String> check(Map<String, List<WorkHours>> schedule) =>
        EmployeeRules.check(EmployeeRules.normalize(input(schedule)),
            requirePassword: false);

    test('dos franjas que no se pisan (o que solo se tocan) valen', () {
      expect(check({
        'monday': [afternoon, morning],
        'tuesday': [
          const WorkHours(start: '09:00', end: '13:00'),
          const WorkHours(start: '13:00', end: '18:00'),
        ],
      }), isEmpty);
    });

    test('franjas del mismo día que se pisan → scheduleOverlap', () {
      expect(check({
        'monday': [
          const WorkHours(start: '10:00', end: '13:00'),
          const WorkHours(start: '12:00', end: '18:00'),
        ],
      }), [EmployeeRules.scheduleOverlap]);
    });

    test('la misma hora en días distintos no es un solape', () {
      expect(check({
        'monday': [morning],
        'tuesday': [morning],
      }), isEmpty);
    });

    test('inicio no anterior al fin → scheduleInvalid', () {
      expect(check({
        'monday': [morning, const WorkHours(start: '18:00', end: '16:00')],
      }), [EmployeeRules.scheduleInvalid]);
      expect(check({
        'monday': [const WorkHours(start: '10:00', end: '10:00')],
      }), [EmployeeRules.scheduleInvalid]);
    });

    test('normalize: "HH:mm:ss" → "HH:mm", ordena y quita días vacíos', () {
      final normalized = EmployeeRules.normalize(input({
        'monday': [
          const WorkHours(start: '16:00:00', end: '18:00:00'),
          const WorkHours(start: '10:00', end: '12:00'),
        ],
        'tuesday': [],
      }));
      expect(normalized.schedule, {
        'monday': [morning, afternoon],
      });
    });

    test('el use case no llama al backend con un solape', () async {
      final repository = _NoCallsRepository();
      final result = await UpdateEmployeeUseCase(repository)(
          UpdateEmployeeParams(
              id: 'emp-1',
              input: input({
                'monday': [
                  const WorkHours(start: '10:00', end: '13:00'),
                  const WorkHours(start: '12:00', end: '18:00'),
                ],
              })));
      expect(result.fold((f) => f, (_) => null),
          isA<InvalidEmployeeDataFailure>());
    });
  });

  group('WorkHours', () {
    test('overlaps: [inicio, fin) cruzados; tocarse no cuenta', () {
      expect(morning.overlaps(const WorkHours(start: '11:00', end: '13:00')),
          isTrue);
      expect(morning.overlaps(const WorkHours(start: '12:00', end: '13:00')),
          isFalse);
      expect(morning.overlaps(const WorkHours(start: '08:00', end: '10:00')),
          isFalse);
      expect(morning.overlaps(const WorkHours(start: '09:00', end: '18:00')),
          isTrue);
    });
  });
}

class _NoCallsRepository implements EmployeesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('No debía llamar al repositorio');
}
