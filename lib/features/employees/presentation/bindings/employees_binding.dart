import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/di/modules/employees_module.dart';
import 'package:login_signup/core/di/modules/services_module.dart';
import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/repositories/employees_repository_impl.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/create_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';

class EmployeesBinding implements Bindings {
  @override
  void dependencies() {
    try {
      print('Inicializando EmployeesBinding...');

      // Registrar dependencias en orden específico
      _initServicesModule();
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

  void _initServicesModule() {
    try {
      // Inicializar ServicesModule si es necesario
      if (!Get.isRegistered<GetServicesUseCase>()) {
        print('Inicializando ServicesModule...');
        ServicesModule.init();
      }

      // Asegurarse de que el ServicesController esté disponible
      if (!Get.isRegistered<ServicesController>()) {
        print('Registrando ServicesController...');
        Get.put(
          ServicesController(getServicesUseCase: Get.find()),
          permanent: true,
        );
      }
    } catch (e) {
      print('Error inicializando ServicesModule: $e');
      rethrow;
    }
  }

  void _initEmployeesModule() {
    try {
      EmployeesModule.init();
      print('Registrando dependencias de Employees...');

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

      // Registrar Use Cases
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

      // Registrar Controller
      print('Registrando EmployeesController...');
      if (!Get.isRegistered<EmployeesController>()) {
        Get.put<EmployeesController>(
          EmployeesController(
            getEmployeesUseCase: Get.find(),
            getEmployeeByIdUseCase: Get.find(),
            createEmployeeUseCase: Get.find(),
          ),
          permanent: true,
        );
      }
    } catch (e) {
      print('Error inicializando EmployeesModule: $e');
    }
  }
}
