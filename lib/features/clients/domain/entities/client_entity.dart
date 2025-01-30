class ClientEntity {
  final String? id;
  final String name;
  final String lastname;
  final String email;
  final String phone;
  final String? image;
  final String? address;
  final String ownerId;
  final bool isFromDevice;
  final String? deviceContactId;
  final DateTime? lastVisit;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClientEntity({
    this.id,
    required this.name,
    required this.lastname,
    required this.email,
    required this.phone,
    this.image,
    this.address,
    required this.ownerId,
    this.isFromDevice = false,
    this.deviceContactId,
    this.lastVisit,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });
}
