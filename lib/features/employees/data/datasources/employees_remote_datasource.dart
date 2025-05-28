import 'package:dio/dio.dart';
import 'package:login_signup/features/employees/data/models/employee_model.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';
import 'package:login_signup/core/errors/failures.dart';

class EmployeesRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;

  // Endpoints separados para plural y singular
  static const String endpointPlural = '/auth/employees';
  static const String endpointSingular = '/auth/employee';
  static const String endpointRegister = '/auth/register/employee';

  EmployeesRemoteDataSource({
    required this.dio,
    required this.localStorage,
  });

  Future<List<EmployeeModel>> getEmployees(
      {bool includeDeleted = false}) async {
    try {
      final token = await localStorage.getToken();

      // Construir URL con parámetros
      String url = endpointPlural;
      if (includeDeleted) {
        url += '?includeDeleted=true';
      }

      print('Obteniendo empleados desde: $url');

      final response = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final employeesList = (response.data as List)
            .map((json) => EmployeeModel.fromJson(json))
            .toList();

        // Log para depuración
        print('📊 Empleados obtenidos: ${employeesList.length}');
        for (var emp in employeesList) {
          print(
              '👤 ${emp.name} ${emp.lastname} - Activo: ${emp.isActive}, Eliminado: ${emp.isDeleted}');
          if (emp.schedule != null) {
            print('   Horario: ${emp.schedule}');
          }
        }

        return employeesList;
      }
      throw ServerFailure(message: 'Failed to load employees');
    } catch (e) {
      print('Error al cargar empleados: $e');

      if (e is DioException) {
        if (e.response != null) {
          throw ServerFailure(
              message: 'Error del servidor: ${e.response!.statusCode}');
        }
        throw NetworkFailure(
            message: 'Error de conexión a internet: ${e.message}');
      }

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(
          message: 'Error al cargar empleados: ${e.toString()}');
    }
  }

  Future<EmployeeModel> getEmployeeById(String id) async {
    try {
      final token = await localStorage.getToken();
      final url = '$endpointSingular/$id';
      print('Obteniendo empleado desde: $url');

      final response = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        print('Empleado obtenido con éxito: ${response.data}');
        final employee = EmployeeModel.fromJson(response.data);
        print('Horario del empleado obtenido: ${employee.schedule}');
        return employee;
      }
      throw ServerFailure(message: 'Employee not found');
    } catch (e) {
      print('Error al obtener empleado con ID $id: $e');

      if (e is DioException) {
        if (e.response != null) {
          if (e.response!.statusCode == 404) {
            throw ServerFailure(message: 'Empleado no encontrado');
          }
          throw ServerFailure(
              message: 'Error del servidor: ${e.response!.statusCode}');
        }
        throw NetworkFailure(
            message: 'Error de conexión a internet: ${e.message}');
      }

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(
          message: 'Error al obtener empleado: ${e.toString()}');
    }
  }

  Future<List<EmployeeModel>> getActiveEmployees() async {
    try {
      final token = await localStorage.getToken();
      final url = '$endpointPlural/active';

      print('📋 Obteniendo empleados activos desde: $url');

      final response = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final employeesList = (response.data as List)
            .map((json) => EmployeeModel.fromJson(json))
            .toList();

        print('✅ Empleados activos obtenidos: ${employeesList.length}');
        return employeesList;
      }

      throw ServerFailure(message: 'Error al cargar empleados activos');
    } catch (e) {
      print('❌ Error cargando empleados activos: $e');

      if (e is DioException) {
        if (e.response != null) {
          throw ServerFailure(
              message: 'Error del servidor: ${e.response!.statusCode}');
        }
        throw NetworkFailure(message: 'Error de conexión: ${e.message}');
      }

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(message: 'Error al cargar empleados activos');
    }
  }

  Future<EmployeeModel> createEmployee(
      EmployeeEntity employee, String password) async {
    try {
      final token = await localStorage.getToken();

      // Preparar datos para la petición
      final Map<String, dynamic> data =
          (employee as EmployeeModel).toCreateJson(password: password);

      print('Enviando datos al servidor: $data');
      print('Enviando horario: ${data['schedule']}');

      final response = await dio.post(
        endpointRegister,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Respuesta del servidor: ${response.data}');
        if (response.data['user'] != null) {
          return EmployeeModel.fromJson(response.data['user']);
        }
        return EmployeeModel.fromJson(response.data);
      }

      throw 'Error al crear profesional';
    } on DioException catch (e) {
      print('DioException: ${e.toString()}');
      print('Response: ${e.response?.statusCode} - ${e.response?.data}');

      // SOLUCIÓN DIRECTA: Usar el mensaje exacto del servidor para errores 409
      if (e.response != null && e.response!.statusCode == 409) {
        if (e.response!.data is Map) {
          Map<String, dynamic> errorData =
              e.response!.data as Map<String, dynamic>;
          if (errorData.containsKey('message')) {
            throw errorData[
                'message']; // Lanzar directamente el mensaje del servidor
          }
        }
      }

      throw 'Error de conexión con el servidor'; // Mensaje genérico para otros errores
    } catch (e) {
      print('Otro tipo de error: ${e.toString()}');

      // Simplemente propagar cualquier error
      rethrow;
    }
  }

  Future<List<EmployeeModel>> getDeletedEmployees() async {
    try {
      final token = await localStorage.getToken();
      final url = '$endpointPlural/deleted';

      print('🗑️ Obteniendo empleados eliminados desde: $url');

      final response = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final employeesList = (response.data as List)
            .map((json) => EmployeeModel.fromJson(json))
            .toList();

        print('✅ Empleados eliminados obtenidos: ${employeesList.length}');
        return employeesList;
      }

      throw ServerFailure(message: 'Error al cargar empleados eliminados');
    } catch (e) {
      print('❌ Error cargando empleados eliminados: $e');

      if (e is DioException) {
        if (e.response != null) {
          throw ServerFailure(
              message: 'Error del servidor: ${e.response!.statusCode}');
        }
        throw NetworkFailure(message: 'Error de conexión: ${e.message}');
      }

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(message: 'Error al cargar empleados eliminados');
    }
  }

  Future<EmployeeModel> updateEmployee(String id, EmployeeEntity employee,
      {String? password,
      Map<String, ServiceAssignment>? serviceAssignments}) async {
    try {
      final token = await localStorage.getToken();
      final url = '$endpointSingular/$id';

      // Datos básicos
      final Map<String, dynamic> data = {
        'name': employee.name,
        'lastname': employee.lastname,
        'email': employee.email,
        'phone': employee.phone,
      };

      // Añadir horario si existe
      if (employee.schedule != null && employee.schedule!.isNotEmpty) {
        data['schedule'] = employee.schedule;
      }

      // Añadir contraseña si se proporciona
      if (password != null && password.isNotEmpty) {
        data['password'] = password;
      }

      // AÑADIR SERVICIOS
      if (serviceAssignments != null && serviceAssignments.isNotEmpty) {
        print('⭐ PROCESANDO SERVICIOS: ${serviceAssignments.length} servicios');

        // Crear array de servicios
        List<Map<String, dynamic>> servicesArray = [];

        // Añadir cada servicio al array
        serviceAssignments.forEach((serviceId, assignment) {
          Map<String, dynamic> serviceData = {
            'serviceId': serviceId,
            'commissionPercentage': assignment.commissionPercentage,
            'isActive': true
          };

          if (assignment.customPrice != null) {
            serviceData['customPrice'] = assignment.customPrice;
          }

          servicesArray.add(serviceData);
          print(
              '⭐ Añadido servicio: $serviceId con comisión: ${assignment.commissionPercentage}');
        });

        // Añadir array de servicios a los datos de la petición
        data['services'] = servicesArray;

        print('⭐ SERVICIOS AÑADIDOS A LA PETICIÓN: ${servicesArray.length}');
        print('⭐ Datos de servicios: $servicesArray');
      } else {
        print('⚠️ NO HAY SERVICIOS PARA AÑADIR A LA PETICIÓN');
      }

      // Log completo de datos
      print('⭐ ENVIANDO DATOS AL SERVIDOR: $data');

      // Hacer la petición HTTP
      final response = await dio.patch(
        url,
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Verificar respuesta
      if (response.statusCode == 200) {
        print('✅ ÉXITO: Empleado actualizado correctamente');
        print('✅ RESPUESTA SERVIDOR: ${response.data}');

        // Parsear respuesta
        if (response.data['user'] != null) {
          return EmployeeModel.fromJson(response.data['user']);
        }
        return EmployeeModel.fromJson(response.data);
      }

      throw ServerFailure(
          message: 'Failed to update employee: ${response.statusCode}');
    } catch (e) {
      print('❌ ERROR ACTUALIZACIÓN: $e');

      // Manejar errores específicos (similar al método createEmployee)
      if (e is DioException) {
        if (e.response != null) {
          final statusCode = e.response!.statusCode;

          if (statusCode == 409) {
            if (e.response!.data is Map<String, dynamic> &&
                e.response!.data['message'] != null) {
              final String errorMessage = e.response!.data['message'];

              if (errorMessage.contains('email')) {
                final RegExp emailRegex = RegExp(r'email: ([^\s,]+)');
                final match = emailRegex.firstMatch(errorMessage);
                final String email = match?.group(1) ?? employee.email;

                return Future.error(
                    DuplicateEmailFailure(email: email, message: errorMessage));
              } else if (errorMessage.contains('teléfono')) {
                final RegExp phoneRegex = RegExp(r'teléfono: (\d+)');
                final match = phoneRegex.firstMatch(errorMessage);
                final String phone = match?.group(1) ?? employee.phone;

                return Future.error(
                    DuplicatePhoneFailure(phone: phone, message: errorMessage));
              }

              return Future.error(ServerFailure(message: errorMessage));
            }
          }

          return Future.error(
              ServerFailure(message: 'Error del servidor: ${statusCode}'));
        }

        return Future.error(
            NetworkFailure(message: 'Error de conexión: ${e.message}'));
      }

      if (e is Failure) {
        return Future.error(e);
      }

      return Future.error(ServerFailure(
          message: 'Error al actualizar empleado: ${e.toString()}'));
    }
  }

  Future<EmployeeModel> toggleEmployeeStatus(String id, bool isActive) async {
    try {
      final token = await localStorage.getToken();
      final url = '$endpointSingular/$id/status';

      print('Actualizando estado del empleado en: $url');
      print('Nuevo estado: $isActive');

      final response = await dio.patch(
        url,
        data: {'isActive': isActive},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        print('Estado del empleado actualizado con éxito');
        // Verificar la estructura de la respuesta
        if (response.data['user'] != null) {
          return EmployeeModel.fromJson(response.data['user']);
        }
        return EmployeeModel.fromJson(response.data);
      }

      throw ServerFailure(
          message: 'Failed to update employee status: ${response.statusCode}');
    } catch (e) {
      print('Error al actualizar estado del empleado con ID $id: $e');

      if (e is DioException) {
        if (e.response != null) {
          throw ServerFailure(
              message: 'Error del servidor: ${e.response!.statusCode}');
        }
        throw NetworkFailure(
            message: 'Error de conexión a internet: ${e.message}');
      }

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(
          message: 'Error al actualizar estado del empleado: ${e.toString()}');
    }
  }

  Future<bool> verifyEmployeeEmail(String employeeId, String code) async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.post(
        '/auth/verify/employee-email',
        data: {
          'employee_id': employeeId,
          'code': code,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      print('Error al verificar email de empleado: $e');

      if (e is DioException) {
        if (e.response != null) {
          if (e.response!.statusCode == 400) {
            throw ServerFailure(message: 'Código de verificación inválido');
          }
          throw ServerFailure(
              message: 'Error del servidor: ${e.response!.statusCode}');
        }
        throw NetworkFailure(
            message: 'Error de conexión a internet: ${e.message}');
      }

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(
          message: 'Error al verificar email de empleado: ${e.toString()}');
    }
  }

  Future<bool> deleteEmployee(String id, {String? reason}) async {
    try {
      final token = await localStorage.getToken();
      final url = '$endpointSingular/$id';

      print('🚀 Eliminando empleado en: $url');
      if (reason != null && reason.isNotEmpty) {
        print('📝 Razón: $reason');
      }

      // Preparar datos para enviar razón si existe
      final Map<String, dynamic>? data =
          reason != null && reason.isNotEmpty ? {'reason': reason} : null;

      final response = await dio.delete(
        url,
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        print('✅ Empleado eliminado con éxito (soft delete)');
        return true;
      }

      throw ServerFailure(message: 'Error al eliminar empleado');
    } on DioException catch (e) {
      print('❌ DioException capturado');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('📋 Response Data: ${e.response?.data}');

      if (e.response != null && e.response!.statusCode == 403) {
        final responseData = e.response!.data;

        String serverMessage = 'No se puede eliminar al dueño del negocio';
        if (responseData is Map<String, dynamic> &&
            responseData['message'] != null) {
          serverMessage = responseData['message'].toString();
        }

        print('🚫 Error 403 detectado - Mensaje: $serverMessage');
        throw OwnerDeletionFailure(message: serverMessage);
      }

      if (e.response != null && e.response!.statusCode == 409) {
        final responseData = e.response!.data;
        String message = 'El empleado ya ha sido eliminado previamente';
        if (responseData is Map<String, dynamic> &&
            responseData['message'] != null) {
          message = responseData['message'].toString();
        }
        print('🔄 Error 409 - Empleado ya eliminado');
        throw AlreadyDeletedFailure(employeeId: id, message: message);
      }

      if (e.response != null && e.response!.statusCode == 404) {
        print('🔍 Error 404 - Empleado no encontrado');
        throw NotFoundFailure(message: 'Empleado no encontrado');
      }

      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Error del servidor';
        if (responseData is Map<String, dynamic> &&
            responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
        throw ServerFailure(message: errorMessage);
      }

      throw NetworkFailure(message: 'Sin conexión a internet');
    } catch (e) {
      if (e is OwnerDeletionFailure ||
          e is AlreadyDeletedFailure ||
          e is NotFoundFailure ||
          e is NetworkFailure ||
          e is ServerFailure) {
        rethrow;
      }

      print('💥 Error inesperado: $e');
      throw ServerFailure(message: 'Error inesperado al eliminar empleado');
    }
  }

  Future<bool> restoreEmployee(String id) async {
    try {
      final token = await localStorage.getToken();
      final url = '$endpointSingular/$id/restore';

      print('♻️ Restaurando empleado en: $url');

      final response = await dio.patch(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        print('✅ Empleado restaurado con éxito');
        return true;
      }

      throw ServerFailure(message: 'Error al restaurar empleado');
    } on DioException catch (e) {
      print('❌ Error restaurando empleado');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('📋 Response Data: ${e.response?.data}');

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;

        if (statusCode == 404) {
          print('🔍 Empleado eliminado no encontrado');
          throw NotFoundFailure(message: 'Empleado eliminado no encontrado');
        }

        if (statusCode == 409) {
          String message = 'El empleado no está eliminado';
          if (responseData is Map<String, dynamic> &&
              responseData['message'] != null) {
            message = responseData['message'].toString();
          }
          print('⚠️ Empleado no está eliminado');
          throw NotDeletedFailure(employeeId: id, message: message);
        }

        if (statusCode == 403) {
          String message = 'No tienes permisos para restaurar este empleado';
          if (responseData is Map<String, dynamic> &&
              responseData['message'] != null) {
            message = responseData['message'].toString();
          }
          throw ServerFailure(message: message);
        }

        // Error genérico del servidor
        String errorMessage = 'Error del servidor';
        if (responseData is Map<String, dynamic> &&
            responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
        throw ServerFailure(message: errorMessage);
      }

      throw NetworkFailure(message: 'Error de conexión: ${e.message}');
    } catch (e) {
      if (e is RestoreFailure ||
          e is NotFoundFailure ||
          e is NotDeletedFailure ||
          e is NetworkFailure ||
          e is ServerFailure) {
        rethrow;
      }

      print('💥 Error inesperado restaurando: $e');
      throw RestoreFailure(
          employeeId: id, message: 'Error inesperado al restaurar empleado');
    }
  }
}
