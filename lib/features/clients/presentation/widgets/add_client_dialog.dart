// lib/features/clients/presentation/widgets/add_client_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';

class AddClientDialog {
  static void show() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Agregar Cliente',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 50,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.blue.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              _buildOptionItem(
                title: 'Nuevo Cliente',
                subtitle: 'Crear un cliente desde cero',
                icon: Icons.person_add_alt_1,
                iconColor: Colors.green,
                backgroundColor: Colors.green.shade50,
                onTap: () {
                  Get.back();
                  Get.toNamed('/clients/new');
                },
              ),
              const SizedBox(height: 16),
              _buildOptionItem(
                title: 'Importar Contactos',
                subtitle: 'Sincronizar desde dispositivo',
                icon: Icons.import_contacts,
                iconColor: Colors.blue,
                backgroundColor: Colors.blue.shade50,
                onTap: () => _importContacts(),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildOptionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _importContacts() async {
    final controller = Get.find<ClientsController>();
    Get.back();

    bool isDialogShowing = true;
    
    Get.dialog(
      WillPopScope(
        onWillPop: () async {
          print('⏹️ Usuario presionó botón atrás durante importación');
          isDialogShowing = false;
          return true; // Permitir cerrar el diálogo
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.contacts,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Importando contactos...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Procesando tus contactos del dispositivo\nEsto puede tomar unos segundos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    print('⏹️ Usuario canceló la importación manualmente');
                    isDialogShowing = false;
                    Get.back();
                  },
                  child: Text(
                    'Si tarda mucho, toca aquí para cerrar',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      print('🚀 Iniciando proceso de importación...');
      
      await controller.importContacts().timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          print('⏰ Timeout: La importación tomó demasiado tiempo');
          throw Exception('La importación tomó demasiado tiempo. Intenta nuevamente.');
        },
      );
      
      print('✅ Importación completada, cerrando diálogo...');
      
      // ✅ SOLUCIÓN: Usar Get.until para cerrar específicamente todos los diálogos hasta llegar a la página principal
      if (isDialogShowing) {
        Get.until((route) => !Get.isDialogOpen!);
        print('✅ Diálogo cerrado exitosamente con Get.until');
      } else {
        print('ℹ️ Diálogo ya fue cerrado por el usuario');
      }
      
    } catch (e) {
      print('❌ Error durante importación: $e');
      
      // Cerrar el diálogo de loading si está abierto
      if (isDialogShowing) {
        Get.until((route) => !Get.isDialogOpen!);
      }
      
      // Mostrar diálogo de error
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 50,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error al importar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No se pudieron importar los contactos: ${e.toString()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
