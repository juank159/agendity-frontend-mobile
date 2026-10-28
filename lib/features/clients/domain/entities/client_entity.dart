/// Cliente del negocio. Es único por teléfono dentro del negocio; el email es
/// opcional (2.20).
///
/// - [id] es `null` en un cliente que aún no existe (alta o import).
/// - [email] `null` = sin email.
/// - [phone] tal como lo guarda el backend; las altas y ediciones lo envían
///   normalizado (`ClientRules.normalizePhone`).
/// - [birthday] es un día de calendario (`DateTime(y, m, d)` local), no un
///   instante.
/// - [isFromDevice]: lo marca el backend en los importados de los contactos.
/// - El negocio (`owner_id`) no viaja: el backend lo saca del token.
class ClientEntity {
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

  const ClientEntity({
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

  /// Nombre y apellido separados por un espacio.
  String get fullName => lastname.isEmpty ? name : '$name $lastname';

  bool get hasEmail => email != null && email!.isNotEmpty;

  /// Los campos opcionales no se pueden poner a `null` con [copyWith]: para
  /// quitar un valor se construye la entidad de nuevo.
  ClientEntity copyWith({
    String? id,
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? image,
    String? address,
    bool? isFromDevice,
    String? deviceContactId,
    DateTime? lastVisit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    DateTime? birthday,
    bool? showNotes,
  }) =>
      ClientEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        lastname: lastname ?? this.lastname,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        image: image ?? this.image,
        address: address ?? this.address,
        isFromDevice: isFromDevice ?? this.isFromDevice,
        deviceContactId: deviceContactId ?? this.deviceContactId,
        lastVisit: lastVisit ?? this.lastVisit,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        notes: notes ?? this.notes,
        birthday: birthday ?? this.birthday,
        showNotes: showNotes ?? this.showNotes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientEntity &&
          other.id == id &&
          other.name == name &&
          other.lastname == lastname &&
          other.email == email &&
          other.phone == phone &&
          other.image == image &&
          other.address == address &&
          other.isFromDevice == isFromDevice &&
          other.deviceContactId == deviceContactId &&
          other.lastVisit == lastVisit &&
          other.isActive == isActive &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.notes == notes &&
          other.birthday == birthday &&
          other.showNotes == showNotes;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        lastname,
        email,
        phone,
        image,
        address,
        isFromDevice,
        deviceContactId,
        lastVisit,
        isActive,
        createdAt,
        updatedAt,
        notes,
        birthday,
        showNotes,
      );

  @override
  String toString() => 'ClientEntity($id, $fullName)';
}
