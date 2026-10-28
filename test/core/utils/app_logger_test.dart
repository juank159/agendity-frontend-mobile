import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/utils/app_logger.dart';

void main() {
  final lines = <String>[];
  late void Function(String) original;

  setUp(() {
    lines.clear();
    original = AppLogger.sink;
    AppLogger.sink = lines.add;
  });
  tearDown(() => AppLogger.sink = original);

  test('en debug (tests) escribe trazas y errores con su causa', () {
    AppLogger.debug('hola');
    AppLogger.error('falló', StateError('x'));
    AppLogger.error('sin causa');
    expect(lines, ['hola', 'falló: Bad state: x', 'sin causa']);
  });
}
