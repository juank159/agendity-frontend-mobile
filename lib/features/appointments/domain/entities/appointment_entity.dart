class AppointmentEntity {
  final String id;
  final String ownerId;
  final DateTime date;
  final String status;
  final String paymentStatus;
  final double totalPrice;
  final String? notes;
  final String? cancellationReason;
  final ClientEntity client;
  final ProfessionalEntity professional;
  final ServiceEntity service;

  AppointmentEntity({
    required this.id,
    required this.ownerId,
    required this.date,
    required this.status,
    required this.paymentStatus,
    required this.totalPrice,
    this.notes,
    this.cancellationReason,
    required this.client,
    required this.professional,
    required this.service,
  });
}

class ClientEntity {
  final String id;
  final String name;
  final String lastname;
  final String email;
  final String phone;
  final String? image;

  ClientEntity({
    required this.id,
    required this.name,
    required this.lastname,
    required this.email,
    required this.phone,
    this.image,
  });
}

class ProfessionalEntity {
  final String id;
  final String name;
  final String lastname;
  final String email;
  final String phone;
  final String? image;

  ProfessionalEntity({
    required this.id,
    required this.name,
    required this.lastname,
    required this.email,
    required this.phone,
    this.image,
  });
}

class ServiceEntity {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int duration;
  final String color;

  ServiceEntity({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.duration,
    required this.color,
  });
}
