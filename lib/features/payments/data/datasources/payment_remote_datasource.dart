import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:login_signup/features/payments/data/models/payment_model.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class PaymentRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;

  PaymentRemoteDataSource({
    required this.dio,
    required this.localStorage,
  });

  Future<PaymentModel> createPayment(PaymentModel payment) async {
    try {
      final token = await localStorage.getToken();
      debugPrint('Creando pago: ${payment.toJson()}');

      final response = await dio.post(
        '/payments',
        data: payment.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      debugPrint(
          'Respuesta del servidor (createPayment): ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('Pago creado exitosamente');
        return PaymentModel.fromJson(response.data);
      }

      throw Exception(
          'El servidor respondió con código ${response.statusCode}');
    } catch (e) {
      debugPrint('Error en createPayment: $e');
      if (e is DioException) {
        debugPrint('DioError tipo: ${e.type}');
        debugPrint('DioError mensaje: ${e.message}');
        debugPrint(
            'DioError respuesta: ${e.response?.statusCode}, ${e.response?.data}');
      }
      throw Exception('Error creating payment: $e');
    }
  }
}
