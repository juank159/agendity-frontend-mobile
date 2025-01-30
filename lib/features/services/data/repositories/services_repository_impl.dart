import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/services_repository.dart';
import '../datasources/services_remote_datasource.dart';
import '../models/service_model.dart' as model;

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource remoteDataSource;

  ServicesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ServiceEntity>> getServices() async {
    try {
      final response = await remoteDataSource.getServices();
      return response.map((json) => model.ServiceModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error getting services: $e');
    }
  }

  @override
  Future<void> createService(ServiceEntity service) async {
    try {
      final serviceModel = model.ServiceModel(
        name: service.name,
        description: service.description,
        price: service.price,
        priceType: service.priceType,
        duration: service.duration,
        categoryId: service.categoryId,
        color: service.color,
        image: service.image,
        onlineBooking: service.onlineBooking,
        deposit: service.deposit,
        isActive: service.isActive,
      );
      await remoteDataSource.createService(serviceModel);
    } catch (e) {
      throw Exception('Error creating service: $e');
    }
  }

  @override
  Future<void> updateService(String id, ServiceEntity service) {
    return remoteDataSource.updateService(id, service);
  }

  @override
  Future<void> deleteService(String id) {
    return remoteDataSource.deleteService(id);
  }
}
