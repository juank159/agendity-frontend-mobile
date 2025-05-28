import 'package:get/get.dart';
import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/repositories/employees_repository_impl.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/create_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/delete_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_deleted_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/restore_employee_use_case.dart';
import 'package:login_signup/features/employees/domain/usecases/toggle_employee_status_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/update_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/verify_employee_email_usecase.dart';
// 🆕 NUEVOS IMPORTS agregados

import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';

class EmployeesModule {
  // 🔧 APLICANDO DRY: Lista de casos de uso para evitar repetición
  static final Map<Type, Function> _useCases = {};
  static EmployeesRepository? _repository;
  static EmployeesRemoteDataSource? _remoteDataSource;

  static Future<void> init() async {
    try {
      print('🏗️ Inicializando EmployeesModule...');

      // Verificar si ya está inicializado
      if (Get.isRegistered<EmployeesController>()) {
        print('✅ EmployeesModule ya inicializado');
        return;
      }

      // Inicializar dependencias en orden
      await _initDataLayer();
      await _initDomainLayer();
      await _initPresentationLayer();

      print('✅ EmployeesModule inicializado exitosamente');
    } catch (e) {
      print('❌ Error al inicializar EmployeesModule: $e');
      rethrow;
    }
  }

  // 🔧 DRY: Método para inicializar capa de datos
  static Future<void> _initDataLayer() async {
    try {
      print('📊 Inicializando capa de datos...');

      // DataSource
      if (!Get.isRegistered<EmployeesRemoteDataSource>()) {
        _remoteDataSource = EmployeesRemoteDataSource(
          dio: Get.find(),
          localStorage: Get.find(),
        );
        Get.put<EmployeesRemoteDataSource>(_remoteDataSource!, permanent: true);
      } else {
        _remoteDataSource = Get.find<EmployeesRemoteDataSource>();
      }

      // Repository
      if (!Get.isRegistered<EmployeesRepository>()) {
        _repository = EmployeesRepositoryImpl(_remoteDataSource!);
        Get.put<EmployeesRepository>(_repository!, permanent: true);
      } else {
        _repository = Get.find<EmployeesRepository>();
      }

      print('✅ Capa de datos inicializada');
    } catch (e) {
      print('❌ Error inicializando capa de datos: $e');
      rethrow;
    }
  }

  // 🔧 DRY: Método para inicializar capa de dominio
  static Future<void> _initDomainLayer() async {
    try {
      print('🎯 Inicializando capa de dominio...');

      // 🔧 CORRECCIÓN: Registrar cada caso de uso individualmente sin tags

      // GetEmployeesUseCase
      if (!Get.isRegistered<GetEmployeesUseCase>()) {
        final getEmployeesUseCase = GetEmployeesUseCase(_repository!);
        Get.put<GetEmployeesUseCase>(getEmployeesUseCase, permanent: true);
        print('✅ Registrado: GetEmployeesUseCase');
      }

      // GetEmployeeByIdUseCase
      if (!Get.isRegistered<GetEmployeeByIdUseCase>()) {
        final getEmployeeByIdUseCase = GetEmployeeByIdUseCase(_repository!);
        Get.put<GetEmployeeByIdUseCase>(getEmployeeByIdUseCase,
            permanent: true);
        print('✅ Registrado: GetEmployeeByIdUseCase');
      }

      // CreateEmployeeUseCase
      if (!Get.isRegistered<CreateEmployeeUseCase>()) {
        final createEmployeeUseCase = CreateEmployeeUseCase(_repository!);
        Get.put<CreateEmployeeUseCase>(createEmployeeUseCase, permanent: true);
        print('✅ Registrado: CreateEmployeeUseCase');
      }

      // UpdateEmployeeUseCase
      if (!Get.isRegistered<UpdateEmployeeUseCase>()) {
        final updateEmployeeUseCase = UpdateEmployeeUseCase(_repository!);
        Get.put<UpdateEmployeeUseCase>(updateEmployeeUseCase, permanent: true);
        print('✅ Registrado: UpdateEmployeeUseCase');
      }

      // DeleteEmployeeUseCase
      if (!Get.isRegistered<DeleteEmployeeUseCase>()) {
        final deleteEmployeeUseCase = DeleteEmployeeUseCase(_repository!);
        Get.put<DeleteEmployeeUseCase>(deleteEmployeeUseCase, permanent: true);
        print('✅ Registrado: DeleteEmployeeUseCase');
      }

      // ToggleEmployeeStatusUseCase
      if (!Get.isRegistered<ToggleEmployeeStatusUseCase>()) {
        final toggleEmployeeStatusUseCase =
            ToggleEmployeeStatusUseCase(_repository!);
        Get.put<ToggleEmployeeStatusUseCase>(toggleEmployeeStatusUseCase,
            permanent: true);
        print('✅ Registrado: ToggleEmployeeStatusUseCase');
      }

      // VerifyEmployeeEmailUseCase
      if (!Get.isRegistered<VerifyEmployeeEmailUseCase>()) {
        final verifyEmployeeEmailUseCase =
            VerifyEmployeeEmailUseCase(_repository!);
        Get.put<VerifyEmployeeEmailUseCase>(verifyEmployeeEmailUseCase,
            permanent: true);
        print('✅ Registrado: VerifyEmployeeEmailUseCase');
      }

      // 🆕 RestoreEmployeeUseCase
      if (!Get.isRegistered<RestoreEmployeeUseCase>()) {
        final restoreEmployeeUseCase = RestoreEmployeeUseCase(_repository!);
        Get.put<RestoreEmployeeUseCase>(restoreEmployeeUseCase,
            permanent: true);
        print('✅ Registrado: RestoreEmployeeUseCase');
      }

      // 🆕 GetDeletedEmployeesUseCase
      if (!Get.isRegistered<GetDeletedEmployeesUseCase>()) {
        final getDeletedEmployeesUseCase =
            GetDeletedEmployeesUseCase(_repository!);
        Get.put<GetDeletedEmployeesUseCase>(getDeletedEmployeesUseCase,
            permanent: true);
        print('✅ Registrado: GetDeletedEmployeesUseCase');
      }

      print('✅ Capa de dominio inicializada con 9 casos de uso');
    } catch (e) {
      print('❌ Error inicializando capa de dominio: $e');
      rethrow;
    }
  }

