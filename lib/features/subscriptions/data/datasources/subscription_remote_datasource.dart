import 'package:dio/dio.dart';
import 'package:login_signup/features/subscriptions/data/models/subscription_checkout_model.dart';
import 'package:login_signup/features/subscriptions/data/models/subscription_limits_model.dart';
import 'package:login_signup/features/subscriptions/data/models/subscription_model.dart';

/// Rutas `/subscriptions` que usa la app. Sin token ni tenant manuales: el
/// backend saca el negocio del JWT (`tenant_id` en el body se ignora). Los
/// errores (403, red…) salen como `DioException` y los traduce `safeCall`.
abstract class SubscriptionRemoteDataSource {
  /// `GET /subscriptions/plans`: solo planes activos.
  Future<List<SubscriptionPlanModel>> getPlans();

  /// `GET /subscriptions/status`.
  Future<SubscriptionModel> getStatus();

  /// `GET /subscriptions/check-limits`.
  Future<SubscriptionLimitsModel> checkLimits();

  /// `POST /subscriptions/subscribe` (solo Owner, 201).
  Future<SubscriptionCheckoutModel> subscribe(String planId);

  /// `POST /subscriptions/refresh-status` (solo Owner, 200).
  Future<SubscriptionRefreshModel> refreshStatus();
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  /// A dónde vuelve Wompi tras pagar: la webview lo intercepta. En producción
  /// el backend lo cambia por `WOMPI_REDIRECT_URL` (exige https).
  static const paymentRedirectUrl = 'myapp://payment-callback';

  final Dio _dio;

  /// Debe ser el Dio `tag: apiClientTag` (token y errores del núcleo).
  SubscriptionRemoteDataSourceImpl(this._dio);

  @override
  Future<List<SubscriptionPlanModel>> getPlans() async {
    final response = await _dio.get<List<dynamic>>('/subscriptions/plans');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(SubscriptionPlanModel.fromJson)
        .toList();
  }

  @override
  Future<SubscriptionModel> getStatus() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/subscriptions/status');
    return SubscriptionModel.fromJson(response.data!);
  }

  @override
  Future<SubscriptionLimitsModel> checkLimits() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/subscriptions/check-limits');
    return SubscriptionLimitsModel.fromJson(response.data!);
  }

  @override
  Future<SubscriptionCheckoutModel> subscribe(String planId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/subscriptions/subscribe',
      data: {'plan_id': planId, 'redirect_url': paymentRedirectUrl},
    );
    return SubscriptionCheckoutModel.fromJson(response.data!);
  }

  @override
  Future<SubscriptionRefreshModel> refreshStatus() async {
    final response =
        await _dio.post<Map<String, dynamic>>('/subscriptions/refresh-status');
    return SubscriptionRefreshModel.fromJson(response.data!);
  }
}
