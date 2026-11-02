import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/notifications/domain/entities/app_notification.dart';
import 'package:login_signup/features/notifications/presentation/widgets/notifications_list.dart';

/// Tarjeta de un aviso (12.05).
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  Future<void> pump(WidgetTester tester, AppNotification n,
      {ThemeData? theme}) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? ThemeConfig.lightTheme,
      home: Scaffold(body: NotificationTile(notification: n)),
    ));
  }

  final unreadDot = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == 'Sin leer');

  const reminder = AppNotification(
      id: 'n1',
      type: 'APPOINTMENT_REMINDER',
      title: 'Cita en 30 min',
      message: 'Ana Ruiz · Cejas');

  testWidgets('sin leer: ícono de su tipo y punto "Sin leer"', (tester) async {
    await pump(tester, reminder);
    expect(find.text('Cita en 30 min'), findsOneWidget);
    expect(find.text('Ana Ruiz · Cejas'), findsOneWidget);
    expect(find.byIcon(Icons.alarm_rounded), findsOneWidget);
    expect(unreadDot, findsOneWidget);
  });

  testWidgets('leído: sin punto; con fecha', (tester) async {
    await pump(
        tester,
        AppNotification(
            id: 'n2',
            type: 'PAYMENT_RECEIVED',
            title: 'Pago',
            message: 'Recibido',
            read: true,
            createdAt: DateTime(2030, 1, 7, 15, 30)),
        theme: ThemeConfig.darkTheme);
    expect(unreadDot, findsNothing);
    expect(find.byIcon(Icons.payments_rounded), findsOneWidget);
    expect(find.textContaining(formatTime(DateTime(2030, 1, 7, 15, 30))),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
