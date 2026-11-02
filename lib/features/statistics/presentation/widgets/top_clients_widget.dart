import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import '../../domain/entities/top_client_entity.dart';

/// Ranking de clientes por gasto neto en el período: puesto en una píldora
/// (los tres primeros con el degradado de la paleta), avatar, citas pagadas
/// y el monto tabular.
class TopClientsWidget extends StatelessWidget {
  final List<TopClientEntity> clients;

  /// "Ver más clientes"; `null` si no hay más que pedir.
  final VoidCallback? onShowMore;

  const TopClientsWidget({super.key, required this.clients, this.onShowMore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    return Column(
      children: [
        for (var i = 0; i < clients.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: i < 3 ? tokens.primaryGradient : null,
                    color: i < 3 ? null : scheme.surfaceContainerHighest,
                  ),
                  child: Text('${i + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: i < 3
                              ? tokens.onGradient
                              : scheme.onSurfaceVariant)),
                ),
                const SizedBox(width: 10),
                AppAvatar(name: _name(clients[i]), radius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name(clients[i]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                          clients[i].visitCount == 1
                              ? '1 cita pagada'
                              : '${clients[i].visitCount} citas pagadas',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Text(
                  formatCop(clients[i].totalSpent),
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w800)
                      .tabular,
                ),
              ],
            ),
          ),
        if (onShowMore != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextButton.icon(
              onPressed: onShowMore,
              icon: const Icon(Icons.people_rounded),
              label: const Text('Ver más clientes'),
            ),
          ),
      ],
    );
  }

  static String _name(TopClientEntity client) =>
      client.clientName.trim().isEmpty ? 'Cliente' : client.clientName.trim();
}
