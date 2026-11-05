import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/services/data/models/service_model.dart';
import 'package:login_signup/features/services/domain/entities/my_service.dart';

/// Un elemento de `GET /auth/me/services` (7.04): `{id, name, duration,
/// price, color, category: {id, name} | null, commission_percentage}`. Solo
/// vienen servicios activos; `commission_percentage` es el efectivo de la
/// empleada (`null` para el Owner).
abstract final class MyServiceModel {
  static MyService fromJson(Map<String, dynamic> json) => MyService(
        service: ServiceModel.fromJson(json).toEntity(),
        commissionPercentage: json['commission_percentage'] == null
            ? null
            : JsonRead.asDouble(json['commission_percentage']),
      );
}
