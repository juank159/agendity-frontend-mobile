import 'package:login_signup/features/services/domain/entities/service_entity.dart';

abstract class ServicesRepository {
  Future<List<ServiceEntity>> getServices();
  Future<void> createService(ServiceEntity service);
  Future<void> updateService(String id, ServiceEntity service);
  Future<void> deleteService(String id);
}
