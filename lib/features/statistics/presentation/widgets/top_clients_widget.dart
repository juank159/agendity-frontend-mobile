import 'package:flutter/material.dart';
import 'package:login_signup/core/utils/formatters.dart';
import '../../domain/entities/top_client_entity.dart';

/// Ranking de clientes por gasto neto en el período.
class TopClientsWidget extends StatelessWidget {
  final List<TopClientEntity> clients;

  /// "Ver más clientes"; `null` si no hay más que pedir.
  final VoidCallback? onShowMore;

  const TopClientsWidget({super.key, required this.clients, this.onShowMore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < clients.length; i++)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text('${i + 1}'),
                ),
                title: Text(
                  clients[i].clientName.trim().isEmpty
                      ? 'Cliente'
                      : clients[i].clientName.trim(),
                ),
                subtitle: Text(clients[i].visitCount == 1
                    ? '1 cita pagada'
                    : '${clients[i].visitCount} citas pagadas'),
                trailing: Text(
                  formatCop(clients[i].totalSpent),
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            if (onShowMore != null)
              TextButton.icon(
                onPressed: onShowMore,
                icon: const Icon(Icons.people_outline),
                label: const Text('Ver más clientes'),
              ),
          ],
        ),
      ),
    );
  }
}
