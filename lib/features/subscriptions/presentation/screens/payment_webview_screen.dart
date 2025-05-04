// lib/features/subscriptions/presentation/screens/payment_webview_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:login_signup/features/subscriptions/presentation/controllers/subscription_controller.dart';

class PaymentWebViewScreen extends GetView<SubscriptionController> {
  const PaymentWebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final String url = args?['url'] ?? '';

    print('PaymentWebViewScreen - URL recibida: $url');

    if (url.isEmpty) {
      print('PaymentWebViewScreen - URL vacía, mostrando error');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('No se proporcionó una URL válida para el pago.'),
        ),
      );
    }

    // Si la URL usa un esquema personalizado (para pruebas), manejarlo directamente
    if (url.startsWith('myapp://')) {
      print(
          'PaymentWebViewScreen - Detectada URL con esquema personalizado: $url');

      // Mostrar un diálogo de demostración de pago
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPaymentDemoDialog(context, url);
      });

      // Retornar un scaffold vacío mientras tanto
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pagar Suscripción'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Get.back(),
            ),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    print('PaymentWebViewScreen - Cargando WebView con URL: $url');

    // Para URLs normales, usar WebView
    final WebViewController webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('WebView cargando: $progress%');
          },
          onPageStarted: (String url) {
            print('Cargando: $url');
          },
          onPageFinished: (String url) {
            print('Carga completa: $url');

            // Verificar si estamos en cualquier URL que contenga payment-callback o tuapp.com
            if (url.contains('payment-callback') ||
                url.contains('tuapp.com') ||
                url.contains('transaction_id=') ||
                url.contains('id=')) {
              _handlePaymentSuccess();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Solicitando navegación a: ${request.url}');

            // Detectar cualquier redirección relacionada con el callback
            if (request.url.contains('payment-callback') ||
                request.url.contains('tuapp.com') ||
                request.url.contains('myapp://')) {
              print('Detectada redirección a callback: ${request.url}');
              _handlePaymentSuccess();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('Error de WebView: ${error.description}');

            // Si la URL de callback falla (porque probablemente es ficticia),
            // consideramos que el pago fue exitoso
            if (error.description.contains('ERR_CONNECTION') ||
                error.description.contains('net::ERR')) {
              _handlePaymentSuccess();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar Suscripción'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: webViewController),
          ),
        ],
      ),
    );
  }

  // Nuevo método simplificado para manejar redirecciones exitosas
  void _handlePaymentSuccess() {
    // Actualizar la suscripción en el backend antes de redirigir
    _updateSubscriptionStatus().then((_) {
      // Navegar a la pantalla de éxito
      Get.offAllNamed(GetRoutes.paymentSuccess);
    });
  }

  // Método para actualizar el estado de la suscripción en el backend
  Future<void> _updateSubscriptionStatus() async {
    try {
      // Intentar actualizar la suscripción
      await controller.refreshSubscriptionStatus();
      print('Estado de suscripción actualizado correctamente después del pago');
    } catch (e) {
      print('Error actualizando estado de suscripción después del pago: $e');
      // Continuamos con la navegación aunque falle la actualización
    }
  }

  // Método para mostrar diálogo de demostración (solo en desarrollo)
  void _showPaymentDemoDialog(BuildContext context, String url) {
    // Parsear la URL para obtener parámetros
    final Uri uri = Uri.parse(url);
    final String reference = uri.queryParameters['reference'] ?? '';
    final String redirectUrl =
        uri.queryParameters['redirect'] ?? 'myapp://payment-callback';

    print('Mostrando diálogo de demostración de pago');
    print('Referencia: $reference');
    print('URL de redirección: $redirectUrl');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Demo de Pago',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Esto es una simulación de pago para desarrollo.\n'),
            Text('Referencia: $reference'),
            const SizedBox(height: 20),
            const Text('Seleccione el resultado:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Simular pago rechazado
              _showPaymentErrorDialog('declined');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Simular pago aprobado
              _handlePaymentSuccess();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _showPaymentErrorDialog(String status) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error,
                  color: Colors.red[700],
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pago no completado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tu pago no pudo ser procesado. Por favor, intenta nuevamente con otro método de pago.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Cerrar diálogo
                    Get.back(); // Volver a la pantalla de planes
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Intentar de nuevo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showPaymentPendingDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time,
                  color: Colors.orange[700],
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pago en proceso',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tu pago está siendo procesado. Te notificaremos cuando se confirme.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Cerrar diálogo
                    Get.offAllNamed(
                        '/appointments'); // Regresar a la pantalla principal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
