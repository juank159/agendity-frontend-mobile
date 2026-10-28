import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/utils/json_read.dart';

void main() {
  test('asDouble: num, texto decimal de Postgres y valores raros', () {
    expect(JsonRead.asDouble(45000), 45000.0);
    expect(JsonRead.asDouble('45000.00'), 45000.0);
    expect(JsonRead.asDouble(' 12.5 '), 12.5);
    expect(JsonRead.asDouble(null), 0);
    expect(JsonRead.asDouble('abc'), 0);
    expect(JsonRead.asDouble(true, fallback: -1), -1);
  });

  test('asInt: redondea y acepta texto', () {
    expect(JsonRead.asInt(3), 3);
    expect(JsonRead.asInt(2.6), 3);
    expect(JsonRead.asInt('3'), 3);
    expect(JsonRead.asInt('2.4'), 2);
    expect(JsonRead.asInt(null), 0);
    expect(JsonRead.asInt('x', fallback: 7), 7);
  });

  test('asString / asOptionalString recortan y tratan vacío como ausente', () {
    expect(JsonRead.asString('Ana '), 'Ana');
    expect(JsonRead.asString(null), '');
    expect(JsonRead.asString(' ', fallback: '-'), '-');
    expect(JsonRead.asOptionalString(''), isNull);
    expect(JsonRead.asOptionalString(42), '42');
  });

  test('asBool: bool, texto y valor por defecto', () {
    expect(JsonRead.asBool(false, fallback: true), false);
    expect(JsonRead.asBool('false', fallback: true), false);
    expect(JsonRead.asBool('true', fallback: false), true);
    expect(JsonRead.asBool(null, fallback: true), true);
  });

  test('asMap / asMapList ignoran lo que no es un objeto', () {
    expect(JsonRead.asMap({'a': 1}), {'a': 1});
    expect(JsonRead.asMap([1]), isNull);
    expect(
        JsonRead.asMapList([
          {'a': 1},
          'x',
          null
        ]),
        [
          {'a': 1}
        ]);
    expect(JsonRead.asMapList(null), isEmpty);
  });
}
