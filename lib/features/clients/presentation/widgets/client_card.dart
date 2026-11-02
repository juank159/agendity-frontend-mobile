import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/config/utils/string_utils.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/whatsapp_icon.dart';

/// Un cliente de la lista: avatar (foto o iniciales sobre el degradado),
/// nombre, teléfono y email, y la marca de WhatsApp si aceptó los
/// recordatorios.
class ClientCard extends StatelessWidget {
  final ClientEntity client;
  final VoidCallback onTap;

  const ClientCard({super.key, required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final contact = [
      StringUtils.formatPhoneNumber(client.phone),
      if (client.hasEmail) client.email!,
    ].where((part) => part.isNotEmpty).join(' · ');
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      depth: 1,
      onTap: onTap,
      semanticLabel: 'Abrir ficha de ${client.fullName}',
      child: Row(
        children: [
          AppAvatar(name: client.fullName, imageUrl: client.image, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700, color: scheme.onSurface)),
                if (contact.isNotEmpty)
                  Text(contact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)
                          .tabular),
              ],
            ),
          ),
          if (client.hasWhatsappConsent)
            Tooltip(
              message: 'Acepta recordatorios por WhatsApp',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: WhatsappIcon(color: tokens.success.color, size: 18),
              ),
            ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
