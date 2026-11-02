import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_pill.dart';
import 'package:login_signup/shared/widgets/app_search_field.dart';
import 'package:login_signup/shared/widgets/app_section_card.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';

/// Piezas del kit añadidas en 12.06: `AppPill`, `AppSectionCard` y
/// `AppSearchField`.
void main() {
  Future<void> pump(WidgetTester tester, Widget child,
      {ThemeData? theme}) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? ThemeConfig.lightTheme,
      home: Scaffold(body: Center(child: child)),
    ));
  }

  testWidgets('AppPill: neutra con los colores del tema o con un tono',
      (tester) async {
    await pump(
        tester,
        const Column(children: [
          AppPill(label: '45 min', icon: Icons.schedule_rounded),
          AppPill(label: 'Inactivo', tabular: true),
        ]));
    expect(find.text('45 min'), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    final context = tester.element(find.text('45 min'));
    final neutral = AppPill.neutral(context);
    expect(neutral.container,
        Theme.of(context).colorScheme.surfaceContainerHighest);
  });

  testWidgets('StatusChip delega en AppPill y conserva "Estado: …"',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, StatusChip.toReschedule());
    expect(find.byType(AppPill), findsOneWidget);
    expect(find.bySemanticsLabel('Estado: Por mover'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('AppSectionCard: tarjeta con encabezado y contenido',
      (tester) async {
    await pump(
        tester,
        const AppSectionCard(
          icon: Icons.spa_rounded,
          title: 'Precio y duración',
          subtitle: 'Lo que cobra y cuánto tarda',
          child: Text('contenido'),
        ));
    expect(find.byType(AppCard), findsOneWidget);
    final header =
        tester.widget<AppSectionHeader>(find.byType(AppSectionHeader));
    expect(header.title, 'Precio y duración');
    expect(header.icon, Icons.spa_rounded);
    expect(find.text('Lo que cobra y cuánto tarda'), findsOneWidget);
    expect(find.text('contenido'), findsOneWidget);
  });

  testWidgets('AppSearchField: borrar sin onClear vacía y avisa con ""',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];
    await pump(
        tester,
        SizedBox(
          width: 320,
          child: AppSearchField(
            controller: controller,
            hint: 'Buscar',
            onChanged: changes.add,
          ),
        ));
    expect(find.byTooltip('Borrar búsqueda'), findsNothing);
    await tester.enterText(find.byType(TextField), 'ana');
    await tester.pump();
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    await tester.tap(find.byTooltip('Borrar búsqueda'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(changes, ['ana', '']);
    expect(find.byTooltip('Borrar búsqueda'), findsNothing);
  });

  testWidgets('AppSearchField: con onClear lo llama a él', (tester) async {
    final controller = TextEditingController(text: 'x');
    addTearDown(controller.dispose);
    var cleared = 0;
    await pump(
        tester,
        SizedBox(
          width: 320,
          child: AppSearchField(
            controller: controller,
            hint: 'Buscar',
            clearTooltip: 'Limpiar búsqueda',
            onClear: () => cleared++,
          ),
        ),
        theme: ThemeConfig.darkTheme);
    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    expect(cleared, 1);
  });
}
