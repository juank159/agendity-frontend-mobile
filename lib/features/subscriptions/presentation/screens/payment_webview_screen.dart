// lib/features/subscriptions/presentation/screens/payment_webview_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:login_signup/features/subscriptions/presentation/controllers/subscription_controller.dart';

/// Muestra el checkout de Wompi y, cuando detecta la redirección de vuelta,
/// confirma el pago consultando el backend (`SubscriptionController.verifyPayment`).
///
/// La URL nunca decide si el pago fue exitoso: ni `id=`, ni `transaction_id=`,
/// ni los errores `net::ERR` de la webview.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  final SubscriptionController controller = Get.find<SubscriptionController>();

  late final String _url;
  WebViewController? _webViewController;
  final RxInt _progress = 0.obs;
  final Rx<String?> _loadError = Rx<String?>(null);
  bool _callbackHandled = false;

  bool get _isDemoUrl => _url.startsWith('myapp://');

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _url = (args?['url'] as String?) ?? '';
    controller.resetPaymentVerification();

    if (_url.isEmpty) return;

    if (_isDemoUrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showPaymentDemoDialog();
      });
      return;
    }

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => _progress.value = progress,
          onPageStarted: (url) {
            // Algunas plataformas no pasan los 302 por onNavigationRequest.
            if (_isCallbackUrl(url)) _onCallbackDetected();
          },
          onNavigationRequest: (request) {
            if (_isCallbackUrl(request.url)) {
              _onCallbackDetected();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            // Un error de carga NO significa pago exitoso. Solo se informa si
            // falla la página principal y no estamos ya verificando.
            if (error.isForMainFrame == true && !_callbackHandled) {
              _loadError.value = error.description;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  /// La redirección de vuelta es `myapp://payment-callback` o, cuando el
  /// backend la reemplaza para Wompi, una URL http(s) con ruta `/payment-callback`.
  bool _isCallbackUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme == 'myapp') return uri.host == 'payment-callback';
    return uri.path.contains('/payment-callback');
  }

  void _onCallbackDetected() {
    if (_callbackHandled) return;
    _callbackHandled = true;
    _verifyPayment();
  }

  Future<void> _verifyPayment() async {
    final status = await controller.verifyPayment();
    if (status == PaymentVerificationStatus.approved && mounted) {
      Get.offAllNamed(GetRoutes.paymentSuccess);
    }
  }

  void _reloadCheckout() {
    _loadError.value = null;
    _webViewController?.loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar Suscripción'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: _url.isEmpty
          ? ErrorState(
              title: 'Enlace de pago no válido',
              message: 'No se proporcionó una URL válida para el pago.',
              actionLabel: 'Volver',
              actionIcon: Icons.arrow_back,
              onRetry: () => Get.back(),
            )
          : Obx(() {
              final status = controller.paymentVerification.value;
              if (status != PaymentVerificationStatus.idle) {
                return _buildVerification(context, status);
              }
              if (_isDemoUrl) {
                return const LoadingState(message: 'Abriendo pago de prueba…');
              }
              if (_loadError.value != null) {
                return ErrorState(
                  title: 'No se pudo cargar la página de pago',
                  message: _loadError.value!,
                  onRetry: _reloadCheckout,
                );
              }
              return Column(
                children: [
                  if (_progress.value < 100)
                    LinearProgressIndicator(value: _progress.value / 100),
                  Expanded(
                    child: WebViewWidget(controller: _webViewController!),
                  ),
                ],
              );
            }),
    );
  }

  Widget _buildVerification(
      BuildContext context, PaymentVerificationStatus status) {
    final message = controller.paymentVerificationMessage.value;

    switch (status) {
      case PaymentVerificationStatus.error:
        return ErrorState(
          title: 'No se pudo verificar el pago',
          message: message,
          actionLabel: 'Reintentar verificación',
          onRetry: _verifyPayment,
        );
      case PaymentVerificationStatus.pending:
        return _VerificationMessage(
          icon: Icons.access_time,
          title: 'Pago en proceso',
          message: message,
          primaryLabel: 'Verificar de nuevo',
          onPrimary: _verifyPayment,
          secondaryLabel: 'Ir al inicio',
          onSecondary: () => Get.offAllNamed(GetRoutes.home),
        );
      case PaymentVerificationStatus.failed:
        return _VerificationMessage(
          icon: Icons.cancel_outlined,
          title: 'Pago no completado',
          message: message,
          primaryLabel: 'Volver a los planes',
          onPrimary: () => Get.back(),
          secondaryLabel: 'Verificar de nuevo',
          onSecondary: _verifyPayment,
        );
      case PaymentVerificationStatus.verifying:
      case PaymentVerificationStatus.approved:
      case PaymentVerificationStatus.idle:
        return const LoadingState(message: 'Verificando pago…');
    }
  }

  // Flujo de demostración (cuando el backend devuelve `myapp://payment-demo`).
  // "Aprobar" ya no da el pago por hecho: consulta el estado en el backend.
  void _showPaymentDemoDialog() {
    final uri = Uri.parse(_url);
    final reference = uri.queryParameters['reference'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
              Navigator.of(dialogContext).pop();
              controller.markPaymentRejected();
            },
            child: const Text('Rechazar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _onCallbackDetected();
            },
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }
}

class _VerificationMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  const _VerificationMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPrimary,
                child: Text(primaryLabel),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
          ],
        ),
      ),
    );
  }
}
