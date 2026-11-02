import 'package:flutter/material.dart';
import 'package:login_signup/shared/widgets/app_dialog_title.dart';

/// Hoja inferior de la guía (§3): radio 28, asa superior (del
/// `BottomSheetTheme`), título con ícono, contenido y botones al pie.
///
/// ```dart
/// final ok = await AppSheet.show<bool>(context,
///     title: 'Filtrar', icon: Icons.tune_rounded,
///     builder: (context) => …,
///     actions: (context) => [ … ]);
/// ```
/// Se cierra con `Navigator.of(context).pop(valor)` (no con `Get.back()`,
/// que cerraría antes un snackbar abierto).
class AppSheet extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  const AppSheet({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
    this.actions = const [],
  });

  /// Abre la hoja y devuelve lo que se pase al cerrarla.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
    IconData? icon,
    String? subtitle,
    List<Widget> Function(BuildContext context)? actions,
    bool isDismissible = true,
  }) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: isDismissible,
        showDragHandle: true,
        builder: (context) => AppSheet(
          title: title,
          icon: icon,
          subtitle: subtitle,
          actions: actions?.call(context) ?? const [],
          child: builder(context),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Sube con el teclado.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: AppDialogTitle(
                icon: icon,
                title: title,
                subtitle: subtitle,
              ),
            ),
            Flexible(child: child),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: actions[i]),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
