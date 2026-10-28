import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

/// DTO de `/clients` (backend: `Client`, en camelCase salvo `created_at` y
/// `updated_at`).
///
/// - `email` puede llegar `null` (2.20): cliente sin email.
/// - `birthday` es un día: se envía `yyyy-MM-dd` (el backend lo guarda como
///   00:00 del negocio) y se lee la fecha escrita, sin convertir de zona.
/// - `GET /clients/:id` trae además `appointments` y `reviews`: se ignoran.
class ClientModel {
  final String? id;
  final String name;
  final String lastname;
  final String? email;
  final String phone;
  final String? image;
  final String? address;
  final bool isFromDevice;
  final String? deviceContactId;
  final DateTime? lastVisit;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final DateTime? birthday;
  final bool showNotes;

  const ClientModel({
    this.id,
    required this.name,
    this.lastname = '',
    this.email,
    required this.phone,
    this.image,
    this.address,
    this.isFromDevice = false,
    this.deviceContactId,
    this.lastVisit,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.birthday,
    this.showNotes = false,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: JsonRead.asOptionalString(json['id']),
      name: JsonRead.asString(json['name']),
      lastname: JsonRead.asString(json['lastname']),
      email: JsonRead.asOptionalString(json['email']),
      phone: JsonRead.asString(json['phone']),
      image: JsonRead.asOptionalString(json['image']),
      address: JsonRead.asOptionalString(json['address']),
      isFromDevice: JsonRead.asBool(json['isFromDevice'], fallback: false),
      deviceContactId: JsonRead.asOptionalString(json['deviceContactId']),
      lastVisit: DateCodec.tryDecode(json['lastVisit']),
      isActive: JsonRead.asBool(json['isActive'], fallback: true),
      createdAt: DateCodec.tryDecode(json['created_at']),
      updatedAt: DateCodec.tryDecode(json['updated_at']),
      notes: JsonRead.asOptionalString(json['notes']),
      birthday: DateCodec.tryDecodeDay(json['birthday']),
      showNotes: JsonRead.asBool(json['showNotes'], fallback: false),
    );
  }

  factory ClientModel.fromEntity(ClientEntity entity) => ClientModel(
        id: entity.id,
        name: entity.name,
        lastname: entity.lastname,
        email: entity.email,
        phone: entity.phone,
        image: entity.image,
        address: entity.address,
        isFromDevice: entity.isFromDevice,
        deviceContactId: entity.deviceContactId,
        lastVisit: entity.lastVisit,
        isActive: entity.isActive,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        notes: entity.notes,
        birthday: entity.birthday,
        showNotes: entity.showNotes,
      );

  ClientEntity toEntity() => ClientEntity(
        id: id,
        name: name,
        lastname: lastname,
        email: email,
        phone: phone,
        image: image,
        address: address,
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

  /// Cuerpo de `POST /clients` y `PATCH /clients/:id` (`CreateClientDto`; el
  /// backend rechaza campos de más, así que nunca `id`, `ownerId`,
  /// `isActive`…).
  ///
  /// - `email`: `''` si no hay; el backend lo guarda como `null` (en una
  ///   edición, así se quita).
  /// - `notes`, `address` y `birthday` van siempre: `null` los borra al editar.
  /// - `image` solo si hay (el backend conserva la anterior si no llega).
  Map<String, dynamic> toJson() => {
        'name': name,
        'lastname': lastname,
        'email': email ?? '',
        'phone': phone,
        'address': address,
        if (image != null) 'image': image,
        if (deviceContactId != null) 'deviceContactId': deviceContactId,
        'notes': notes,
        'birthday': birthday == null ? null : DateCodec.encodeDay(birthday!),
        'showNotes': showNotes,
      };

  /// Una fila de `POST /clients/batch`: solo lo que trae un contacto; sin
  /// email si no tiene (el backend ya no lo exige, 2.20).
  Map<String, dynamic> toImportJson() => {
        'name': name,
        'lastname': lastname,
        if (email != null) 'email': email,
        'phone': phone,
        if (deviceContactId != null) 'deviceContactId': deviceContactId,
      };
}
