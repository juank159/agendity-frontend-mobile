import 'package:dio/dio.dart';
import 'package:login_signup/core/network/interceptors/auth_interceptor.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/employees/data/models/employee_input_model.dart';
import 'package:login_signup/features/employees/data/models/employee_model.dart';
import 'package:login_signup/features/employees/data/models/employee_restoration_model.dart';

/// Rutas de profesionales en `/auth` (todas solo para el Owner, salvo
/// `verify/request-code`, que es pública). Los errores (400/401/403/404/409,
/// red) salen como `DioException` y los traduce `safeCall` en el repositorio.
abstract class EmployeesRemoteDataSource {
  /// `GET /auth/employees`: el Owner y sus empleados sin baja.
  Future<List<EmployeeModel>> getEmployees();

  /// `GET /auth/employees/deleted`.
  Future<List<EmployeeModel>> getDeletedEmployees();

  /// `GET /auth/employee/:id`.
  Future<EmployeeModel> getEmployeeById(String id);

  /// `POST /auth/register/employee`. Responde 201 `{user}` (sin token).
  Future<EmployeeModel> createEmployee(EmployeeInputModel body);

  /// `PATCH /auth/employee/:id`. Responde 200 con el profesional.
  Future<EmployeeModel> updateEmployee(String id, EmployeeInputModel body);

  /// `PATCH /auth/employee/:id/status` con `{isActive}`.
  Future<void> setEmployeeActive(String id, bool isActive);

  /// `DELETE /auth/employee/:id` con `{reason?}` (soft-delete).
  Future<void> deleteEmployee(String id, {String? reason});

  /// `PATCH /auth/employee/:id/restore`.
  Future<EmployeeRestorationModel> restoreEmployee(String id);

  /// `POST /auth/verify/request-code` con `{email}` (pública).
  Future<void> requestVerificationCode(String email);

  /// `POST /auth/verify/employee-email` con `{employee_id, code}`. Un código
  /// incorrecto responde 401: la petición se marca para no cerrar la sesión.
  Future<void> verifyEmployeeEmail(String employeeId, String code);
}

class EmployeesRemoteDataSourceImpl implements EmployeesRemoteDataSource {
  static const _employees = '/auth/employees';
  static const _employee = '/auth/employee';

  final Dio _dio;

  /// Debe ser el Dio `tag: apiClientTag` (token y errores del núcleo).
  EmployeesRemoteDataSourceImpl(this._dio);

  @override
  Future<List<EmployeeModel>> getEmployees() => _list(_employees);

  @override
  Future<List<EmployeeModel>> getDeletedEmployees() =>
      _list('$_employees/deleted');

  @override
  Future<EmployeeModel> getEmployeeById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('$_employee/$id');
    return EmployeeModel.fromJson(response.data!);
  }

  @override
  Future<EmployeeModel> createEmployee(EmployeeInputModel body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register/employee',
      data: body.toCreateJson(),
    );
    final data = response.data!;
    return EmployeeModel.fromJson(JsonRead.asMap(data['user']) ?? data);
  }

  @override
  Future<EmployeeModel> updateEmployee(
      String id, EmployeeInputModel body) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_employee/$id',
      data: body.toUpdateJson(),
    );
    return EmployeeModel.fromJson(response.data!);
  }

  @override
  Future<void> setEmployeeActive(String id, bool isActive) async {
    await _dio.patch<void>('$_employee/$id/status',
        data: {'isActive': isActive});
  }

  @override
  Future<void> deleteEmployee(String id, {String? reason}) async {
    await _dio.delete<void>('$_employee/$id',
        data: reason == null ? null : {'reason': reason});
  }

  @override
  Future<EmployeeRestorationModel> restoreEmployee(String id) async {
    final response =
        await _dio.patch<Map<String, dynamic>>('$_employee/$id/restore');
    return EmployeeRestorationModel.fromJson(response.data ?? const {},
        fallbackId: id);
  }

  @override
  Future<void> requestVerificationCode(String email) async {
    await _dio.post<void>(
      '/auth/verify/request-code',
      data: {'email': email},
      options: Options(extra: {AuthInterceptor.publicKey: true}),
    );
  }

  @override
  Future<void> verifyEmployeeEmail(String employeeId, String code) async {
    await _dio.post<void>(
      '/auth/verify/employee-email',
      data: {'employee_id': employeeId, 'code': code},
      options: Options(extra: {AuthInterceptor.keepSessionOn401Key: true}),
    );
  }

  Future<List<EmployeeModel>> _list(String path) async {
    final response = await _dio.get<List<dynamic>>(path);
    return JsonRead.asMapList(response.data)
        .map(EmployeeModel.fromJson)
        .toList();
  }
}
