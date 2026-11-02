import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/cop_input_formatter.dart';
import 'package:login_signup/core/utils/formatters.dart';

/// Campo de dinero en pesos (D-24, guía §3): prefijo "$ ", separador de miles
/// **mientras se escribe** (`15000` se ve `$ 15.000`, con `CopInputFormatter`),
/// teclado numérico, cifras tabulares y valor `int?` en pesos (sin decimales).
///
/// Úsalo en **todo** monto: precio de servicio, pago, anticipo, abono,
/// reembolso, precio variable y comisiones con monto.
///
/// - Con [controller] (p. ej. el de un `GetxController`), el texto es el
///   formateado (`15.000`): léelo con [MoneyField.valueOf] o `parseCop`.
/// - Sin [controller], el campo crea el suyo con [initialValue].
/// - [onChanged] recibe el monto o `null` si está vacío.
/// - [validator] recibe el monto (no el texto).
class MoneyField extends StatefulWidget {
  final TextEditingController? controller;
  final int? initialValue;
  final ValueChanged<int?>? onChanged;
  final FormFieldValidator<int?>? validator;
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? icon;

  /// Tope en pesos (incluido); una edición que lo supera no se acepta.
  final int? max;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<int?>? onSubmitted;

  const MoneyField({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.label = 'Monto',
    this.hint,
    this.helperText,
    this.errorText,
    this.icon = Icons.payments_rounded,
    this.max,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  /// Monto del texto de un campo de dinero (`null` si está vacío).
  static int? valueOf(TextEditingController controller) =>
      parseCop(controller.text);

  /// Texto inicial para [amount] (`15.000`), para crear un controller.
  static String textFor(int? amount) =>
      amount == null ? '' : CopInputFormatter.format(amount);

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  TextEditingController? _own;

  TextEditingController get _controller =>
      widget.controller ??
      (_own ??=
          TextEditingController(text: MoneyField.textFor(widget.initialValue)));

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.tabular;
    final fieldIcon = widget.icon;
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.number,
      textInputAction: widget.textInputAction,
      inputFormatters: [CopInputFormatter(max: widget.max)],
      style: style,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixText: r'$ ',
        prefixStyle: style,
        prefixIcon: fieldIcon == null ? null : Icon(fieldIcon),
      ),
      onChanged: widget.onChanged == null
          ? null
          : (text) => widget.onChanged!(parseCop(text)),
      onFieldSubmitted: widget.onSubmitted == null
          ? null
          : (text) => widget.onSubmitted!(parseCop(text)),
      validator: widget.validator == null
          ? null
          : (text) => widget.validator!(parseCop(text)),
    );
  }
}
