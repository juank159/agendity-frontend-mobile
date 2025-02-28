import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData? icon;
  final Color? color;
  final bool isOutlined;

  const CustomButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.color,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Theme.of(context).primaryColor;

    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: buttonColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        child: _buildButtonContent(buttonColor),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      child: _buildButtonContent(Colors.white),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (icon != null) {
      return Row(
        mainAxisSize:
            MainAxisSize.min, // Cambio aquí para evitar desbordamiento
        children: [
          Icon(icon, color: textColor, size: 18), // Reducir tamaño del icono
          const SizedBox(width: 4), // Reducir espacio
          Flexible(
            // Envolver el texto con Flexible
            child: Text(
              text,
              style: TextStyle(
                  color: textColor, fontSize: 13), // Reducir tamaño del texto
              overflow: TextOverflow.ellipsis, // Para evitar desbordamiento
            ),
          ),
        ],
      );
    }
    return Text(
      text,
      style: TextStyle(color: textColor),
      overflow: TextOverflow.ellipsis,
    );
  }
}
