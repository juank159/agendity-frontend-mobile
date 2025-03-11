import 'package:flutter/material.dart';

class WhatsappSetupGuide extends StatelessWidget {
  const WhatsappSetupGuide({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Pasos para configurar notificaciones:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStep(
              number: 1,
              text:
                  'Guarda el contacto +34 621 64 49 18 en tu teléfono como "notifcationes de WhatsApp"',
            ),
            _buildStep(
              number: 2,
              text:
                  'Envía el mensaje "Autorizo callmebot a enviarme mensajes" a ese número por WhatsApp si las comillas',
            ),
            _buildStep(
              number: 3,
              text: 'Recibirás un mensaje con tu API Key personal',
            ),
            _buildStep(
              number: 4,
              text:
                  'Ingresa tu número de teléfono (sin código de país, sin +) y API Key en este formulario',
            ),
            _buildStep(
              number: 5,
              text: 'Haz clic en "Guardar configuracion"',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({required int number, required String text}) {
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
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Colors.white,
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
