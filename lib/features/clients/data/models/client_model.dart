import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

class ClientModel extends ClientEntity {
  ClientModel({
    String? id,
    required String name,
    required String lastname,
    required String email,
    required String phone,
    String? image,
    String? address,
    required String ownerId,
    bool isFromDevice = false,
    String? deviceContactId,
    DateTime? lastVisit,
    bool isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          id: id,
          name: name,
          lastname: lastname,
          email: email,
          phone: phone,
          image: image,
          address: address,
          ownerId: ownerId,
          isFromDevice: isFromDevice,
          deviceContactId: deviceContactId,
          lastVisit: lastVisit,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'],
      name: json['name'],
      lastname: json['lastname'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'],
      address: json['address'],
      ownerId: json['ownerId'],
      isFromDevice: json['isFromDevice'] ?? false,
      deviceContactId: json['deviceContactId'],
      lastVisit:
          json['lastVisit'] != null ? DateTime.parse(json['lastVisit']) : null,
      isActive: json['isActive'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastname': lastname,
      'email': email,
      'phone': phone,
      'image': image,
      'address': address,
      'ownerId': ownerId,
      'isFromDevice': isFromDevice,
      'deviceContactId': deviceContactId,
      'lastVisit': lastVisit?.toIso8601String(),
      'isActive': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
