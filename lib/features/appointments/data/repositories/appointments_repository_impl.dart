// import 'dart:convert';

// import 'package:dartz/dartz.dart';
// import 'package:dio/dio.dart';
// import 'package:login_signup/core/errors/exceptions.dart';
// import 'package:login_signup/core/errors/failures.dart';
// import 'package:login_signup/core/network/network_info.dart';
// import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
// import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
// import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
// import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

// class AppointmentsRepositoryImpl implements AppointmentsRepository {
//   final AppointmentsRemoteDataSource remoteDataSource;
//   final NetworkInfo networkInfo;

//   AppointmentsRepositoryImpl(
//     this.remoteDataSource,
//     this.networkInfo,
//   );

//   @override
//   Future<List<AppointmentEntity>> getAppointments({
//     DateTime? startDate,
//     DateTime? endDate,
//     String? status,
//   }) async {
//     try {
//       print('\n=== Repository: getAppointments ===');
//       print('Start Date: $startDate');
//       print('End Date: $endDate');
//       print('Status: $status');

//       final result = await remoteDataSource.getAppointments(
//         startDate: startDate,
//         endDate: endDate,
//         status: status,
//       );

//       print('Repository: Got ${result.length} appointments');
//       return result;
//     } on DioException catch (e) {
//       print('Repository: DioException caught');
//       print('Error Type: ${e.type}');
//       print('Error Message: ${e.message}');
//       print('Error Response: ${e.response?.data}');

//       throw AppointmentException(
//         message: e.response?.data?['message'] ??
//             e.message ??
//             'Error getting appointments',
//         code: e.response?.statusCode,
//       );
//     } catch (e) {
//       print('Repository: Generic error caught: $e');
//       throw AppointmentException(message: e.toString());
//     }
//   }

//   @override
//   Future<AppointmentEntity> createAppointment(
//       AppointmentEntity appointment) async {
//     try {
//       if (appointment is! AppointmentModel) {
//         throw AppointmentException(
//           message: 'Invalid appointment type',
//         );
//       }

//       return await remoteDataSource.createAppointment(appointment);
//     } on DioException catch (e) {
//       throw AppointmentException(
//         message: e.message ?? 'Error creating appointment',
//         code: e.response?.statusCode,
//       );
//     } catch (e) {
//       throw AppointmentException(message: e.toString());
//     }
//   }

//   @override
//   Future<AppointmentEntity> updateAppointment(
//       AppointmentEntity appointment) async {
//     try {
//       if (appointment is! AppointmentModel) {
//         throw AppointmentException(
//           message: 'Invalid appointment type',
//         );
//       }

//       return await remoteDataSource.updateAppointment(appointment);
//     } on DioException catch (e) {
//       throw AppointmentException(
//         message: e.message ?? 'Error updating appointment',
//         code: e.response?.statusCode,
//       );
//     } catch (e) {
//       throw AppointmentException(message: e.toString());
//     }
//   }

//   @override
//   Future<void> deleteAppointment(String id) async {
//     try {
//       await remoteDataSource.deleteAppointment(id);
//     } on DioException catch (e) {
//       throw AppointmentException(
//         message: e.message ?? 'Error deleting appointment',
//         code: e.response?.statusCode,
//       );
//     } catch (e) {
//       throw AppointmentException(message: e.toString());
//     }
//   }

//   @override
//   Future<AppointmentEntity> getAppointmentById(String id) async {
//     try {
//       return await remoteDataSource.getAppointmentById(id);
//     } on DioException catch (e) {
//       throw AppointmentException(
//         message: e.message ?? 'Error getting appointment',
//         code: e.response?.statusCode,
//       );
//     } catch (e) {
//       throw AppointmentException(message: e.toString());
//     }
//   }

//   @override
//   Future<Either<Failure, List<AppointmentEntity>>>
//       getUpcomingAppointments() async {
//     if (await networkInfo.isConnected) {
//       try {
//         final appointments = await remoteDataSource.getUpcomingAppointments();
//         return Right(appointments);
//       } on ServerException catch (e) {
//         return Left(ServerFailure(message: e.message));
//       } catch (e) {
//         return Left(ServerFailure(message: e.toString()));
//       }
//     } else {
//       return Left(NetworkFailure());
//     }
//   }

