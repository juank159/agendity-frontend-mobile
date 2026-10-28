import 'package:flutter/material.dart';
import 'package:login_signup/core/config/utils/string_utils.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

/// Un cliente de la lista.
class ClientCard extends StatelessWidget {
  final ClientEntity client;
  final VoidCallback onTap;

  const ClientCard({super.key, required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = client.image;
    final hasImage = image != null && image.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          backgroundImage: hasImage ? NetworkImage(image) : null,
          onBackgroundImageError: hasImage ? (_, __) {} : null,
          child: hasImage ? null : Text(StringUtils.getInitials(client.name)),
        ),
        title:
            Text(client.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            StringUtils.formatPhoneNumber(client.phone),
            if (client.hasEmail) client.email!,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
