// lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:login_signup/core/errors/exceptions.dart';
import 'package:login_signup/features/subscriptions/data/models/subscription_model.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class SubscriptionRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;

  SubscriptionRemoteDataSource({
    required this.dio,
    required this.localStorage,
  });

  // Obtener todos los planes disponibles
  Future<List<SubscriptionPlanModel>> getAllPlans() async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/subscriptions/plans',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> plansJson = response.data;
        return plansJson
            .map((json) => SubscriptionPlanModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to load plans',
          statusCode: response.statusCode ?? 0,
        );
      }
    } catch (e) {
      print('Error loading plans: $e');
      throw ServerException(
        message: 'Error retrieving plans: ${e.toString()}',
      );
    }
  }

  // Verificar el estado de la suscripción
  Future<Map<String, dynamic>> checkSubscriptionStatus() async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/subscriptions/check-limits',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ServerException(
          message: 'Failed to check subscription status',
          statusCode: response.statusCode ?? 0,
        );
      }
    } catch (e) {
      print('Error checking subscription status: $e');
      throw ServerException(
        message: 'Error checking subscription status: ${e.toString()}',
      );
    }
  }

  // Obtener la suscripción actual
  Future<SubscriptionModel> getCurrentSubscription() async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/subscriptions/status',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return SubscriptionModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to get subscription status',
          statusCode: response.statusCode ?? 0,
        );
      }
    } catch (e) {
      print('Error getting subscription: $e');
      throw ServerException(
        message: 'Error retrieving subscription: ${e.toString()}',
      );
    }
  }

  // Crear una suscripción pagada

  Future<Map<String, dynamic>> createPaidSubscription(
      String planId, String redirectUrl) async {
    try {
      final token = await localStorage.getToken();
      final tenantId = _extractTenantId(token ?? '');

      final response = await dio.post(
        '/subscriptions/subscribe',
        data: {
          'plan_id': planId,
          'redirect_url': redirectUrl,
          'tenant_id': tenantId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw ServerException(
          message: 'Failed to create subscription',
          statusCode: response.statusCode ?? 0,
        );
      }
    } catch (e) {
      print('Error creating subscription: $e');
      throw ServerException(
        message: 'Error creating subscription: ${e.toString()}',
      );
    }
  }

  // Obtener el plan por ID
  Future<SubscriptionPlanModel> getPlanById(String id) async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/subscriptions/plans/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return SubscriptionPlanModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to get plan',
          statusCode: response.statusCode ?? 0,
        );
      }
    } catch (e) {
      print('Error getting plan: $e');
      throw ServerException(
        message: 'Error retrieving plan: ${e.toString()}',
      );
    }
  }

  // Método para extraer el Tenant ID del token
  String _extractTenantId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length > 1) {
        final payload = base64Url.normalize(parts[1]);
        final decoded = utf8.decode(base64Url.decode(payload));
        final Map<String, dynamic> data = jsonDecode(decoded);
        return data['tenant_id'] ?? '';
      }
    } catch (e) {
      print('Error extracting tenant_id: $e');
    }
    return '';
  }
}
