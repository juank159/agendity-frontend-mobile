import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';

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
class SyncController extends GetxController with WidgetsBindingObserver {
  final SyncEngine _engine;

  SyncController(this._engine);

  final status = Rx<SyncStatus>(const SyncStatus());
  final entries = <OutboxEntry>[].obs;
  final isLoadingEntries = false.obs;

  /// Cambia cada vez que los datos locales pueden haber cambiado.
  final dataVersion = 0.obs;

  StreamSubscription<SyncStatus>? _subscription;

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
    if (finished && next.lastSyncedAt != previous.lastSyncedAt) {
      dataVersion.value++;
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
    } finally {
      isLoadingEntries.value = false;
    }
  }

  Future<void> retry(OutboxEntry entry) async {
    await _engine.retry(entry.mutationId);
    await loadEntries();
  }

  /// Sin confirmación: la pide la pantalla (es lo único que pierde datos).
  Future<void> discard(OutboxEntry entry) async {
    await _engine.discard(entry.mutationId);
    await loadEntries();
    dataVersion.value++;
  }

  /// Tras cerrar o iniciar sesión: la bandeja es de otra base.
  Future<void> reloadCounts() async {
    await _engine.refreshCounts();
    await loadEntries();
  }
}
