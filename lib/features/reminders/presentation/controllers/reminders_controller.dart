import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_settings.dart';
import 'package:login_signup/features/reminders/domain/usecases/delete_reminder_rule_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/get_reminder_rules_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/get_reminder_settings_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/preview_reminder_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/save_reminder_rule_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/update_reminder_settings_usecase.dart';
import 'package:login_signup/features/reminders/presentation/widgets/reminder_ui.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

enum RemindersStatus { loading, ready, error }

/// "Recordatorios" (Fase 11, solo Owner y con conexión): interruptor
/// general, ventana de envío, cupo del mes y reglas por tipo.
class RemindersController extends GetxController {
  final GetReminderSettingsUseCase _getSettings;
  final UpdateReminderSettingsUseCase _updateSettings;
  final GetReminderRulesUseCase _getRules;
  final SaveReminderRuleUseCase _saveRule;
  final DeleteReminderRuleUseCase _deleteRule;
  final PreviewReminderUseCase _preview;

  RemindersController({
    required GetReminderSettingsUseCase getReminderSettingsUseCase,
    required UpdateReminderSettingsUseCase updateReminderSettingsUseCase,
    required GetReminderRulesUseCase getReminderRulesUseCase,
    required SaveReminderRuleUseCase saveReminderRuleUseCase,
    required DeleteReminderRuleUseCase deleteReminderRuleUseCase,
    required PreviewReminderUseCase previewReminderUseCase,
  })  : _getSettings = getReminderSettingsUseCase,
        _updateSettings = updateReminderSettingsUseCase,
        _getRules = getReminderRulesUseCase,
        _saveRule = saveReminderRuleUseCase,
        _deleteRule = deleteReminderRuleUseCase,
        _preview = previewReminderUseCase;

  final status = RemindersStatus.loading.obs;
  final loadError = RxnString();
  final loadErrorIsFinal = false.obs;
  final settings = Rxn<ReminderSettings>();
  final rules = <ReminderRule>[].obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status.value = RemindersStatus.loading;
    loadError.value = null;
    loadErrorIsFinal.value = false;
    final settingsResult = await _getSettings(NoParams());
    final rulesResult = await _getRules(NoParams());
    final failure = settingsResult.fold((f) => f, (_) => null) ??
        rulesResult.fold((f) => f, (_) => null);
    if (failure != null) {
      loadError.value = failure.message;
      loadErrorIsFinal.value = failure is ForbiddenFailure;
      status.value = RemindersStatus.error;
      return;
    }
    settings.value = settingsResult.getOrElse(() => const ReminderSettings());
    rules.assignAll(rulesResult.getOrElse(() => const []));
    status.value = RemindersStatus.ready;
  }

  /// Reglas de un tipo (las de cita, por minutos de mayor a menor).
  List<ReminderRule> rulesOf(ReminderKind kind) => [
        for (final rule in rules)
          if (rule.kind == kind) rule,
      ]..sort((a, b) => (b.minutesBefore ?? 0).compareTo(a.minutesBefore ?? 0));

  bool canAdd(ReminderKind kind) => kind.allowsSeveral || rulesOf(kind).isEmpty;

  // --- Configuración ---------------------------------------------------------

  Future<void> setEnabled(bool enabled) => _saveSettings(
      (s) => s.copyWith(enabled: enabled),
      enabled ? 'Recordatorios activados' : 'Recordatorios apagados');

  Future<void> setWindowStart(String value) => _saveSettings(
      (s) => s.copyWith(sendWindowStart: value), 'Horario de envío guardado');

  Future<void> setWindowEnd(String value) => _saveSettings(
      (s) => s.copyWith(sendWindowEnd: value), 'Horario de envío guardado');

  Future<void> _saveSettings(
      ReminderSettings Function(ReminderSettings) change, String done) async {
    final current = settings.value;
    if (current == null || isSaving.value) return;
    isSaving.value = true;
    final result = await _updateSettings(change(current));
    isSaving.value = false;
    result.fold(_showFailure, (saved) {
      settings.value = saved;
      AppSnackbar.success(done, title: 'Listo');
    });
  }

  // --- Reglas ------------------------------------------------------------------

  /// Crea o edita [rule]. `true` si se guardó.
  Future<bool> saveRule(ReminderRule rule) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    final result = await _saveRule(rule);
    isSaving.value = false;
    return result.fold((failure) {
      _showFailure(failure);
      return false;
    }, (saved) {
      final index = rules.indexWhere((r) => r.id == saved.id);
      index >= 0 ? rules[index] = saved : rules.add(saved);
      AppSnackbar.success('${saved.kind.label}: guardado',
          title: 'Recordatorio guardado');
      return true;
    });
  }

  Future<void> setRuleActive(ReminderRule rule, bool active) async {
    await saveRule(rule.copyWith(isActive: active));
  }

  /// Borra tras confirmar. `true` si se borró.
  Future<bool> deleteRule(ReminderRule rule) async {
    final id = rule.id;
    if (id == null) return false;
    final confirmed = await AppDialogs.confirm(
      title: '¿Borrar este recordatorio?',
      message: 'Dejará de enviarse "${rule.kind.label}". El historial de lo '
          'ya enviado se conserva.',
      confirmLabel: 'Borrar',
      destructive: true,
    );
    if (!confirmed) return false;
    final result = await _deleteRule(id);
    return result.fold((failure) {
      _showFailure(failure);
      return false;
    }, (_) {
      rules.removeWhere((r) => r.id == id);
      AppSnackbar.success('Recordatorio borrado');
      return true;
    });
  }

  /// Texto de ejemplo de [template] (vacía = la del tipo). `null` si falló
  /// (ya avisado).
  Future<String?> preview(ReminderKind kind, String template) async {
    final result =
        await _preview(PreviewReminderParams(kind: kind, template: template));
    return result.fold((failure) {
      _showFailure(failure);
      return null;
    }, (text) => text);
  }

  static void _showFailure(Failure failure) {
    if (failure is ValidationFailure || failure is ConflictFailure) {
      AppSnackbar.warning(failure.message, title: 'Revisa el recordatorio');
    } else {
      AppSnackbar.error(failure.message, title: 'No se guardó');
    }
  }

  /// Icono por tipo, para la vista.
  static IconData iconOf(ReminderKind kind) => kind.icon;
}
