import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

/// Contactos del teléfono con al menos un número, como clientes sin `id`
/// (el use case de importar los valida y normaliza). `null` sin permiso.
Future<List<ClientEntity>?> readDeviceContacts() async {
  if (!await FlutterContacts.requestPermission(readonly: true)) return null;
  final contacts =
      await FlutterContacts.getContacts(withProperties: true, withPhoto: false);
  return [
    for (final contact in contacts)
      if (contact.phones.isNotEmpty)
        ClientEntity(
          name: contact.name.first,
          lastname: contact.name.last,
          email: contact.emails.isEmpty ? null : contact.emails.first.address,
          phone: contact.phones.first.number,
          deviceContactId: contact.id,
        ),
  ];
}
