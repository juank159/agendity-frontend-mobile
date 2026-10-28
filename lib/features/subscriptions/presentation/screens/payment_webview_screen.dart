import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/subscription_controller.dart';
import '../widgets/payment_verification_view.dart';

/// Checkout de Wompi. Al detectar la redirección de vuelta verifica el pago
/// en el backend (`SubscriptionController.verifyPayment`): la URL nunca
/// decide si el pago fue exitoso (ni `id=`, ni los errores `net::ERR`).
///
/// `myapp://payment-demo…` (solo con `NODE_ENV=development` en el backend)
/// no abre la webview: pregunta si simular el pago y lo verifica igual,
/// contra el backend.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  final SubscriptionController controller = Get.find<SubscriptionController>();

  late final String _url;
  WebViewController? _webViewController;
  int _progress = 0;
  String? _loadError;
  bool _callbackHandled = false;

  bool get _isDemoUrl => _url.startsWith('myapp://');

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _url = args is Map ? (args['url'] as String? ?? '') : '';
    controller.resetVerification();

    if (_url.isEmpty) return;

    if (_isDemoUrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _askDemoPayment();
      });
      return;
    }

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (url) {
            // Algunas plataformas no pasan los 302 por onNavigationRequest.
            if (isPaymentCallbackUrl(url)) _onCallbackDetected();
          },
          onNavigationRequest: (request) {
            if (isPaymentCallbackUrl(request.url)) {
              _onCallbackDetected();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            // Un error de carga NO significa pago exitoso.
            if (error.isForMainFrame == true && !_callbackHandled && mounted) {
              setState(() => _loadError = error.description);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  void _onCallbackDetected() {
    if (_callbackHandled) return;
    _callbackHandled = true;
    _verify();
  }

  Future<void> _verify() async {
    final result = await controller.verifyPayment();
    if (result == PaymentVerificationStatus.approved && mounted) {
      Get.offAllNamed(GetRoutes.paymentSuccess,
          arguments: controller.verifiedSubscription);
    }
  }

  void _backToPlans() => Navigator.of(context).maybePop();

  void _goHome() => Get.offAllNamed(GetRoutes.home);

  void _reloadCheckout() {
    setState(() => _loadError = null);
    _webViewController?.loadRequest(Uri.parse(_url));
  }

  Future<void> _askDemoPayment() async {
    final reference = Uri.tryParse(_url)?.queryParameters['reference'] ?? '';
    final approve = await AppDialogs.confirm(
      title: 'Pago de prueba',
      message: 'Simulación de pago para desarrollo. El backend lo verifica '
          'igual que un pago real.'
          '${reference.isEmpty ? '' : '\nReferencia: $reference'}',
      confirmLabel: 'Simular pago aprobado',
      cancelLabel: 'Cancelar',
      icon: Icons.science_outlined,
    );
    if (!mounted) return;
    if (approve) {
      _onCallbackDetected();
    } else {
      _backToPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar suscripción'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
            onPressed: _backToPlans,
          ),
        ],
      ),
      body: _url.isEmpty
          ? ErrorState(
              title: 'Enlace de pago no válido',
              message: 'No se recibió un enlace de pago.',
              actionLabel: 'Volver',
              actionIcon: Icons.arrow_back,
              onRetry: _backToPlans,
            )
          : Obx(() {
              if (controller.verification.value !=
                  PaymentVerificationStatus.idle) {
                return PaymentVerificationView(
                  onBackToPlans: _backToPlans,
                  onGoHome: _goHome,
                  onVerify: _verify,
                );
              }
              if (_isDemoUrl) {
                return const LoadingState(message: 'Abriendo pago de prueba…');
              }
              if (_loadError != null) {
                return ErrorState(
                  title: 'No se pudo cargar la página de pago',
                  message: _loadError!,
                  onRetry: _reloadCheckout,
                );
              }
              return Column(
                children: [
                  if (_progress < 100)
                    LinearProgressIndicator(value: _progress / 100),
                  Expanded(
                    child: WebViewWidget(controller: _webViewController!),
                  ),
                ],
              );
            }),
    );
  }
}

/// La redirección de vuelta es `myapp://payment-callback` o, cuando el
/// backend la reemplaza para Wompi, una URL http(s) con ruta `/payment-callback`.
bool isPaymentCallbackUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (uri.scheme == 'myapp') return uri.host == 'payment-callback';
  return uri.path.contains('/payment-callback');
}
