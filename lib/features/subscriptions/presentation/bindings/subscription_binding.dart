// lib/features/subscriptions/presentation/bindings/subscription_binding.dart

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:login_signup/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_status_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/create_paid_subscription_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/get_all_plans_usecase.dart';
import 'package:login_signup/features/subscriptions/presentation/controllers/subscription_controller.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    print('Inicializando SubscriptionBinding...');

    try {
      // DataSource
      if (!Get.isRegistered<SubscriptionRemoteDataSource>()) {
        print('Registrando SubscriptionRemoteDataSource');
        Get.put<SubscriptionRemoteDataSource>(
          SubscriptionRemoteDataSource(
            dio: Get.find<Dio>(),
            localStorage: Get.find<LocalStorage>(),
          ),
        );
      } else {
        print('SubscriptionRemoteDataSource ya está registrado');
      }

      // Repository
      if (!Get.isRegistered<SubscriptionRepository>()) {
        print('Registrando SubscriptionRepository');
        Get.put<SubscriptionRepository>(
          SubscriptionRepositoryImpl(
            remoteDataSource: Get.find<SubscriptionRemoteDataSource>(),
          ),
        );
      } else {
        print('SubscriptionRepository ya está registrado');
      }

      // Use Cases
      if (!Get.isRegistered<CheckSubscriptionStatusUseCase>()) {
        print('Registrando CheckSubscriptionStatusUseCase');
        Get.put<CheckSubscriptionStatusUseCase>(
          CheckSubscriptionStatusUseCase(
            Get.find<SubscriptionRepository>(),
          ),
        );
      } else {
        print('CheckSubscriptionStatusUseCase ya está registrado');
      }

      if (!Get.isRegistered<GetAllPlansUseCase>()) {
        print('Registrando GetAllPlansUseCase');
        Get.put<GetAllPlansUseCase>(
          GetAllPlansUseCase(
            Get.find<SubscriptionRepository>(),
          ),
        );
      } else {
        print('GetAllPlansUseCase ya está registrado');
      }

      if (!Get.isRegistered<CreatePaidSubscriptionUseCase>()) {
        print('Registrando CreatePaidSubscriptionUseCase');
        Get.put<CreatePaidSubscriptionUseCase>(
          CreatePaidSubscriptionUseCase(
            Get.find<SubscriptionRepository>(),
          ),
        );
      } else {
        print('CreatePaidSubscriptionUseCase ya está registrado');
      }

      // Controller
      if (!Get.isRegistered<SubscriptionController>()) {
        print('Registrando SubscriptionController');
        Get.put<SubscriptionController>(
          SubscriptionController(
            checkSubscriptionStatusUseCase:
                Get.find<CheckSubscriptionStatusUseCase>(),
            getAllPlansUseCase: Get.find<GetAllPlansUseCase>(),
            createPaidSubscriptionUseCase:
                Get.find<CreatePaidSubscriptionUseCase>(),
          ),
        );
      } else {
        print('SubscriptionController ya está registrado');
        // Como es final, no podemos modificar las propiedades
        // Si necesitas actualizar las referencias, tendrías que
        // reconstruir el controlador o modificar tu diseño
      }

      print('SubscriptionBinding inicializado correctamente');
    } catch (e) {
      print('Error al inicializar SubscriptionBinding: $e');

      // Intentar recuperar el error específico
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }

      // Esto debería asegurar que al menos se intente registrar el controlador
      // si aún no está registrado
      try {
        if (!Get.isRegistered<SubscriptionController>() &&
            Get.isRegistered<CheckSubscriptionStatusUseCase>() &&
            Get.isRegistered<GetAllPlansUseCase>() &&
            Get.isRegistered<CreatePaidSubscriptionUseCase>()) {
          print('Intentando registrar SubscriptionController después de error');
          Get.put<SubscriptionController>(
            SubscriptionController(
              checkSubscriptionStatusUseCase:
                  Get.find<CheckSubscriptionStatusUseCase>(),
              getAllPlansUseCase: Get.find<GetAllPlansUseCase>(),
              createPaidSubscriptionUseCase:
                  Get.find<CreatePaidSubscriptionUseCase>(),
            ),
          );
        }
      } catch (innerError) {
        print('Error adicional al intentar recuperarse: $innerError');
      }
    }
  }
}
