import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/shared/controller/code_countdown.dart';

// testWidgets corre en una zona con tiempo falso: `tester.pump(d)` avanza
// los Timer sin esperar de verdad.
void main() {
  test('format da mm:ss', () {
    expect(CodeCountdown.format(0), '00:00');
    expect(CodeCountdown.format(59), '00:59');
    expect(CodeCountdown.format(600), '10:00');
  });

  testWidgets('cuenta hacia atrás y avisa una vez al vencer', (tester) async {
    await tester.pumpWidget(const SizedBox());
    var expired = 0;
    final countdown = CodeCountdown(
      lifetime: const Duration(seconds: 3),
      onExpired: () => expired++,
    );
    expect(countdown.isActive, isFalse);

    countdown.start();
    expect(countdown.isActive, isTrue);
    expect(countdown.formatted, '00:03');

    await tester.pump(const Duration(seconds: 1));
    expect(countdown.secondsLeft.value, 2);

    await tester.pump(const Duration(seconds: 3));
    expect(countdown.isActive, isFalse);
    expect(expired, 1);
    countdown.dispose();
  });

  testWidgets('start reinicia y stop detiene sin avisar', (tester) async {
    await tester.pumpWidget(const SizedBox());
    var expired = 0;
    final countdown = CodeCountdown(
      lifetime: const Duration(seconds: 60),
      onExpired: () => expired++,
    )..start();

    await tester.pump(const Duration(seconds: 30));
    expect(countdown.secondsLeft.value, 30);
    countdown.start();
    expect(countdown.secondsLeft.value, 60);

    countdown.stop();
    await tester.pump(const Duration(seconds: 90));
    expect(countdown.isActive, isFalse);
    expect(expired, 0);
  });
}
