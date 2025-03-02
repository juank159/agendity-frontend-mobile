// lib/core/widgets/whatsapp_icon.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WhatsappIcon extends StatelessWidget {
  final double size;
  final Color color;

  const WhatsappIcon({
    Key? key,
    this.size = 24.0,
    this.color = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/whatsapp.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
