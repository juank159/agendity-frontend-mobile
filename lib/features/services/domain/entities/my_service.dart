import 'package:login_signup/features/services/domain/entities/service_entity.dart';

/// Un servicio que hace la profesional de la sesión ("Mis servicios", D-27),
/// con su % de comisión **efectivo**: la excepción de ese servicio o, si no
/// tiene, su comisión general.
class MyService {
  final ServiceEntity service;

  /// `null` = no se sabe (sin conexión, sin excepción y sin la comisión
  /// general guardada en el teléfono) o el Owner (todo es del negocio).
  final double? commissionPercentage;

  const MyService({required this.service, this.commissionPercentage});

  /// Lo que gana por una cita de este servicio al precio del catálogo.
  double? get commission {
    final percent = commissionPercentage;
    return percent == null ? null : service.price * percent / 100;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyService &&
          other.service == service &&
          other.commissionPercentage == commissionPercentage;

  @override
  int get hashCode => Object.hash(service, commissionPercentage);
}
