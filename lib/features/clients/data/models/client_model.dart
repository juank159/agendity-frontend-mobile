// import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

// class ClientModel extends ClientEntity {
//   ClientModel({
//     String? id,
//     required String name,
//     required String lastname,
//     required String email,
//     required String phone,
//     String? image,
//     String? address,
//     required String ownerId,
//     bool isFromDevice = false,
//     String? deviceContactId,
//     DateTime? lastVisit,
//     bool isActive = true,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//     String? notes,
//     DateTime? birthday,
//     bool showNotes = false,
//   }) : super(
//           id: id,
//           name: name,
//           lastname: lastname,
//           email: email,
//           phone: phone,
//           image: image,
//           address: address,
//           ownerId: ownerId,
//           isFromDevice: isFromDevice,
//           deviceContactId: deviceContactId,
//           lastVisit: lastVisit,
//           isActive: isActive,
//           createdAt: createdAt,
//           updatedAt: updatedAt,
//           notes: notes,
//           birthday: birthday,
//           showNotes: showNotes,
//         );

//   factory ClientModel.fromJson(Map<String, dynamic> json) {
//     return ClientModel(
//       id: json['id'],
//       name: json['name'] ?? '',
//       lastname: json['lastname'] ?? '',
//       email: json['email'] ?? '',
//       phone: json['phone'] ?? '',
//       image: json['image'],
//       address: json['address'],
//       ownerId: json['ownerId'] ?? '',
//       isFromDevice: json['isFromDevice'] ?? false,
//       deviceContactId: json['deviceContactId'],
//       lastVisit:
//           json['lastVisit'] != null ? DateTime.parse(json['lastVisit']) : null,
//       isActive: json['isActive'] ?? true,
//       createdAt: json['created_at'] != null
//           ? DateTime.parse(json['created_at'])
//           : null,
//       updatedAt: json['updated_at'] != null
//           ? DateTime.parse(json['updated_at'])
//           : null,
//       notes: json['notes'],
//       birthday:
//           json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
//       showNotes: json['showNotes'] ?? false,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name.trim(),
//       'lastname': lastname.trim(),
//       'email': email.trim(),
//       'phone': phone.replaceAll(RegExp(r'[^\d+]'), ''),
//       'image': image,
//       'address': address?.trim(),
//       'ownerId': ownerId,
//       'isFromDevice': isFromDevice,
//       'deviceContactId': deviceContactId,
//       'isActive': isActive,
//       'notes': notes?.trim(),
//       'birthday': birthday?.toIso8601String(),
//       'showNotes': showNotes,
//     };
//   }

//   bool isValid() {
//     final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

//     final isValidName = name.trim().isNotEmpty;
//     final isValidPhone = cleanPhone.length >= 10;
//     final isValidOwnerId = ownerId.trim().isNotEmpty;

//     print('Validando cliente:');
//     print('- Nombre: ${isValidName ? 'válido' : 'inválido'} ($name)');
//     print('- Teléfono: ${isValidPhone ? 'válido' : 'inválido'} ($cleanPhone)');
//     print('- OwnerId: ${isValidOwnerId ? 'válido' : 'inválido'} ($ownerId)');

//     return isValidName && isValidPhone && isValidOwnerId;
//   }

//   ClientModel copyWithCleanData() {
//     return ClientModel(
//       id: id,
//       name: name.trim(),
//       lastname: lastname.trim(),
//       email: email.trim(),
//       phone: phone.replaceAll(RegExp(r'[^\d+]'), ''),
//       image: image,
//       address: address?.trim(),
//       ownerId: ownerId.trim(),
//       isFromDevice: isFromDevice,
//       deviceContactId: deviceContactId,
//       lastVisit: lastVisit,
//       isActive: isActive,
//       createdAt: createdAt,
//       updatedAt: updatedAt,
//       notes: notes?.trim(),
//       birthday: birthday,
//       showNotes: showNotes,
//     );
//   }

//   @override
//   String toString() {
//     return 'ClientModel(id: $id, name: $name, lastname: $lastname, phone: $phone, email: $email)';
//   }
// }

// lib/features/clients/data/models/client_model.dart

import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/core/utils/date_codec.dart';

// ✅ MODELO DE PAGINACIÓN PARA RESPUESTAS DEL BACKEND
class PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  PaginatedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) itemFactory) {
    return PaginatedResponse(
      data: (json['data'] as List).map((item) => itemFactory(item as Map<String, dynamic>)).toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }
}

typedef PaginatedClientResponse = PaginatedResponse<ClientModel>;

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
    String? notes,
    DateTime? birthday,
    bool showNotes = false,
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
          notes: notes,
          birthday: birthday,
          showNotes: showNotes,
        );

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'],
      name: json['name'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      image: json['image'],
      address: json['address'],
      ownerId: json['ownerId'] ?? '',
      isFromDevice: json['isFromDevice'] ?? false,
      deviceContactId: json['deviceContactId'],
      lastVisit:
          DateCodec.tryDecode(json['lastVisit']),
      isActive: json['isActive'] ?? true,
      createdAt: DateCodec.tryDecode(json['created_at']),
      updatedAt: DateCodec.tryDecode(json['updated_at']),
      notes: json['notes'],
      birthday:
          DateCodec.tryDecode(json['birthday']),
      showNotes: json['showNotes'] ?? false,
    );
  }

  Map<String, dynamic> toJson({bool forCreate = false}) {
    final Map<String, dynamic> json = {
      'name': name.trim(),
      'lastname': lastname.trim(),
      'email': email.trim(),
      'phone': phone.replaceAll(RegExp(r'[^\d+]'), ''),
      'image': image,
      'address': address?.trim(),
      'notes': notes?.trim(),
      'birthday': DateCodec.encodeOrNull(birthday),
      'showNotes': showNotes,
    };

    // Solo incluir estos campos si NO es para crear un nuevo cliente
    if (!forCreate) {
      json['id'] = id;
      json['ownerId'] = ownerId;
      json['isFromDevice'] = isFromDevice;
      json['deviceContactId'] = deviceContactId;
      json['isActive'] = isActive;
    }

    return json;
  }

  bool isValid() {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    final isValidName = name.trim().isNotEmpty;
    final isValidPhone = cleanPhone.length >= 10;
    final isValidOwnerId = ownerId.trim().isNotEmpty;

    print('Validando cliente:');
    print('- Nombre: ${isValidName ? 'válido' : 'inválido'} ($name)');
    print('- Teléfono: ${isValidPhone ? 'válido' : 'inválido'} ($cleanPhone)');
    print('- OwnerId: ${isValidOwnerId ? 'válido' : 'inválido'} ($ownerId)');

    return isValidName && isValidPhone && isValidOwnerId;
  }

  ClientModel copyWithCleanData() {
    return ClientModel(
      id: id,
      name: name.trim(),
      lastname: lastname.trim(),
      email: email.trim(),
      phone: phone.replaceAll(RegExp(r'[^\d+]'), ''),
      image: image,
      address: address?.trim(),
      ownerId: ownerId.trim(),
      isFromDevice: isFromDevice,
      deviceContactId: deviceContactId,
      lastVisit: lastVisit,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      notes: notes?.trim(),
      birthday: birthday,
      showNotes: showNotes,
    );
  }

  @override
  String toString() {
    return 'ClientModel(id: $id, name: $name, lastname: $lastname, phone: $phone, email: $email)';
  }
}
