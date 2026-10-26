// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/core/di/modules/services_module.dart';
// import 'package:login_signup/features/auth/data/datasources/auth_remote_datasource.dart';
// import 'package:login_signup/features/auth/data/repositories/auth_repository_impl.dart';
// import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
// import 'package:login_signup/features/auth/domain/usecases/request_verification_code_usecase.dart';
// import 'package:login_signup/features/auth/domain/usecases/verify_email_usecase.dart';
// import 'package:login_signup/features/auth/presentation/controllers/email_verification_controller.dart';
// import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
// import 'package:login_signup/features/employees/data/repositories/employees_repository_impl.dart';
// import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
// import 'package:login_signup/features/employees/domain/usecases/create_employee_usecase.dart';
// import 'package:login_signup/features/employees/domain/usecases/delete_employee_usecase.dart';
// import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
// import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
// import 'package:login_signup/features/employees/domain/usecases/toggle_employee_status_usecase.dart';
// import 'package:login_signup/features/employees/domain/usecases/update_employee_usecase.dart';
// import 'package:login_signup/features/employees/domain/usecases/verify_employee_email_usecase.dart';
// import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
// import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';
// import 'package:login_signup/features/services/presentation/controller/services_controller.dart';
// import 'package:login_signup/shared/local_storage/local_storage.dart';

// class EmployeesBinding implements Bindings {
//   @override
//   void dependencies() {
//     try {
//       print('Inicializando EmployeesBinding...');

//       // Registrar dependencias en orden específico
//       _initServicesModule();
//       _initAuthModule(); // Registrar dependencias de auth primero
//       _initEmployeesModule();

//       print('EmployeesBinding inicializado correctamente');
//     } catch (e) {
//       print('Error en EmployeesBinding: $e');
//       // No uses rethrow, mejor maneja el error aquí
//       Get.snackbar(
//         'Error',
//         'No se pudieron cargar los datos de empleados',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   void _initServicesModule() {
//     try {
//       // Inicializar ServicesModule si es necesario
//       if (!Get.isRegistered<GetServicesUseCase>()) {
//         print('Inicializando ServicesModule...');
//         ServicesModule.init();
//       }

//       // Asegurarse de que el ServicesController esté disponible
//       if (!Get.isRegistered<ServicesController>()) {
//         print('Registrando ServicesController...');
//         Get.put(
//           ServicesController(getServicesUseCase: Get.find()),
//           permanent: true,
//         );
//       }
//     } catch (e) {
//       print('Error inicializando ServicesModule: $e');
//       rethrow;
//     }
//   }

//   void _initAuthModule() {
//     try {
//       // Verificar si ya están registradas las dependencias
//       if (Get.isRegistered<EmailVerificationController>()) {
//         print('AuthModule para verificación ya inicializado');
//         return;
//       }

//       // Asegurarse de que AuthRemoteDataSource está registrado
//       if (!Get.isRegistered<AuthRemoteDataSource>()) {
//         // Si necesitamos crear AuthRemoteDataSource, podríamos necesitar
//         // registrarlo aquí, pero normalmente ya debería estar disponible
//         print(
//             'AuthRemoteDataSource no encontrado, será necesario registrarlo primero');
//       }

//       // Registrar AuthRepository si no existe
//       if (!Get.isRegistered<AuthRepository>()) {
//         Get.put<AuthRepository>(
//           AuthRepositoryImpl(
//             remoteDataSource: Get.find<AuthRemoteDataSource>(),
//             localStorage: Get.find<LocalStorage>(),
//           ),
//           permanent: true,
//         );
//       }

//       // Registrar casos de uso necesarios
//       if (!Get.isRegistered<RequestVerificationCodeUseCase>()) {
//         Get.put<RequestVerificationCodeUseCase>(
//           RequestVerificationCodeUseCase(Get.find<AuthRepository>()),
//           permanent: true,
//         );
//       }

//       if (!Get.isRegistered<VerifyEmailUseCase>()) {
//         Get.put<VerifyEmailUseCase>(
//           VerifyEmailUseCase(Get.find<AuthRepository>()),
//           permanent: true,
//         );
//       }

//       // Registrar controlador
//       Get.put<EmailVerificationController>(
//         EmailVerificationController(
//           requestCodeUseCase: Get.find<RequestVerificationCodeUseCase>(),
//           verifyEmailUseCase: Get.find<VerifyEmailUseCase>(),
//         ),
//         permanent: true,
//       );

//       print('AuthModule para verificación inicializado correctamente');
//     } catch (e) {
//       print('Error inicializando AuthModule para verificación: $e');
//       rethrow;
//     }
//   }

//   void _initEmployeesModule() {
//     try {
//       // Registrar DataSource si no existe
//       if (!Get.isRegistered<EmployeesRemoteDataSource>()) {
//         Get.put<EmployeesRemoteDataSource>(
//           EmployeesRemoteDataSource(
//             dio: Get.find(),
//             localStorage: Get.find(),
//           ),
//           permanent: true,
//         );
//       }

