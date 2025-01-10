import 'package:login_signup/features/services/domain/entities/service_entity.dart';

abstract class ServicesRepository {
  Future<List<ServiceEntity>> getServices();
}
