import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:login_signup/core/utils/formatters.dart';

/// Campo de dinero en pesos (D-24): muestra el separador de miles mientras se
/// escribe (`15000` → `15.000`). El símbolo `$` no va en el texto (es
/// decoración del campo: `MoneyField`, 12.03); el valor se lee con
/// [parseCop] (`int` en pesos).
///
/// - Solo cifras y sin decimales: cualquier otro carácter tecleado se ignora.
/// - El cursor queda junto a la misma cifra al escribir o borrar en medio.
/// - Borrar un separador borra la cifra de al lado (retroceso: la de la
///   izquierda; suprimir: la de la derecha), como en cualquier campo
///   formateado.
/// - Pegar `15.000`, `$ 15.000` o `15.000,50` deja `15.000`.
/// - Con [max], una edición que lo supera no se acepta (queda el valor
///   anterior). Sin [max], el tope es [copMaxDigits] cifras.
class CopInputFormatter extends TextInputFormatter {
  /// Monto máximo en pesos (incluido). `null` = sin tope propio.
  final int? max;

  const CopInputFormatter({this.max});

  /// Texto que muestra el campo para [amount] (`15.000`): para el valor
  /// inicial de un campo. Igual a `formatCopDigits`.
  static String format(int amount) => formatCopDigits(amount);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    var cursor = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, text.length)
        : text.length;

    // Se borró solo un separador: se borra la cifra de al lado.
    if (_rawDigits(text) == _rawDigits(oldValue.text) &&
        text.length < oldValue.text.length &&
        oldValue.selection.isValid &&
        oldValue.selection.isCollapsed) {
      final oldCursor = oldValue.selection.extentOffset;
      if (cursor == oldCursor - 1) {
        final i = _lastDigitBefore(text, cursor);
        if (i >= 0) {
          text = text.replaceRange(i, i + 1, '');
          cursor = i;
        }
      } else if (cursor == oldCursor) {
        final i = _firstDigitFrom(text, cursor);
        if (i >= 0) text = text.replaceRange(i, i + 1, '');
      }
    }

    // Pegado (más de un carácter nuevo): se descartan los decimales.
    if (text.length - oldValue.text.length > 1) {
      final withoutDecimals = dropCopDecimals(text);
      if (withoutDecimals != text) {
        text = withoutDecimals;
        cursor = math.min(cursor, text.length);
      }
    }

    final raw = _rawDigits(text);
    final digits = copDigitsOf(text);
    if (digits.isEmpty) {
      return const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0));
    }
    if (digits.length > copMaxDigits) return oldValue;
    final amount = int.parse(digits);
    final limit = max;
    if (limit != null && amount > limit) return oldValue;

    final leadingZeros = raw.length - digits.length;
    final digitsLeft =
        (_rawDigits(text.substring(0, cursor)).length - leadingZeros)
            .clamp(0, digits.length);
    final formatted = formatCopDigits(amount);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
          offset: _offsetAfterDigits(formatted, digitsLeft)),
    );
  }

  static final RegExp _nonDigit = RegExp(r'\D');

  static String _rawDigits(String text) => text.replaceAll(_nonDigit, '');

  static bool _isDigit(String text, int i) {
    final unit = text.codeUnitAt(i);
    return unit >= 0x30 && unit <= 0x39;
  }

  static int _lastDigitBefore(String text, int end) {
    for (var i = end - 1; i >= 0; i--) {
      if (_isDigit(text, i)) return i;
    }
    return -1;
  }

  static int _firstDigitFrom(String text, int start) {
    for (var i = start; i < text.length; i++) {
      if (_isDigit(text, i)) return i;
    }
    return -1;
  }

  /// Posición justo después de la cifra número [count] de [text] (0 = inicio).
  static int _offsetAfterDigits(String text, int count) {
    if (count <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < text.length; i++) {
      if (_isDigit(text, i) && ++seen == count) return i + 1;
    }
    return text.length;
  }
}