//       // Registrar Repository si no existe
//       if (!Get.isRegistered<EmployeesRepository>()) {
//         Get.put<EmployeesRepository>(
//           EmployeesRepositoryImpl(Get.find()),
//           permanent: true,
//         );
//       }

//       // Registrar Use Cases
//       if (!Get.isRegistered<GetEmployeesUseCase>()) {
//         Get.put<GetEmployeesUseCase>(
//           GetEmployeesUseCase(Get.find()),
//           permanent: true,
//         );
//       }

//       if (!Get.isRegistered<GetEmployeeByIdUseCase>()) {
//         Get.put<GetEmployeeByIdUseCase>(
//           GetEmployeeByIdUseCase(Get.find()),
//           permanent: true,
//         );
//       }

//       if (!Get.isRegistered<CreateEmployeeUseCase>()) {
//         Get.put<CreateEmployeeUseCase>(
//           CreateEmployeeUseCase(Get.find()),
//           permanent: true,
//         );
//       }

//       if (!Get.isRegistered<UpdateEmployeeUseCase>()) {
//         Get.put<UpdateEmployeeUseCase>(
//           UpdateEmployeeUseCase(Get.find()),
//           permanent: true,
//         );
//       }

//       if (!Get.isRegistered<DeleteEmployeeUseCase>()) {
//         Get.put<DeleteEmployeeUseCase>(
//           DeleteEmployeeUseCase(Get.find()),
//           permanent: true,
//         );
//       }

//       // Registrar el caso de uso para toggle status
//       if (!Get.isRegistered<ToggleEmployeeStatusUseCase>()) {
//         Get.put<ToggleEmployeeStatusUseCase>(
//           ToggleEmployeeStatusUseCase(Get.find()),
//           permanent: true,
//         );
//       }

//       // Registrar el caso de uso para verificar email de empleados
//       if (!Get.isRegistered<VerifyEmployeeEmailUseCase>()) {
//         Get.put<VerifyEmployeeEmailUseCase>(
//           VerifyEmployeeEmailUseCase(Get.find()),
//           permanent: true,
//         );
//       }

//       // Registrar Controller
//       print('Registrando EmployeesController...');
//       if (!Get.isRegistered<EmployeesController>()) {
//         Get.put<EmployeesController>(
//           EmployeesController(
//             getEmployeesUseCase: Get.find(),
//             getEmployeeByIdUseCase: Get.find(),
//             createEmployeeUseCase: Get.find(),
//             updateEmployeeUseCase: Get.find(),
//             deleteEmployeeUseCase: Get.find(),
//             toggleEmployeeStatusUseCase: Get.find(),
//           ),
//           permanent: true,
//         );
//       }
//     } catch (e) {
//       print('Error inicializando EmployeesModule: $e');
//       rethrow;
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:login_signup/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
import 'package:login_signup/features/auth/domain/usecases/request_verification_code_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_controller.dart';
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
// 🆕 NUEVOS IMPORTS

