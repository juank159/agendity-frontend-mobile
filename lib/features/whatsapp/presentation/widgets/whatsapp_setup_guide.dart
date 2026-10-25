import 'package:flutter/material.dart';

class WhatsappSetupGuide extends StatelessWidget {
  const WhatsappSetupGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: scheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Cómo conectar tu WhatsApp:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStep(
              scheme: scheme,
              number: 1,
              text:
                  'Guarda el contacto +34 621 64 49 18 en tu teléfono (por ejemplo, como "CallMeBot").',
            ),
            _buildStep(
              scheme: scheme,
              number: 2,
              text:
                  'Envíale por WhatsApp el mensaje: I allow callmebot to send me messages',
            ),
            _buildStep(
              scheme: scheme,
              number: 3,
              text: 'Recibirás un mensaje con tu API Key personal.',
            ),
            _buildStep(
              scheme: scheme,
              number: 4,
              text:
                  'Escribe aquí tu número (10 dígitos, sin +57) y la API Key.',
            ),
            _buildStep(
              scheme: scheme,
              number: 5,
              text: 'Pulsa "Guardar configuración" y envía una prueba.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required ColorScheme scheme,
    required int number,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              number.toString(),
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
