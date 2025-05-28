import 'package:flutter/material.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';

class ToggleStatusDialog extends StatelessWidget {
  final Future<void> Function(bool) onConfirm;
  final EmployeeEntity employee;

  const ToggleStatusDialog({
    super.key,
    required this.employee,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final bool willActivate = !employee.isActive;
    final String action = willActivate ? 'activar' : 'desactivar';
    final Color mainColor = willActivate ? Colors.green : Colors.orange;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        '${willActivate ? 'Activar' : 'Desactivar'} Profesional',
        style: TextStyle(
          color: mainColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            willActivate ? Icons.check_circle : Icons.person_off,
            color: mainColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              children: [
                TextSpan(
                  text: '¿Estás seguro que deseas $action a ',
                ),
                TextSpan(
                  text: employee.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: willActivate ? Colors.green[200]! : Colors.orange[200]!,
            ),
            child: Row(
              children: [
                Icon(
                  willActivate
                      ? Icons.info_outline
                      : Icons.warning_amber_rounded,
                  color: mainColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    willActivate
                        ? 'El profesional estará disponible para asignar citas.'
                        : 'El profesional NO estará disponible para asignar citas.',
                    style: TextStyle(
                      color: mainColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: mainColor,
          ),
          onPressed: () async {
            await onConfirm(willActivate);
          },
          child: Text(
            willActivate ? 'Activar' : 'Desactivar',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
