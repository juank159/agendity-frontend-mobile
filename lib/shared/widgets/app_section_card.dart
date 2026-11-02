import 'package:flutter/material.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';

/// Sección de un formulario o de una ficha (guía §3): `AppCard` con su
/// `AppSectionHeader` (ícono en píldora, título y subtítulo) y el contenido
/// debajo. La usan Mi negocio, los formularios de servicio, cliente y
/// profesional y el detalle del profesional.
class AppSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const AppSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.margin = const EdgeInsets.fromLTRB(16, 10, 16, 6),
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: margin,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            padding: EdgeInsets.zero,
            icon: icon,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
