import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';

class AppointmentModel extends AppointmentEntity {
  AppointmentModel({
    required String id,
    required String ownerId,
    required DateTime date,
    required String status,
    required String paymentStatus,
    required double totalPrice,
    String? notes,
    String? cancellationReason,
    required ClientModel client,
    required ProfessionalModel professional,
    required ServiceModel service,
  }) : super(
          id: id,
          ownerId: ownerId,
          date: date,
          status: status,
          paymentStatus: paymentStatus,
          totalPrice: totalPrice,
          notes: notes,
          cancellationReason: cancellationReason,
          client: client,
          professional: professional,
          service: service,
        );

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      ownerId: json['ownerId'],
      date: DateTime.parse(json['date']),
      status: json['status'],
      paymentStatus: json['payment_status'],
      totalPrice: double.parse(json['total_price']),
      notes: json['notes'],
      cancellationReason: json['cancellation_reason'],
      client: ClientModel.fromJson(json['client']),
      professional: ProfessionalModel.fromJson(json['professional']),
      service: ServiceModel.fromJson(json['service']),
    );
  }
}

class ClientModel extends ClientEntity {
  ClientModel({
    required String id,
    required String name,
    required String lastname,
    required String email,
    required String phone,
    String? image,
  }) : super(
          id: id,
          name: name,
          lastname: lastname,
          email: email,
          phone: phone,
          image: image,
        );

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'],
      name: json['name'],
      lastname: json['lastname'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'],
    );
  }
}

class ProfessionalModel extends ProfessionalEntity {
  ProfessionalModel({
    required String id,
    required String name,
    required String lastname,
    required String email,
    required String phone,
    String? image,
  }) : super(
          id: id,
          name: name,
          lastname: lastname,
          email: email,
          phone: phone,
          image: image,
        );

  factory ProfessionalModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalModel(
      id: json['id'],
      name: json['name'],
      lastname: json['lastname'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'],
    );
  }
}

class ServiceModel extends ServiceEntity {
  ServiceModel({
    required String id,
    required String name,
    String? description,
    required double price,
    required int duration,
    required String color,
  }) : super(
          id: id,
          name: name,
          description: description,
          price: price,
          duration: duration,
          color: color,
        );

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price']),
      duration: json['duration'],
      color: json['color'],
    );
  }
}
