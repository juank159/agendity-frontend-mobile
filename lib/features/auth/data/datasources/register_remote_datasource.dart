// import 'package:dio/dio.dart';
// import 'package:login_signup/features/auth/data/models/register_model.dart';

// abstract class RegisterRemoteDataSource {
//   Future<(RegisterModel, String)> register({
//     required String name,
//     required String lastname,
//     required String email,
//     required String phone,
//     required String password,
//   });
// }

// class RegisterRemoteDataSourceImpl implements RegisterRemoteDataSource {
//   final Dio dio;

//   RegisterRemoteDataSourceImpl({required this.dio});

//   @override
//   Future<(RegisterModel, String)> register({
//     required String name,
//     required String lastname,
//     required String email,
//     required String phone,
//     required String password,
//   }) async {
//     try {
//       final response = await dio.post(
//         '/auth/register/owner',
//         data: {
//           'name': name,
//           'lastname': lastname,
//           'email': email,
//           'phone': phone,
//           'password': password,
//         },
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final userData = response.data['dataUser'];
//         final token = response.data['token'];
//         return (RegisterModel.fromJson(userData), token as String);
//       } else {
//         throw DioException(
//           requestOptions: response.requestOptions,
//           response: response,
//           error: 'Error en el registro',
//         );
//       }
//     } on DioException catch (e) {
//       if (e.response?.statusCode == 400) {
//         final errorMessage =
//             e.response?.data['message'] ?? 'Error en el registro';

//         if (errorMessage.contains('Key (email)')) {
//           throw Exception(
//               'El correo electrónico que ingresaste ya está en registrado');
//         }

//         if (errorMessage.contains('Key (phone)')) {
//           throw Exception(
//               'El número de teléfono que ingresaste ya está en registrado');
//         }
//         throw Exception(e.response?.data['message'] ?? 'Error en el registro');
//       }
//       rethrow;
//     }
//   }
// }

// ==========================

import 'package:dio/dio.dart';
import 'package:login_signup/features/auth/data/models/register_model.dart';

abstract class RegisterRemoteDataSource {
  Future<(RegisterModel, String)> register({
    required String name,
    required String lastname,
    required String email,
    required String phone,
    required String password,
  });
}

class RegisterRemoteDataSourceImpl implements RegisterRemoteDataSource {
  final Dio dio;

  RegisterRemoteDataSourceImpl({required this.dio});

  @override
  Future<(RegisterModel, String)> register({
    required String name,
    required String lastname,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/auth/register/owner', // ← CORREGIDO: Mantener ruta correcta
        data: {
          'name': name,
          'lastname': lastname,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ← CORREGIDO: Ajustar estructura de respuesta según el backend
        final userData = response
            .data['user']; // El backend retorna { user: {...}, token: "..." }
        final token = response.data['token'];
        return (RegisterModel.fromJson(userData), token as String);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Error en el registro',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage =
            e.response?.data['message'] ?? 'Error en el registro';

        // ← MEJORADO: Manejo de errores más específico
        if (errorMessage.contains('Ya existe un usuario con el email')) {
          throw Exception(
              'El correo electrónico que ingresaste ya está registrado');
        }

        if (errorMessage.contains('Ya existe un usuario con el teléfono')) {
          throw Exception(
              'El número de teléfono que ingresaste ya está registrado');
        }

        throw Exception(errorMessage);
      }

      // ← AGREGADO: Manejo de conflictos (409)
      if (e.response?.statusCode == 409) {
        final errorMessage = e.response?.data['message'] ?? 'Datos duplicados';
        throw Exception(errorMessage);
      }

      rethrow;
    }
  }
}
