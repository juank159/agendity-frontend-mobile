import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/appointments/domain/usecases/appointment_rules.dart';

/// Confirma la cancelación y pide un motivo opcional. Devuelve el motivo
/// (`''` = sin motivo) o `null` si el usuario se arrepiente.
class CancelAppointmentDialog extends StatefulWidget {
  final String clientName;

  const CancelAppointmentDialog({super.key, required this.clientName});

  static Future<String?> show(String clientName) =>
      Get.dialog<String>(CancelAppointmentDialog(clientName: clientName));

  @override
  State<CancelAppointmentDialog> createState() =>
      _CancelAppointmentDialogState();
}

class _CancelAppointmentDialogState extends State<CancelAppointmentDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.event_busy_outlined, color: scheme.error),
      title: const Text('¿Cancelar la cita?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('La cita de ${widget.clientName} quedará cancelada y su hora '
              'se liberará. No se devuelve el cupo del plan.'),
          const SizedBox(height: 16),
          TextField(
            key: const Key('cancel-reason'),
            controller: _reason,
            maxLength: AppointmentRules.maxCancellationReasonLength,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
          child: const Text('Cancelar cita'),
        ),
      ],
    );
  }
}
