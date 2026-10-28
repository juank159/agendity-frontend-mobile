import 'package:flutter/material.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';

/// Foto del profesional o sus iniciales (colores del tema).
class EmployeeAvatar extends StatelessWidget {
  final EmployeeEntity employee;
  final double radius;

  const EmployeeAvatar({super.key, required this.employee, this.radius = 28});

  String get _initials {
    final first = employee.name.isNotEmpty ? employee.name[0] : '';
    final last = employee.lastname.isNotEmpty ? employee.lastname[0] : '';
    final initials = '$first$last'.toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = employee.status == EmployeeStatus.active;
    final background =
        active ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final foreground =
        active ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final initials = Text(
      _initials,
      style: TextStyle(
        color: foreground,
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.65,
      ),
    );
    final image = employee.image;

    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: image != null && image.isNotEmpty
          ? ClipOval(
              child: Image.network(
                image,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => initials,
              ),
            )
          : initials,
    );
  }
}