//   @override
//   Future<AppointmentEntity?> updateAppointmentDirect({
//     required String appointmentId,
//     required Map<String, dynamic> data,
//   }) async {
//     try {
//       print('\n=== Repository: updateAppointmentDirect ===');
//       print('Appointment ID: $appointmentId');
//       print('Data: $data');

//       // Delegar al DataSource que ya tiene acceso a dio y localStorage
//       return await remoteDataSource.updateAppointmentDirect(
//           appointmentId, data);
//     } on DioException catch (e) {
//       print('Repository: DioException caught');
//       print('Error Type: ${e.type}');
//       print('Error Message: ${e.message}');
//       print('Error Response: ${e.response?.data}');

//       throw AppointmentException(
//         message: e.response?.data?['message'] ??
//             e.message ??
//             'Error updating appointment',
//         code: e.response?.statusCode,
//         originalError: e,
//         errorData: e.response?.data,
//       );
//     } catch (e) {
//       print('Repository: Generic error caught: $e');
//       throw AppointmentException(message: e.toString());
//     }
//   }

//   String _extractTenantId(String token) {
//     try {
//       final parts = token.split('.');
//       if (parts.length > 1) {
//         final payload = base64Url.normalize(parts[1]);
//         final decoded = utf8.decode(base64Url.decode(payload));
//         final Map<String, dynamic> data = jsonDecode(decoded);
//         return data['tenant_id'] ?? '';
//       }
//     } catch (e) {
//       print('Error extrayendo tenant_id: $e');
//     }
//     return '';
//   }
// }

// class AppointmentException implements Exception {
//   final String message;
//   final int? code;
//   final dynamic originalError; // Añadir este campo
//   final dynamic errorData; // Añadir este campo
//   AppointmentException({
//     required this.message,
//     this.code,
//     this.originalError, // Añadir este parámetro
//     this.errorData, // Añadir este parámetro
//   });

//   bool get isHorarioNoDisponible =>
//       message == 'Horario no disponible' ||
//       (errorData is Map && errorData['message'] == 'Horario no disponible');

//   @override
//   String toString() =>
//       'AppointmentException: $message ${code != null ? '(Code: $code)' : ''}';
// }

import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:login_signup/core/errors/exceptions.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/network_info.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

class AppointmentsRepositoryImpl implements AppointmentsRepository {
  final AppointmentsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AppointmentsRepositoryImpl(
    this.remoteDataSource,
    this.networkInfo,
  );

  @override
  Future<List<AppointmentEntity>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      print('\n=== Repository: getAppointments ===');
      print('Start Date: $startDate');
      print('End Date: $endDate');
      print('Status: $status');

      final result = await remoteDataSource.getAppointments(
        startDate: startDate,
        endDate: endDate,
        status: status,
      );

