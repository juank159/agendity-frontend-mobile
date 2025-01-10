import 'package:login_signup/features/services/data/datasources/services_remote_datasource.dart';
import 'package:login_signup/features/services/data/models/service_model.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource remoteDataSource;

  ServicesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ServiceEntity>> getServices() async {
    try {
      final response = await remoteDataSource.getServices();
      return response.map((json) => ServiceModel.fromJson(json)).toList();
    } catch (e) {
      print('Error en repository: $e');
      rethrow;
    }
  }
}
