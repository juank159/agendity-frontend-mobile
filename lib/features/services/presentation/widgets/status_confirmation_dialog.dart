import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StatusConfirmationDialog extends StatelessWidget {
  final String categoryName;
  final bool newStatus;
  final Function onConfirm;

  const StatusConfirmationDialog({
    Key? key,
    required this.categoryName,
    required this.newStatus,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono de advertencia o confirmación
            CircleAvatar(
              backgroundColor:
                  newStatus ? Colors.green.shade100 : Colors.red.shade100,
              radius: 40,
              child: Icon(
                newStatus ? Icons.check_circle : Icons.warning_rounded,
                color: newStatus ? Colors.green : Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            // Título
            Text(
              newStatus ? 'Activar Categoría' : 'Desactivar Categoría',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            // Mensaje
            Text(
              newStatus
                  ? '¿Estás seguro de que deseas activar la categoría "$categoryName"? Los servicios asociados a esta categoría volverán a estar disponibles.'
                  : '¿Estás seguro de que deseas desactivar la categoría "$categoryName"? Esto ocultará también todos los servicios asociados a esta categoría.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 25),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onConfirm();
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: newStatus ? Colors.green : Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      newStatus ? 'Activar' : 'Desactivar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
