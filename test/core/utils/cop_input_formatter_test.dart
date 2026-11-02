import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/utils/cop_input_formatter.dart';
import 'package:login_signup/core/utils/formatters.dart';

/// Simula el teclado sobre un campo con [CopInputFormatter]: cada acción
/// construye el `newValue` que daría Flutter y lo pasa por el formateador.
class _Field {
  _Field(this.formatter, [String text = '', int? cursor])
      : value = TextEditingValue(
            text: text,
            selection:
                TextSelection.collapsed(offset: cursor ?? text.length));

  final CopInputFormatter formatter;
  TextEditingValue value;

  String get text => value.text;
  int get cursor => value.selection.extentOffset;

  /// Texto con `|` en la posición del cursor (`15|.000`).
  String get shown =>
      '${text.substring(0, cursor)}|${text.substring(cursor)}';

  void _apply(String text, TextSelection selection) {
    value = formatter.formatEditUpdate(
        value, TextEditingValue(text: text, selection: selection));
  }

  void moveTo(int offset) =>
      value = value.copyWith(selection: TextSelection.collapsed(offset: offset));

  /// Escribe (o pega) [input] en el cursor, reemplazando la selección.
  void type(String input) {
    final s = value.selection;
    final next = text.replaceRange(s.start, s.end, input);
    _apply(next, TextSelection.collapsed(offset: s.start + input.length));
  }

  void backspace() {
    final s = value.selection;
    if (!s.isCollapsed) {
      return _apply(text.replaceRange(s.start, s.end, ''),
          TextSelection.collapsed(offset: s.start));
    }
    if (s.start == 0) return;
    _apply(text.replaceRange(s.start - 1, s.start, ''),
        TextSelection.collapsed(offset: s.start - 1));
  }

  void delete() {
    final s = value.selection;
    if (s.start >= text.length) return;
    _apply(text.replaceRange(s.start, s.start + 1, ''),
        TextSelection.collapsed(offset: s.start));
  }

  void selectAll() => value = value.copyWith(
      selection: TextSelection(baseOffset: 0, extentOffset: text.length));
}

