import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/empty_state.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';
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
    if (await sync.discard(entry)) {
      AppSnackbar.info('Se descartó "${SyncEntryText.action(entry)}"',
          title: 'Cambio descartado');
    } else {
      AppSnackbar.warning(
          'Ya se está enviando y aún no hay respuesta del servidor. '
          'Sincroniza y, si lo rechaza, podrás descartarlo.',
          title: 'No se descartó');
    }
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
          var index = 0;
          Widget enter(Widget child) =>
              AppFadeIn(index: index++, child: child);
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              enter(const _StatusCard()),
              if (attention.isNotEmpty) ...[
                const AppSectionHeader(
                  icon: Icons.priority_high_rounded,
                  title: 'Requieren atención',
                  subtitle: 'El servidor no los aceptó: reintenta o '
                      'descártalos.',
                  padding: EdgeInsets.fromLTRB(4, 20, 4, 6),
                ),
                for (final entry in attention)
                  enter(_EntryCard(
                    entry: entry,
                    onRetry: SyncEntryText.retriesBySelf(entry)
                        ? null
                        : () => _retry(entry),
                    onDiscard: () => _discard(entry),
                  )),
              ],
              if (pending.isNotEmpty) ...[
                const AppSectionHeader(
                  icon: Icons.cloud_upload_rounded,
                  title: 'Esperando envío',
                  subtitle: 'Se envían solos cuando haya conexión.',
                  padding: EdgeInsets.fromLTRB(4, 20, 4, 6),
                ),
                // Sin respuesta del servidor: no se descartan; solo se
                // puede pedir que se envíen ya.
                for (final entry in pending)
                  enter(_EntryCard(entry: entry, onSyncNow: sync.syncNow)),
              ],
              if (attention.isEmpty && pending.isEmpty)
                const SizedBox(
                  height: 360,
                  child: EmptyState(
                    icon: Icons.cloud_done_rounded,
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

/// Estado de la conexión: tarjeta con el degradado del estado (sin
/// conexión = aviso, con problemas = error, al día = la paleta), los
/// contadores y "Sincronizar ahora".
class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    final sync = Get.find<SyncController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    return Obx(() {
      final status = sync.status.value;
      final last = status.lastSyncedAt;
      final ToneColors? tone = !status.online
          ? tokens.warning
          : status.needsAttention > 0
              ? tokens.error
              : null;
      final IconData icon = !status.online
          ? Icons.cloud_off_rounded
          : status.syncing
              ? Icons.sync_rounded
              : Icons.cloud_done_rounded;
      final state = !status.online
          ? 'Sin conexión: los cambios se guardan en este teléfono y se '
              'enviarán solos al volver internet.'
          : status.syncing
              ? 'Sincronizando…'
              : 'Conectado.';
      final background = tone?.container ?? scheme.primaryContainer;
      final ink = tone?.onContainer ?? scheme.onPrimaryContainer;
      final accent = tone?.color ?? scheme.primary;
      return AppCard(
        margin: EdgeInsets.zero,
        color: background,
        tint: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: tone == null
                        ? tokens.primaryGradient
                        : tokens.gradientOf(accent),
                    border: Border.all(color: tokens.innerBorder),
                  ),
                  child: Icon(icon,
                      color: tone == null ? tokens.onGradient : scheme.surface),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(state,
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: ink, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _CountPill(
                    icon: Icons.schedule_rounded,
                    text: formatCount(status.pending, 'cambio pendiente',
                        'cambios pendientes'),
                    color: ink),
                _CountPill(
                    icon: Icons.priority_high_rounded,
                    text: formatCount(status.needsAttention,
                        'requiere atención', 'requieren atención'),
                    color: ink),
                if (last != null)
                  _CountPill(
                      icon: Icons.history_rounded,
                      text: 'Última sincronización: ${formatTime(last)}',
                      color: ink),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: status.syncing ? null : sync.syncNow,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Sincronizar ahora'),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Contador de la tarjeta de estado.
class _CountPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _CountPill(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.tabular
                    .copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final OutboxEntry entry;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  /// Solo en las pendientes, en lugar de "Reintentar".
  final VoidCallback? onSyncNow;

  const _EntryCard(
      {required this.entry, this.onRetry, this.onDiscard, this.onSyncNow});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final needsUser = entry.status != OutboxStatus.pending;
    final tone = needsUser
        ? (SyncEntryText.retriesBySelf(entry)
            ? context.tokens.warning
            : context.tokens.error)
        : context.tokens.info;
    final detail = SyncEntryText.detail(entry);
    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      depth: 1,
      tint: tone.color,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tone.container,
                  borderRadius: AppRadii.chipRadius,
                ),
                child: Icon(
                    needsUser
                        ? Icons.error_outline_rounded
                        : Icons.schedule_rounded,
                    size: 20,
                    color: tone.onContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(SyncEntryText.action(entry),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (detail != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(detail),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(SyncEntryText.reason(entry),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!needsUser && onSyncNow != null)
            Align(
              alignment: Alignment.centerRight,
              child: Obx(() => TextButton.icon(
                    onPressed: Get.find<SyncController>().isSyncing
                        ? null
                        : onSyncNow,
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Sincronizar ahora'),
                  )),
            ),
          if (needsUser)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  onPressed: onDiscard,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Descartar'),
                ),
                if (onRetry != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