      print('Repository: Got ${result.length} appointments');
      return result;
    } on DioException catch (e) {
      print('Repository: DioException caught');
      print('Error Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Error Response: ${e.response?.data}');

      // Extraer el mensaje de error directamente de la respuesta del backend
      String errorMessage = 'Error getting appointments';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      throw AppointmentException(
        message: errorMessage,
        code: e.response?.statusCode,
        errorData: e.response?.data,
      );
    } catch (e) {
      print('Repository: Generic error caught: $e');
      throw AppointmentException(message: e.toString());
    }
  }

  @override
  Future<AppointmentEntity> createAppointment(
      AppointmentEntity appointment) async {
    try {
      if (appointment is! AppointmentModel) {
        throw AppointmentException(
          message: 'Invalid appointment type',
        );
      }

      return await remoteDataSource.createAppointment(appointment);
    } on DioException catch (e) {
      print('Repository: DioException caught in createAppointment');
      print('Error Type: ${e.type}');
      print('Error Response: ${e.response?.data}');

      // Extraer el mensaje de error directamente de la respuesta del backend
      String errorMessage = 'Error creating appointment';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
        print('Mensaje de error del backend: $errorMessage');
      }

      throw AppointmentException(
        message: errorMessage,
        code: e.response?.statusCode,
        errorData: e.response?.data,
        originalError: e,
      );
    } catch (e) {
      print('Repository: Generic error caught in createAppointment: $e');
      throw AppointmentException(message: e.toString());
    }
  }

  @override
  Future<AppointmentEntity> updateAppointment(
      AppointmentEntity appointment) async {
    try {
      if (appointment is! AppointmentModel) {
        throw AppointmentException(
          message: 'Invalid appointment type',
        );
      }

      return await remoteDataSource.updateAppointment(appointment);
    } on DioException catch (e) {
      // Extraer el mensaje de error directamente de la respuesta del backend
      String errorMessage = 'Error updating appointment';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }

      throw AppointmentException(
        message: errorMessage,
        code: e.response?.statusCode,
        errorData: e.response?.data,
      );
    } catch (e) {
      throw AppointmentException(message: e.toString());
    }
  }

  @override
  Future<void> deleteAppointment(String id) async {
    try {
      await remoteDataSource.deleteAppointment(id);
    } on DioException catch (e) {
      // Extraer el mensaje de error directamente de la respuesta del backend
      String errorMessage = 'Error deleting appointment';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }

      throw AppointmentException(
        message: errorMessage,
        code: e.response?.statusCode,
        errorData: e.response?.data,
      );
    } catch (e) {
      throw AppointmentException(message: e.toString());
    }
  }

  @override
  Future<AppointmentEntity> getAppointmentById(String id) async {
    try {
      return await remoteDataSource.getAppointmentById(id);
    } on DioException catch (e) {
      // Extraer el mensaje de error directamente de la respuesta del backend
      String errorMessage = 'Error getting appointment';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }

      throw AppointmentException(
        message: errorMessage,
        code: e.response?.statusCode,
        errorData: e.response?.data,
      );
    } catch (e) {
      throw AppointmentException(message: e.toString());
    }
  }

  @override
  Future<Either<Failure, List<AppointmentEntity>>>
      getUpcomingAppointments() async {
    if (await networkInfo.isConnected) {
      try {
        final appointments = await remoteDataSource.getUpcomingAppointments();
        return Right(appointments);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<AppointmentEntity?> updateAppointmentDirect({
    required String appointmentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('\n=== Repository: updateAppointmentDirect ===');
      print('Appointment ID: $appointmentId');
      print('Data: $data');

      // Delegar al DataSource que ya tiene acceso a dio y localStorage
      return await remoteDataSource.updateAppointmentDirect(
          appointmentId, data);
    } on DioException catch (e) {
      print('Repository: DioException caught');
      print('Error Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Error Response: ${e.response?.data}');

      // Extraer el mensaje de error directamente de la respuesta del backend
      String errorMessage = 'Error updating appointment';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }

      throw AppointmentException(
        message: errorMessage,
        code: e.response?.statusCode,
        originalError: e,
        errorData: e.response?.data,
      );
    } catch (e) {
      print('Repository: Generic error caught: $e');
      throw AppointmentException(message: e.toString());
    }
  }

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
      print('Error extrayendo tenant_id: $e');
    }
    return '';
  }
}

class AppointmentException implements Exception {
  final String message;
  final int? code;
  final dynamic originalError;
  final dynamic errorData;

  AppointmentException({
    required this.message,
    this.code,
    this.originalError,
    this.errorData,
  });

  bool get isHorarioNoDisponible =>
      message.contains('Horario no disponible') ||
      (errorData is Map &&
          errorData['message']?.toString().contains('Horario no disponible') ==
              true);

  bool get isSubscriptionLimitReached =>
      message.contains('límite de citas') ||
      message.contains('adquiere un plan') ||
      (errorData is Map &&
          (errorData['message']?.toString().contains('límite de citas') ==
                  true ||
              errorData['message']?.toString().contains('adquiere un plan') ==
                  true));

  @override
  String toString() =>
      'AppointmentException: $message ${code != null ? '(Code: $code)' : ''}';
}
