import 'package:dio/dio.dart';
import 'package:login_signup/features/payments/data/models/payment_model.dart';

/// Rutas `/payments` que usa la app. Los errores (400/403/404/409, red) salen
/// como `DioException` y los traduce `safeCall` en el repositorio.
abstract class PaymentRemoteDataSource {
  /// `POST /payments` (solo Owner). Responde 201 con el pago y su `appointment`.
  Future<PaymentModel> createPayment(PaymentModel payment);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final Dio _dio;

  /// Debe ser el Dio `tag: apiClientTag` (token y errores del núcleo).
  PaymentRemoteDataSourceImpl(this._dio);

  @override
  Future<PaymentModel> createPayment(PaymentModel payment) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/payments',
      data: payment.toJson(),
    );
    return PaymentModel.fromJson(response.data!);
  }
}