  // 🔧 DRY: Método para inicializar capa de presentación
  static Future<void> _initPresentationLayer() async {
    try {
      print('🎨 Inicializando capa de presentación...');

      // Controller con todas las dependencias
      if (!Get.isRegistered<EmployeesController>()) {
        final controller = EmployeesController(
          getEmployeesUseCase: Get.find<GetEmployeesUseCase>(),
          getEmployeeByIdUseCase: Get.find<GetEmployeeByIdUseCase>(),
          createEmployeeUseCase: Get.find<CreateEmployeeUseCase>(),
          updateEmployeeUseCase: Get.find<UpdateEmployeeUseCase>(),
          deleteEmployeeUseCase: Get.find<DeleteEmployeeUseCase>(),
          toggleEmployeeStatusUseCase: Get.find<ToggleEmployeeStatusUseCase>(),
          // 🆕 NUEVAS dependencias
          restoreEmployeeUseCase: Get.find<RestoreEmployeeUseCase>(),
          getDeletedEmployeesUseCase: Get.find<GetDeletedEmployeesUseCase>(),
        );

        Get.put<EmployeesController>(controller, permanent: true);
        print('✅ EmployeesController registrado');
      }

      print('✅ Capa de presentación inicializada');
    } catch (e) {
      print('❌ Error inicializando capa de presentación: $e');
      rethrow;
    }
  }

  static void reset() {
    try {
      print('🧹 Reseteando EmployeesModule...');

      // Lista de tipos a eliminar en orden inverso (SIN TAGS)
      final typesToDelete = [
        EmployeesController,
        GetDeletedEmployeesUseCase, // 🆕 NUEVO
        RestoreEmployeeUseCase, // 🆕 NUEVO
        VerifyEmployeeEmailUseCase,
        ToggleEmployeeStatusUseCase,
        DeleteEmployeeUseCase,
        UpdateEmployeeUseCase,
        CreateEmployeeUseCase,
        GetEmployeeByIdUseCase,
        GetEmployeesUseCase,
        EmployeesRepository,
        EmployeesRemoteDataSource,
      ];

      // 🔧 CORRECCIÓN: Eliminar sin usar tags
      for (final type in typesToDelete) {
        try {
          Get.delete<dynamic>(force: true);
          print('🗑️ Limpiado: ${type.toString()}');
        } catch (e) {
          // Continuar aunque falle la eliminación de un tipo específico
          print('⚠️ No se pudo eliminar: ${type.toString()}');
        }
      }

      // Limpiar referencias internas
      _useCases.clear();
      _repository = null;
      _remoteDataSource = null;

      print('✅ EmployeesModule reseteado correctamente');
    } catch (e) {
      print('❌ Error al resetear EmployeesModule: $e');
      rethrow;
    }
  }

  // 🆕 NUEVO: Método para verificar estado del módulo
  static bool get isInitialized => Get.isRegistered<EmployeesController>();

  // 🆕 NUEVO: Método para obtener estadísticas del módulo
  static Map<String, dynamic> getModuleStats() {
    return {
      'initialized': isInitialized,
      'useCasesRegistered': _useCases.length,
      'hasRepository': _repository != null,
      'hasRemoteDataSource': _remoteDataSource != null,
      'registeredTypes': _useCases.keys.map((e) => e.toString()).toList(),
    };
  }

  // 🆕 NUEVO: Método para forzar reinicialización
  static Future<void> reinitialize() async {
    print('🔄 Reinicializando EmployeesModule...');
    reset();
    await init();
    print('✅ EmployeesModule reinicializado');
  }
}
