import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';

class ServicesController extends GetxController {
  final ServicesRepository repository;
  final RxList<ServiceEntity> services = <ServiceEntity>[].obs;
  final RxBool isLoading = true.obs;

  ServicesController({required this.repository});

  @override
  void onInit() {
    super.onInit();
    loadServices();
  }

  Future<void> loadServices() async {
    try {
      isLoading.value = true;
      final result = await repository.getServices();
      services.assignAll(result);
      print('Servicios cargados: ${services.length}');
    } catch (e) {
      print('Error cargando servicios: $e');
      Get.snackbar(
        'Error',
        'No se pudieron cargar los servicios: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
