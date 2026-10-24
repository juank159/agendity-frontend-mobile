import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/empty_state.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/core/widgets/loading_state.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeConfig.lightTheme,
      home: Scaffold(body: child),
    );

ListStateView<String> _view({
  bool isLoading = false,
  String? error,
  List<String> items = const [],
  VoidCallback? onRetry,
  VoidCallback? onEmptyAction,
}) =>
    ListStateView<String>(
      isLoading: isLoading,
      error: error,
      items: items,
      onRetry: onRetry,
      loadingMessage: 'Cargando...',
      emptyMessage: 'Sin datos',
      emptyActionLabel: 'Crear',
      onEmptyAction: onEmptyAction,
      builder: (context, items) =>
          ListView(children: [for (final i in items) Text(i)]),
    );

void main() {
  testWidgets('carga sin elementos → LoadingState', (tester) async {
    await tester.pumpWidget(_wrap(_view(isLoading: true)));
    expect(find.byType(LoadingState), findsOneWidget);
    expect(find.text('Cargando...'), findsOneWidget);
  });

  testWidgets('error sin elementos → ErrorState con reintento',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
        _wrap(_view(error: 'Sin conexión', onRetry: () => retries++)));
    expect(find.byType(ErrorState), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retries, 1);
  });

  testWidgets('error vacío ("") cuenta como sin error', (tester) async {
    await tester.pumpWidget(_wrap(_view(error: '')));
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('vacío → EmptyState con acción', (tester) async {
    var created = 0;
    await tester.pumpWidget(_wrap(_view(onEmptyAction: () => created++)));
    expect(find.text('Sin datos'), findsOneWidget);
    await tester.tap(find.text('Crear'));
    expect(created, 1);
  });

  testWidgets('con elementos se pinta la lista aunque recargue o falle',
      (tester) async {
    await tester.pumpWidget(
        _wrap(_view(isLoading: true, error: 'x', items: ['a', 'b'])));
    expect(find.text('a'), findsOneWidget);
    expect(find.byType(LoadingState), findsNothing);
    expect(find.byType(ErrorState), findsNothing);
  });

  testWidgets('ErrorState sin onRetry no muestra botón', (tester) async {
    await tester.pumpWidget(_wrap(const ErrorState(message: 'm')));
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('LoadingState sin mensaje solo muestra el indicador',
      (tester) async {
    await tester.pumpWidget(_wrap(const LoadingState()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });
}
