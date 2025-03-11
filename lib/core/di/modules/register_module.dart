// lib/core/di/modules/register_module.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../core/network/network_info.dart';
import '../../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../../features/auth/data/repositories/register_repository_impl.dart';
import '../../../features/auth/domain/repositories/register_repository.dart';
import '../../../features/auth/domain/usecases/register_usecase.dart';
import '../../../shared/local_storage/local_storage.dart';

class RegisterModule {
  static Future<void> init() async {
    try {
      // Asegurarnos que las dependencias básicas estén disponibles
      if (!Get.isRegistered<Dio>()) {
        throw Exception('Dio no está inicializado');
      }

      if (!Get.isRegistered<LocalStorage>()) {
        throw Exception('LocalStorage no está inicializado');
      }

      // Registrar el repositorio
      if (!Get.isRegistered<RegisterRepository>()) {
        Get.put<RegisterRepository>(
          RegisterRepositoryImpl(
            remoteDataSource: Get.find<AuthRemoteDataSource>(),
            localStorage: Get.find<LocalStorage>(),
          ),
          permanent: true,
        );
        print('RegisterRepository registrado correctamente');
      }

      // Registrar el caso de uso
      if (!Get.isRegistered<RegisterUseCase>()) {
        Get.put<RegisterUseCase>(
          RegisterUseCase(Get.find<RegisterRepository>()),
          permanent: true,
        );
        print('RegisterUseCase registrado correctamente');
      }

      print('Módulo de Registro inicializado correctamente');
    } catch (e) {
      print('Error al inicializar el módulo de Registro: $e');
      rethrow;
    }
  }
}