import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/services/presentation/bindings/services_binding.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class EmployeesBinding implements Bindings {
  @override
  void dependencies() {
    try {
      print('Inicializando EmployeesBinding...');

      // Registrar dependencias en orden específico
      _initServicesModule();
      _initAuthModule(); // Registrar dependencias de auth primero
      _initEmployeesModule();

      print('EmployeesBinding inicializado correctamente');
    } catch (e) {
      print('Error en EmployeesBinding: $e');
      // No uses rethrow, mejor maneja el error aquí
      Get.snackbar(
        'Error',
        'No se pudieron cargar los datos de empleados',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Las pantallas de empleados listan los servicios del negocio.
  void _initServicesModule() => ServicesBinding.registerController();

  void _initAuthModule() {
    try {
      // Verificar si ya están registradas las dependencias
      if (Get.isRegistered<EmailVerificationController>()) {
        print('AuthModule para verificación ya inicializado');
        return;
      }

      // Asegurarse de que AuthRemoteDataSource está registrado
      if (!Get.isRegistered<AuthRemoteDataSource>()) {
        // Si necesitamos crear AuthRemoteDataSource, podríamos necesitar
        // registrarlo aquí, pero normalmente ya debería estar disponible
        print(
            'AuthRemoteDataSource no encontrado, será necesario registrarlo primero');
      }

      // Registrar AuthRepository si no existe
      if (!Get.isRegistered<AuthRepository>()) {
        Get.put<AuthRepository>(
          AuthRepositoryImpl(
            remoteDataSource: Get.find<AuthRemoteDataSource>(),
            localStorage: Get.find<LocalStorage>(),
          ),
          permanent: true,
        );
      }

      // Registrar casos de uso necesarios
      if (!Get.isRegistered<RequestVerificationCodeUseCase>()) {
        Get.put<RequestVerificationCodeUseCase>(
          RequestVerificationCodeUseCase(Get.find<AuthRepository>()),
          permanent: true,
        );
      }

      if (!Get.isRegistered<VerifyEmailUseCase>()) {
        Get.put<VerifyEmailUseCase>(
          VerifyEmailUseCase(Get.find<AuthRepository>()),
          permanent: true,
        );
      }

      // Registrar controlador
      Get.put<EmailVerificationController>(
        EmailVerificationController(
          requestCodeUseCase: Get.find<RequestVerificationCodeUseCase>(),
          verifyEmailUseCase: Get.find<VerifyEmailUseCase>(),
        ),
        permanent: true,
      );

      print('AuthModule para verificación inicializado correctamente');
    } catch (e) {
      print('Error inicializando AuthModule para verificación: $e');
      rethrow;
    }
  }

  void _initEmployeesModule() {
    try {
      // Registrar DataSource si no existe
      if (!Get.isRegistered<EmployeesRemoteDataSource>()) {
        Get.put<EmployeesRemoteDataSource>(
          EmployeesRemoteDataSource(
            dio: Get.find(),
            localStorage: Get.find(),
          ),
          permanent: true,
        );
      }

      // Registrar Repository si no existe
      if (!Get.isRegistered<EmployeesRepository>()) {
        Get.put<EmployeesRepository>(
          EmployeesRepositoryImpl(Get.find()),
          permanent: true,
        );
      }

      // Registrar Use Cases existentes
      if (!Get.isRegistered<GetEmployeesUseCase>()) {
        Get.put<GetEmployeesUseCase>(
          GetEmployeesUseCase(Get.find()),
          permanent: true,
        );
      }

      if (!Get.isRegistered<GetEmployeeByIdUseCase>()) {
        Get.put<GetEmployeeByIdUseCase>(
          GetEmployeeByIdUseCase(Get.find()),
          permanent: true,
        );
      }

      if (!Get.isRegistered<CreateEmployeeUseCase>()) {
        Get.put<CreateEmployeeUseCase>(
          CreateEmployeeUseCase(Get.find()),
          permanent: true,
        );
      }

      if (!Get.isRegistered<UpdateEmployeeUseCase>()) {
        Get.put<UpdateEmployeeUseCase>(
          UpdateEmployeeUseCase(Get.find()),
          permanent: true,
        );
      }

      if (!Get.isRegistered<DeleteEmployeeUseCase>()) {
        Get.put<DeleteEmployeeUseCase>(
          DeleteEmployeeUseCase(Get.find()),
          permanent: true,
        );
      }

      // Registrar el caso de uso para toggle status
      if (!Get.isRegistered<ToggleEmployeeStatusUseCase>()) {
        Get.put<ToggleEmployeeStatusUseCase>(
          ToggleEmployeeStatusUseCase(Get.find()),
          permanent: true,
        );
      }

      // Registrar el caso de uso para verificar email de empleados
      if (!Get.isRegistered<VerifyEmployeeEmailUseCase>()) {
        Get.put<VerifyEmployeeEmailUseCase>(
          VerifyEmployeeEmailUseCase(Get.find()),
          permanent: true,
        );
      }

      // 🆕 NUEVOS: Registrar casos de uso para soft delete
      if (!Get.isRegistered<RestoreEmployeeUseCase>()) {
        print('Registrando RestoreEmployeeUseCase...');
        Get.put<RestoreEmployeeUseCase>(
          RestoreEmployeeUseCase(Get.find()),
          permanent: true,
        );
      }

      if (!Get.isRegistered<GetDeletedEmployeesUseCase>()) {
        print('Registrando GetDeletedEmployeesUseCase...');
        Get.put<GetDeletedEmployeesUseCase>(
          GetDeletedEmployeesUseCase(Get.find()),
          permanent: true,
        );
      }

      // 🔄 ACTUALIZADO: Registrar Controller con nuevas dependencias
      print('Registrando EmployeesController...');
      if (!Get.isRegistered<EmployeesController>()) {
        Get.put<EmployeesController>(
          EmployeesController(
            getEmployeesUseCase: Get.find(),
            getEmployeeByIdUseCase: Get.find(),
            createEmployeeUseCase: Get.find(),
            updateEmployeeUseCase: Get.find(),
            deleteEmployeeUseCase: Get.find(),
            toggleEmployeeStatusUseCase: Get.find(),
            // 🆕 NUEVAS DEPENDENCIAS
            restoreEmployeeUseCase: Get.find(),
            getDeletedEmployeesUseCase: Get.find(),
          ),
          permanent: true,
        );
      }

      print('✅ EmployeesModule inicializado correctamente con soft delete');
    } catch (e) {
      print('❌ Error inicializando EmployeesModule: $e');
      rethrow;
    }
  }
}
