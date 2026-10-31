import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/payments/domain/entities/payment_review_item.dart';

/// Monto y motivo de un reembolso. Devuelve `(monto, motivo)` o `null`.
class RefundDialog extends StatefulWidget {
  final PaymentReviewItem item;

  const RefundDialog({super.key, required this.item});

  static Future<(double, String)?> show(PaymentReviewItem item) =>
      Get.dialog<(double, String)>(RefundDialog(item: item));

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  late final _amount = TextEditingController(
      text: widget.item.suggestedRefund.round().toString());
  late final _reason = TextEditingController(
      text: widget.item.isForCancelledAppointment
          ? 'Cita cancelada'
          : 'Pago de más');

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.undo),
      title: const Text('Registrar reembolso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pago de ${formatCop(widget.item.payment.netAmount)} de '
              '${widget.item.clientName}. Para que deje la revisión hay que '
              'devolver ${formatCop(widget.item.suggestedRefund)}.'),
          const SizedBox(height: 16),
          TextField(
            key: const Key('refund-amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Monto a devolver',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('refund-reason'),
            controller: _reason,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((
            double.tryParse(_amount.text) ?? 0,
            _reason.text,
          )),
          child: const Text('Reembolsar'),
        ),
      ],
    );
  }
}
