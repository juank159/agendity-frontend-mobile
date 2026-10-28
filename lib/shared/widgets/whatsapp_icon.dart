import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo de WhatsApp teñido con [color] (por defecto, el del `IconTheme`,
/// como un `Icon`).
class WhatsappIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const WhatsappIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      'assets/images/whatsapp.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
