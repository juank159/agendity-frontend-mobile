import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final sheetIcon = icon;
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
              child: Row(
                children: [
                  if (sheetIcon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: tokens.primaryGradient,
                      ),
                      child:
                          Icon(sheetIcon, size: 20, color: tokens.onGradient),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(title,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        if (subtitle != null)
                          Text(subtitle!,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
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
