import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/features/payments/domain/entities/payment_review_item.dart';
import 'package:login_signup/shared/widgets/app_dialog_title.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:login_signup/shared/widgets/money_field.dart';

/// Monto y motivo de un reembolso (12.07: el monto con `MoneyField`, en
/// pesos enteros). No deja reembolsar más de lo que queda del pago (lo
/// pagado menos lo ya devuelto): avisa en el campo y apaga "Reembolsar"; el
/// use case lo vuelve a comprobar. Devuelve `(monto, motivo)` o `null`.
class RefundDialog extends StatefulWidget {
  final PaymentReviewItem item;

  const RefundDialog({super.key, required this.item});

  static Future<(double, String)?> show(PaymentReviewItem item) =>
      Get.dialog<(double, String)>(RefundDialog(item: item));

  /// Aviso del campo para [amount] (pesos); `null` si es válido.
  static String? amountError(int? amount, double available) {
    if (amount == null || amount <= 0) return 'Escribe el monto a devolver';
    if (amount * 100 > (available * 100).round()) {
      return 'No puede superar lo que queda del pago (${formatCop(available)})';
    }
    return null;
  }

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  late final _amount = TextEditingController(
      text: MoneyField.textFor(widget.item.suggestedRefund.round()));
  late final _reason = TextEditingController(
      text: widget.item.isForCancelledAppointment
          ? 'Cita cancelada'
          : 'Pago de más');

  /// Lo que queda del pago sin devolver: el máximo del reembolso.
  double get _available => widget.item.payment.netAmount;

  String? _error;

  @override
  void initState() {
    super.initState();
    _error = RefundDialog.amountError(MoneyField.valueOf(_amount), _available);
  }

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _onAmount(int? amount) =>
      setState(() => _error = RefundDialog.amountError(amount, _available));

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDialogTitle(
                icon: Icons.undo_rounded,
                title: 'Registrar reembolso',
                subtitle: item.clientName,
              ),
              const SizedBox(height: 16),
              AppNote(
                'Pago de ${formatCop(item.payment.netAmount)} de '
                '${item.clientName}. Para que deje la revisión hay que '
                'devolver ${formatCop(item.suggestedRefund)}.',
                tone: AppTone.info,
                icon: Icons.info_outline_rounded,
              ),
              const SizedBox(height: 16),
              MoneyField(
                key: const Key('refund-amount'),
                controller: _amount,
                label: 'Monto a devolver',
                icon: Icons.undo_rounded,
                helperText:
                    'Hasta ${formatCop(_available)} (lo que queda del pago).',
                errorText: _error,
                onChanged: _onAmount,
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('refund-reason'),
                controller: _reason,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppGradientButton(
                      label: 'Reembolsar',
                      icon: Icons.undo_rounded,
                      expand: true,
                      onPressed: _error != null
                          ? null
                          : () => Navigator.of(context).pop((
                                (MoneyField.valueOf(_amount) ?? 0).toDouble(),
                                _reason.text,
                              )),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
