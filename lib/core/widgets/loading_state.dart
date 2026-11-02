import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:shimmer/shimmer.dart';

/// Estado de carga de una pantalla o lista (guía §3): **esqueletos con
/// brillo** (filas con avatar y dos líneas) en lugar de la ruedita, con el
/// [message] debajo para el lector de pantalla y quien mire.
///
/// [skeleton] `false` = ruedita (esperas que no son una lista: abrir un pago,
/// verificarlo). Sin animaciones si el sistema las desactiva.
/// Ver también [ListStateView].
class LoadingState extends StatelessWidget {
  final String? message;
  final bool skeleton;

  /// Filas del esqueleto.
  final int rows;

  const LoadingState(
      {super.key, this.message, this.skeleton = true, this.rows = 5});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = message;
    final caption = text == null
        ? null
        : Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          );
    if (!skeleton) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (caption != null) ...[const SizedBox(height: 16), caption],
          ],
        ),
      );
    }
    return Semantics(
      label: text ?? 'Cargando',
      liveRegion: true,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            SkeletonShimmer(
              child: Column(
                children: [
                  for (var i = 0; i < rows; i++) const SkeletonListTile(),
                ],
              ),
            ),
            if (caption != null)
              Padding(padding: const EdgeInsets.all(16), child: caption),
          ],
        ),
      ),
    );
  }
}

/// Brillo que recorre los esqueletos de [child] (colores de los tokens).
class SkeletonShimmer extends StatelessWidget {
  final Widget child;

  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: Shimmer.fromColors(
        baseColor: tokens.skeletonBase,
        highlightColor: tokens.skeletonHighlight,
        enabled: AppMotion.enabled(context),
        period: const Duration(milliseconds: 1400),
        child: child,
      ),
    );
  }
}

/// Bloque gris redondeado de un esqueleto.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.tokens.skeletonBase,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Fila de esqueleto: tarjeta con avatar y dos líneas.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SkeletonBox(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.all(Radius.circular(24))),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14),
                SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: SkeletonBox(height: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