void main() {
  const formatter = CopInputFormatter();

  group('escribir', () {
    test('separador de miles mientras se escribe', () {
      final field = _Field(formatter);
      final seen = <String>[];
      for (final digit in '1500000'.split('')) {
        field.type(digit);
        seen.add(field.shown);
      }
      expect(seen, [
        '1|',
        '15|',
        '150|',
        '1.500|',
        '15.000|',
        '150.000|',
        '1.500.000|',
      ]);
      expect(parseCop(field.text), 1500000);
    });

    test('ignora letras, puntos, comas, signos y espacios', () {
      final field = _Field(formatter, '15.000');
      for (final char in ['a', '.', ',', '-', ' ', r'$', 'é']) {
        field.type(char);
        expect(field.shown, '15.000|', reason: char);
      }
      final empty = _Field(formatter)..type('x');
      expect(empty.shown, '|');
    });

    test('ceros a la izquierda: "0" se queda, "05" → "5"', () {
      final field = _Field(formatter)..type('0');
      expect(field.shown, '0|');
      field.type('0');
      expect(field.shown, '0|');
      field.type('5');
      expect(field.shown, '5|');
      field
        ..moveTo(0)
        ..type('0');
      expect(field.shown, '|5');
    });

    test('escribir en medio deja el cursor junto a la cifra escrita', () {
      final field = _Field(formatter, '1.500', 1); // 1|.500
      field.type('2');
      expect(field.shown, '12|.500');
      field.moveTo(4); // 12.5|00
      field.type('9');
      expect(field.shown, '125.9|00');
    });

    test('escribir al inicio', () {
      final field = _Field(formatter, '500', 0)..type('2');
      expect(field.shown, '2|.500');
    });

    test('reemplazar todo lo seleccionado', () {
      final field = _Field(formatter, '1.500.000')
        ..selectAll()
        ..type('7');
      expect(field.shown, '7|');
    });
  });

  group('borrar', () {
    test('retroceso al final', () {
      final field = _Field(formatter, '1.500.000');
      final seen = <String>[];
      for (var i = 0; i < 7; i++) {
        field.backspace();
        seen.add(field.shown);
      }
      expect(seen, [
        '150.000|',
        '15.000|',
        '1.500|',
        '150|',
        '15|',
        '1|',
        '|',
      ]);
      expect(parseCop(field.text), isNull);
    });

    test('retroceso en medio', () {
      final field = _Field(formatter, '125.900', 5); // 125.9|00
      field.backspace();
      expect(field.shown, '12.5|00');
    });

    test('retroceso justo después del separador borra la cifra anterior', () {
      final field = _Field(formatter, '15.000', 3); // 15.|000
      field.backspace();
      expect(field.shown, '1|.000');
      expect(parseCop(field.text), 1000);
    });

    test('suprimir justo antes del separador borra la cifra siguiente', () {
      final field = _Field(formatter, '15.000', 2); // 15|.000
      field.delete();
      expect(field.shown, '1.5|00');
      expect(parseCop(field.text), 1500);
    });

    test('suprimir en medio', () {
      final field = _Field(formatter, '1.500', 3); // 1.5|00
      field.delete();
      expect(field.shown, '15|0');
    });

    test('borrar la primera cifra deja los ceros fuera', () {
      final field = _Field(formatter, '1.005', 1); // 1|.005
      field.backspace();
      expect(field.shown, '|5');
    });

    test('borrar la selección en medio', () {
      final field = _Field(formatter, '1.234.567');
      field.value = field.value.copyWith(
          selection: const TextSelection(baseOffset: 2, extentOffset: 6));
      field.backspace(); // quita "23.4"
      expect(field.shown, '1|.567');
    });
  });

  group('pegar', () {
    for (final (pasted, amount) in [
      ('15.000', 15000),
      (r'$ 15.000', 15000),
      (r'$15.000', 15000),
      ('15000', 15000),
      ('15 000', 15000),
      ('15.000,50', 15000),
      ('45000.00', 45000),
      ('1.250.000', 1250000),
      (' 2.500 ', 2500),
    ]) {
      test('"$pasted" → $amount', () {
        final field = _Field(formatter)..type(pasted);
        expect(field.text, formatCopDigits(amount));
        expect(field.cursor, field.text.length);
        expect(parseCop(field.text), amount);
      });
    }

    test('pegar en medio', () {
      final field = _Field(formatter, '1.000', 1) // 1|.000
        ..type('5.0');
      expect(field.shown, '150|.000');
    });

    test('pegar texto sin cifras no cambia nada', () {
      final field = _Field(formatter, '1.000')..type('hola');
      expect(field.shown, '1.000|');
    });
  });

  group('máximo', () {
    test('una edición que supera el máximo no se acepta', () {
      final field = _Field(const CopInputFormatter(max: 100000), '10.000');
      field.type('0');
      expect(field.shown, '100.000|');
      field.type('1');
      expect(field.shown, '100.000|');
      field
        ..moveTo(0)
        ..type('9');
      expect(field.shown, '|100.000');
    });

    test('pegar algo mayor que el máximo no se acepta', () {
      final field = _Field(const CopInputFormatter(max: 50000))
        ..type(r'$ 60.000');
      expect(field.shown, '|');
    });

    test('el máximo exacto sí entra', () {
      final field = _Field(const CopInputFormatter(max: 50000))
        ..type('50.000');
      expect(parseCop(field.text), 50000);
    });

    test('sin máximo, tope de 15 cifras', () {
      final field = _Field(formatter)..type('9' * copMaxDigits);
      expect(parseCop(field.text), int.parse('9' * copMaxDigits));
      final before = field.text;
      field.type('9');
      expect(field.text, before);
    });
  });

  test('format: valor inicial del campo', () {
    expect(CopInputFormatter.format(0), '0');
    expect(CopInputFormatter.format(15000), '15.000');
    expect(CopInputFormatter.format(1234567), '1.234.567');
  });

  testWidgets('en un TextField real', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: const [CopInputFormatter(max: 10000000)],
        ),
      ),
    ));
    await tester.enterText(find.byType(TextField), '250000');
    expect(controller.text, '250.000');
    expect(parseCop(controller.text), 250000);
    await tester.enterText(find.byType(TextField), r'$ 1.200');
    expect(controller.text, '1.200');
  });
}
