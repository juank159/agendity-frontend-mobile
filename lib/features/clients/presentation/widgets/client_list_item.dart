import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/utils/string_utils.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

class ClientListItem extends StatelessWidget {
  final ClientEntity client;

  const ClientListItem({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: CircleAvatar(
        backgroundColor: Colors.blue[600],
        radius: 25,
        child: Text(
          StringUtils.getInitials(client.name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        '${client.name} ${client.lastname}'.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          'Teléfono: ${StringUtils.formatPhoneNumber(client.phone)}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: () => Get.toNamed('/clients/${client.id}'),
    );
  }
}
