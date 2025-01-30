// lib/features/auth/presentation/widgets/custom_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum DialogType { success, error, warning }

class CustomDialog {
  static void show({
    required String title,
    required String message,
    required DialogType type,
    VoidCallback? onConfirm,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(type),
              SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 24),
              _buildButton(type, onConfirm),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  static Widget _buildIcon(DialogType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case DialogType.success:
        iconData = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case DialogType.error:
        iconData = Icons.error_outline;
        color = Colors.red;
        break;
      case DialogType.warning:
        iconData = Icons.warning_amber;
        color = Colors.orange;
        break;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 48,
        color: color,
      ),
    );
  }

  static Widget _buildButton(DialogType type, VoidCallback? onConfirm) {
    Color color;
    String text;

    switch (type) {
      case DialogType.success:
        color = Colors.green;
        text = 'Continuar';
        break;
      case DialogType.error:
        color = Colors.red;
        text = 'Entendido';
        break;
      case DialogType.warning:
        color = Colors.orange;
        text = 'Aceptar';
        break;
    }

    return TextButton(
      onPressed: () {
        Get.back();
        if (onConfirm != null) onConfirm();
      },
      style: TextButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
