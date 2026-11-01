import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'package:login_signup/shared/widgets/sync_entry_text.dart';

/// Estado de la sincronización para la UI (10.03, D-18), sobre
/// [SyncEngine]. Alcance de app (como `SessionController`): lo registra
/// `SessionBinding`.
///
/// - [status]: sin conexión, sincronizando, N pendientes, "requiere
///   atención" (lo pinta `SyncStatusIndicator`).
/// - [entries]/[retry]/[discard]: la pantalla "Pendientes".
/// - Pide una sincronización inmediata al volver la app a primer plano.
/// - [onDataChanged]: las pantallas que leen de la base local se recargan
///   cuando una sincronización termina o el usuario descarta algo.
/// - Avisa **una vez** de cada operación que el servidor rechaza o deja en
///   conflicto (7.05b, D-18), esté donde esté el usuario: un alta hecha sin
///   conexión que el servidor no acepta desaparece de su lista al
///   sincronizar, y el indicador solo se ve en la agenda.
class SyncController extends GetxController with WidgetsBindingObserver {
  final SyncEngine _engine;

  /// Muestra el aviso de [announceNewAttention] (inyectable en tests).
  final void Function(List<OutboxEntry> fresh) _announce;

  SyncController(this._engine,
      {void Function(List<OutboxEntry> fresh)? announce})
      : _announce = announce ?? showAttentionNotice;

  final status = Rx<SyncStatus>(const SyncStatus());
  final entries = <OutboxEntry>[].obs;
  final isLoadingEntries = false.obs;

  /// Cambia cada vez que los datos locales pueden haber cambiado.
  final dataVersion = 0.obs;

  StreamSubscription<SyncStatus>? _subscription;

  /// `mutation_id` de las que requieren atención y ya se avisaron.
  final Set<String> _announced = {};

  /// `lastSyncedAt` al terminar la pasada anterior (7.05c). Se compara con
  /// esto y no con el evento previo: el motor emite el `lastSyncedAt` nuevo
  /// **antes** del evento que cierra la pasada (`syncing: false`), así que
  /// contra el previo nunca cambiaba y las pantallas no se recargaban.
  DateTime? _syncedAtLastFinish;

  int get pending => status.value.pending;
  int get needsAttention => status.value.needsAttention;
  bool get isOffline => !status.value.online;
  bool get isSyncing => status.value.syncing;

  /// Cambios hechos en este teléfono que aún no están en el servidor.
  int get unsent => pending + needsAttention;

  List<OutboxEntry> get attentionEntries => [
        for (final entry in entries)
          if (entry.status != OutboxStatus.pending) entry,
      ];

  List<OutboxEntry> get pendingEntries => [
        for (final entry in entries)
          if (entry.status == OutboxStatus.pending) entry,
      ];

  @override
  void onInit() {
    super.onInit();
    status.value = _engine.current;
    _syncedAtLastFinish = _engine.current.lastSyncedAt;
    _subscription = _engine.status.listen(_onStatus);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.onClose();
  }

  void _onStatus(SyncStatus next) {
    final previous = status.value;
    status.value = next;
    final finished = previous.syncing && !next.syncing;
    if (finished) {
      // Pasada correcta (subida + bajada): los datos locales pudieron cambiar.
      if (next.lastSyncedAt != _syncedAtLastFinish) dataVersion.value++;
      _syncedAtLastFinish = next.lastSyncedAt;
    }
    if (finished || next.needsAttention != previous.needsAttention) {
      unawaited(loadEntries());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _engine.requestSync(immediate: true);
    }
  }

  /// Llama a [onChanged] cuando los datos locales pudieron cambiar. Quien lo
  /// usa libera el `Worker` en su `onClose`.
  Worker onDataChanged(void Function() onChanged) =>
      ever<int>(dataVersion, (_) => onChanged());

  /// "Deslizar para refrescar": sincroniza ya y espera a que termine.
  Future<void> syncNow() async {
    await _engine.syncNow();
    dataVersion.value++;
  }

  Future<void> loadEntries() async {
    isLoadingEntries.value = true;
    try {
      entries.assignAll(await _engine.entries());
      _announceNewAttention();
    } finally {
      isLoadingEntries.value = false;
    }
  }

  /// Avisa de las que requieren atención y aún no se avisaron. Reintentar
  /// crea un `mutation_id` nuevo: si el servidor la vuelve a rechazar, se
  /// avisa otra vez. Síncrono tras leer la bandeja: dos lecturas seguidas no
  /// avisan dos veces.
  void _announceNewAttention() {
    final attention = attentionEntries;
    _announced.retainAll({for (final e in attention) e.mutationId});
    final fresh = [
      for (final entry in attention)
        if (_announced.add(entry.mutationId)) entry,
    ];
    if (fresh.isNotEmpty) _announce(fresh);
  }

  /// Aviso por defecto: un `AppSnackbar` con "Revisar" → "Pendientes" (no se
  /// muestra si el usuario ya está en esa pantalla).
  static void showAttentionNotice(List<OutboxEntry> fresh) {
    if (Get.currentRoute == GetRoutes.syncPending) return;
    AppSnackbar.warning(
      attentionMessage(fresh),
      title: fresh.length == 1 ? 'Cambio no guardado' : 'Cambios no guardados',
      action: SnackbarAction(
        label: 'Revisar',
        onPressed: () => Get.toNamed(GetRoutes.syncPending),
      ),
    );
  }

  /// Texto del aviso: qué cambio (si es uno) y qué hacer.
  static String attentionMessage(List<OutboxEntry> fresh) {
    if (fresh.length == 1) {
      final entry = fresh.single;
      final detail = SyncEntryText.detail(entry);
      final what = detail == null
          ? SyncEntryText.action(entry)
          : '${SyncEntryText.action(entry)} ($detail)';
      return '$what no se guardó en el servidor. '
          'Revísalo en Pendientes para corregirlo o descartarlo.';
    }
    return '${fresh.length} cambios hechos en este teléfono no se guardaron '
        'en el servidor. Revísalos en Pendientes.';
  }

  Future<void> retry(OutboxEntry entry) async {
    await _engine.retry(entry.mutationId);
    await loadEntries();
  }

  /// Sin confirmación: la pide la pantalla (es lo único que pierde datos).
  /// `false` si no se descartó: una operación **pendiente** aún no tiene
  /// respuesta del servidor y no se puede descartar (podría estar aplicada).
  Future<bool> discard(OutboxEntry entry) async {
    final discarded = await _engine.discard(entry.mutationId);
    await loadEntries();
    if (discarded) dataVersion.value++;
    return discarded;
  }

  /// Tras cerrar o iniciar sesión: la bandeja es de otra base.
  Future<void> reloadCounts() async {
    await _engine.refreshCounts();
    await loadEntries();
  }
}
