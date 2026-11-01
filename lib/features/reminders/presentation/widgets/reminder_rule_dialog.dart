import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';
import 'package:login_signup/features/reminders/domain/usecases/reminder_rules.dart';
import 'package:login_signup/features/reminders/presentation/controllers/reminders_controller.dart';
import 'package:login_signup/features/reminders/presentation/widgets/reminder_ui.dart';
import 'package:login_signup/shared/widgets/time_of_day_button.dart';

/// Crear o editar una regla: los campos de su tipo, la plantilla con sus
/// variables y la vista previa. Devuelve `true` si se guardó.
class ReminderRuleDialog extends StatefulWidget {
  final ReminderRule rule;

  const ReminderRuleDialog({super.key, required this.rule});

  static Future<bool> show(ReminderRule rule) async =>
      await Get.dialog<bool>(ReminderRuleDialog(rule: rule)) ?? false;

  @override
  State<ReminderRuleDialog> createState() => _ReminderRuleDialogState();
}

class _ReminderRuleDialogState extends State<ReminderRuleDialog> {
  RemindersController get _c => Get.find<RemindersController>();
  late final _template = TextEditingController(text: widget.rule.template);
  late final _amount = TextEditingController(text: _initialAmount());
  late String _unit = _initialUnit();
  late String _sendTime = widget.rule.sendTime ?? '09:00';
  String? _preview;
  bool _previewing = false;

  ReminderKind get _kind => widget.rule.kind;

  /// Minutos antes: se escriben en minutos, horas o días.
  String _initialUnit() {
    final m = widget.rule.minutesBefore ?? 1440;
    if (m % 1440 == 0) return 'días';
    if (m % 60 == 0) return 'horas';
    return 'minutos';
  }

  String _initialAmount() => switch (_kind) {
        ReminderKind.beforeAppointment => () {
            final m = widget.rule.minutesBefore ?? 1440;
            if (m % 1440 == 0) return '${m ~/ 1440}';
            if (m % 60 == 0) return '${m ~/ 60}';
            return '$m';
          }(),
        ReminderKind.winBack => '${widget.rule.daysWithoutVisit ?? 60}',
        _ => '',
      };

  int? get _minutesBefore {
    final n = int.tryParse(_amount.text.trim());
    if (n == null) return null;
    return switch (_unit) { 'días' => n * 1440, 'horas' => n * 60, _ => n };
  }

  @override
  void dispose() {
    _template.dispose();
    _amount.dispose();
    super.dispose();
  }

  ReminderRule _build() => ReminderRule(
        id: widget.rule.id,
        kind: _kind,
        isActive: widget.rule.isActive,
        minutesBefore:
            _kind == ReminderKind.beforeAppointment ? _minutesBefore ?? 0 : null,
        daysWithoutVisit: _kind == ReminderKind.winBack
            ? int.tryParse(_amount.text.trim()) ?? 0
            : null,
        sendTime: _kind == ReminderKind.beforeAppointment ? null : _sendTime,
        template: _template.text,
        category: widget.rule.category,
        metaTemplateName: widget.rule.metaTemplateName,
      );

  void _insert(String variable) {
    final text = _template.text;
    final selection = _template.selection;
    final at = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final token = '{$variable}';
    _template.value = TextEditingValue(
      text: text.replaceRange(at, end, token),
      selection: TextSelection.collapsed(offset: at + token.length),
    );
  }

  Future<void> _showPreview() async {
    setState(() => _previewing = true);
    final text = await _c.preview(_kind, _template.text);
    if (!mounted) return;
    setState(() {
      _previewing = false;
      _preview = text;
    });
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    if (await _c.saveRule(_build())) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = context.tokens.info;
    return AlertDialog(
      icon: Icon(_kind.icon),
      title: Text(widget.rule.id == null
          ? 'Nuevo: ${_kind.label}'
          : _kind.label),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_kind.explanation, style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              ..._kindFields(),
              const SizedBox(height: 16),
              TextField(
                key: const Key('reminder-template'),
                controller: _template,
                maxLines: 4,
                maxLength: ReminderRules.templateMaxLength,
                decoration: const InputDecoration(
                  labelText: 'Texto para el envío manual (opcional)',
                  helperText: 'Vacío = el texto de Agendity para este tipo.',
                  border: OutlineInputBorder(),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final v in ReminderRules.templateVariables)
                    ActionChip(
                      label: Text('{$v}'),
                      onPressed: () => _insert(v),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('reminder-preview'),
                  onPressed: _previewing ? null : _showPreview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Vista previa'),
                ),
              ),
              if (_preview != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: info.container,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_preview!,
                      key: const Key('reminder-preview-text'),
                      style: TextStyle(color: info.onContainer)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        Obx(() => FilledButton(
              onPressed: _c.isSaving.value ? null : _save,
              child: const Text('Guardar'),
            )),
      ],
    );
  }

  List<Widget> _kindFields() {
    final digits = [FilteringTextInputFormatter.digitsOnly];
    switch (_kind) {
      case ReminderKind.beforeAppointment:
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('reminder-amount'),
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  decoration: const InputDecoration(
                    labelText: 'Cuánto antes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _unit,
                items: const [
                  DropdownMenuItem(value: 'minutos', child: Text('minutos')),
                  DropdownMenuItem(value: 'horas', child: Text('horas')),
                  DropdownMenuItem(value: 'días', child: Text('días')),
                ],
                onChanged: (v) => setState(() => _unit = v ?? _unit),
              ),
            ],
          ),
        ];
      case ReminderKind.winBack:
        return [
          TextField(
            key: const Key('reminder-amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: digits,
            decoration: const InputDecoration(
              labelText: 'Días sin venir',
              helperText: 'De ${ReminderRules.minDaysWithoutVisit} a '
                  '${ReminderRules.maxDaysWithoutVisit}.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _sendTimeButton(),
        ];
      case ReminderKind.maintenance:
      case ReminderKind.birthday:
        return [_sendTimeButton()];
    }
  }

  Widget _sendTimeButton() => Align(
        alignment: Alignment.centerLeft,
        child: TimeOfDayButton(
          label: 'Hora de envío',
          value: _sendTime,
          semantics: 'Hora de envío del recordatorio',
          onPicked: (v) => setState(() => _sendTime = v),
        ),
      );
}
