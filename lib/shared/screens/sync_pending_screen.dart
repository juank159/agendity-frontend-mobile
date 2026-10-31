import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/empty_state.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'package:login_signup/shared/widgets/sync_entry_text.dart';

/// "Pendientes" (10.03): lo hecho en este teléfono que aún no está en el
/// servidor. Las rechazadas o en conflicto esperan al usuario: reintentar o
/// descartar (con confirmación: es lo único que pierde datos).
class SyncPendingScreen extends StatefulWidget {
  const SyncPendingScreen({super.key});

  @override
  State<SyncPendingScreen> createState() => _SyncPendingScreenState();
}

class _SyncPendingScreenState extends State<SyncPendingScreen> {
  SyncController get sync => Get.find<SyncController>();

  @override
  void initState() {
    super.initState();
    sync.loadEntries();
  }

  Future<void> _discard(OutboxEntry entry) async {
    final confirmed = await AppDialogs.confirm(
      title: '¿Descartar este cambio?',
      message: SyncEntryText.discardWarning(entry),
      confirmLabel: 'Descartar',
      cancelLabel: 'Conservar',
      destructive: true,
    );
    if (!confirmed) return;
    await sync.discard(entry);
    AppSnackbar.info('Se descartó "${SyncEntryText.action(entry)}"',
        title: 'Cambio descartado');
  }

  Future<void> _retry(OutboxEntry entry) async {
    await sync.retry(entry);
    AppSnackbar.info('Se volverá a enviar ahora', title: 'Reintentando');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pendientes')),
      body: RefreshIndicator(
        onRefresh: sync.syncNow,
        child: Obx(() {
          final attention = sync.attentionEntries;
          final pending = sync.pendingEntries;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const _StatusCard(),
              if (attention.isNotEmpty) ...[
                const _Title('Requieren atención'),
                for (final entry in attention)
                  _EntryCard(
                    entry: entry,
                    onRetry: SyncEntryText.retriesBySelf(entry)
                        ? null
                        : () => _retry(entry),
                    onDiscard: () => _discard(entry),
                  ),
              ],
              if (pending.isNotEmpty) ...[
                const _Title('Esperando envío'),
                for (final entry in pending) _EntryCard(entry: entry),
              ],
              if (attention.isEmpty && pending.isEmpty)
                const SizedBox(
                  height: 320,
                  child: EmptyState(
                    icon: Icons.cloud_done_outlined,
                    message: 'Todo está en el servidor',
                    subMessage: 'Lo que hagas sin conexión aparecerá aquí '
                        'hasta que se envíe.',
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    final sync = Get.find<SyncController>();
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final status = sync.status.value;
          final last = status.lastSyncedAt;
          final state = !status.online
              ? 'Sin conexión: los cambios se guardan en este teléfono y se '
                  'enviarán solos al volver internet.'
              : status.syncing
                  ? 'Sincronizando…'
                  : 'Conectado.';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(state, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text(
                '${formatCount(status.pending, 'cambio pendiente', 'cambios pendientes')}'
                ' · ${formatCount(status.needsAttention, 'requiere atención', 'requieren atención')}'
                '${last == null ? '' : ' · Última sincronización: ${formatTime(last)}'}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: status.syncing ? null : sync.syncNow,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizar ahora'),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;

  const _Title(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      );
}

class _EntryCard extends StatelessWidget {
  final OutboxEntry entry;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  const _EntryCard({required this.entry, this.onRetry, this.onDiscard});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needsUser = entry.status != OutboxStatus.pending;
    final tone = needsUser
        ? (SyncEntryText.retriesBySelf(entry)
            ? context.tokens.warning
            : context.tokens.error)
        : context.tokens.info;
    final detail = SyncEntryText.detail(entry);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(needsUser ? Icons.error_outline : Icons.schedule,
                    color: tone.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(SyncEntryText.action(entry),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (detail != null)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 2),
                child: Text(detail),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text(SyncEntryText.reason(entry),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            if (needsUser)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error),
                    onPressed: onDiscard,
                    child: const Text('Descartar'),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: onRetry,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
