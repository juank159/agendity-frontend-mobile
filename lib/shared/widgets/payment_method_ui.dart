import 'package:flutter/material.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';

/// Ícono de cada método de pago (12.07; en shared por la regla de dos): los
/// chips de "Registrar pago", el historial de pagos del detalle de la cita,
/// "Pagos por revisar" y la gráfica de Informes. El texto es `displayName`
/// (common/enums).
extension PaymentMethodUi on PaymentMethod {
  IconData get icon => switch (this) {
        PaymentMethod.CASH => Icons.payments_rounded,
        PaymentMethod.CREDIT_CARD => Icons.credit_card_rounded,
        PaymentMethod.DEBIT_CARD => Icons.credit_score_rounded,
        PaymentMethod.TRANSFER => Icons.account_balance_rounded,
        PaymentMethod.ONLINE => Icons.language_rounded,
        PaymentMethod.CUSTOM => Icons.wallet_rounded,
      };
}

/// Ícono de un método que puede no conocerse (`null` = método propio o
/// desconocido).
IconData paymentMethodIcon(PaymentMethod? method) =>
    method?.icon ?? Icons.wallet_rounded;
