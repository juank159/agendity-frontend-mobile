import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/error_mapper.dart';

Map<String, Object?> body(int status, String? code, Object? message,
        [Object? details]) =>
    {
      'statusCode': status,
      if (code != null) 'code': code,
      'message': message,
      if (details != null) 'details': details,
    };

DioException badResponse(int status, Object? data) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  group('ErrorMapper por code (§3)', () {
    // code, HTTP con que llega hoy (incluido el legado de D-11), tipo esperado.
    final cases = <(String, int, Type)>[
      (ApiErrorCode.validationError, 400, ValidationFailure),
      (ApiErrorCode.badRequest, 400, ValidationFailure),
      (ApiErrorCode.unauthorized, 401, UnauthorizedFailure),
      (ApiErrorCode.forbidden, 403, ForbiddenFailure),
      (ApiErrorCode.accountInactive, 403, ForbiddenFailure),
      (ApiErrorCode.notFound, 404, NotFoundFailure),
      (ApiErrorCode.slotUnavailable, 400, ConflictFailure),
      (ApiErrorCode.professionalInactive, 400, ConflictFailure),
      (ApiErrorCode.invalidStateTransition, 409, ConflictFailure),
      (ApiErrorCode.conflict, 409, ConflictFailure),
      (ApiErrorCode.appointmentPaid, 409, ConflictFailure),
      (ApiErrorCode.emailNotVerified, 409, ConflictFailure),
      (ApiErrorCode.ownerNotDeletable, 403, ConflictFailure),
      (ApiErrorCode.duplicateEmail, 409, DuplicateEmailFailure),
      (ApiErrorCode.duplicatePhone, 409, DuplicatePhoneFailure),
      (ApiErrorCode.trialLimitReached, 400, PaymentRequiredFailure),
      (ApiErrorCode.subscriptionInactive, 400, PaymentRequiredFailure),
      (ApiErrorCode.tooManyRequests, 429, TooManyRequestsFailure),
      (ApiErrorCode.internalError, 500, ServerFailure),
    ];

    for (final (code, status, type) in cases) {
      test('$code ($status) → $type', () {
        final failure = ErrorMapper.fromDioException(
          badResponse(status, body(status, code, 'Texto del servidor', ['d1'])),
        );
        expect(failure.runtimeType, type);
        expect(failure.code, code);
        expect(failure.statusCode, status);
        expect(failure.message, 'Texto del servidor');
        expect(failure.details, ['d1']);
      });
    }

    test('el code manda sobre el HTTP (SLOT_UNAVAILABLE con 400 legado)', () {
      final failure = ErrorMapper.fromResponse(
          400, body(400, 'SLOT_UNAVAILABLE', 'Horario no disponible'));
      expect(failure, isA<ConflictFailure>());
      expect(failure, isNot(isA<ValidationFailure>()));
    });

    test('code en minúsculas se normaliza', () {
      expect(ErrorMapper.fromResponse(404, body(404, 'not_found', 'x')),
          isA<NotFoundFailure>());
    });

    test('code desconocido → decide el HTTP y conserva el code', () {
      final failure =
          ErrorMapper.fromResponse(409, body(409, 'NUEVO_CODIGO', 'Algo'));
      expect(failure, isA<ConflictFailure>());
      expect(failure.code, 'NUEVO_CODIGO');
      expect(failure.message, 'Algo');
    });

    test('sin message usa el texto por defecto del failure', () {
      final failure = ErrorMapper.fromResponse(
          404, {'statusCode': 404, 'code': 'NOT_FOUND'});
      expect(failure.message, NotFoundFailure.defaultMessage);
      expect(failure.details, isEmpty);
    });
  });

  group('ErrorMapper sin code (respuestas antiguas o no JSON)', () {
    final cases = <(int, Type)>[
      (400, ValidationFailure),
      (422, ValidationFailure),
      (401, UnauthorizedFailure),
      (402, PaymentRequiredFailure),
      (403, ForbiddenFailure),
      (404, NotFoundFailure),
      (409, ConflictFailure),
      (429, TooManyRequestsFailure),
      (500, ServerFailure),
      (503, ServerFailure),
      (418, ServerFailure),
    ];
    for (final (status, type) in cases) {
      test('HTTP $status → $type', () {
        final failure = ErrorMapper.fromResponse(
            status, {'statusCode': status, 'message': 'm'});
        expect(failure.runtimeType, type);
        expect(failure.code, isNull);
        expect(failure.statusCode, status);
      });
    }

    test('message en lista (ValidationPipe antiguo) → texto unido y details',
        () {
      final failure = ErrorMapper.fromResponse(400, {
        'statusCode': 400,
        'message': ['email must be an email', 'name should not be empty'],
        'error': 'Bad Request',
      });
      expect(failure, isA<ValidationFailure>());
      expect(
          failure.message, 'email must be an email\nname should not be empty');
      expect(failure.details,
          ['email must be an email', 'name should not be empty']);
    });

    test('message en lista con details propios conserva los details', () {
      final failure = ErrorMapper.fromResponse(
          400, body(400, 'VALIDATION_ERROR', ['a', 'b'], ['x']));
      expect(failure.message, 'a\nb');
      expect(failure.details, ['x']);
    });

    test('cuerpo HTML de un 502 → ServerFailure sin mostrar el HTML', () {
      final failure = ErrorMapper.fromResponse(
          502, '<html><body>Bad gateway</body></html>');
      expect(failure, isA<ServerFailure>());
      expect(failure.message, ServerFailure.defaultMessage);
    });

    test('500 sin code no muestra el texto interno', () {
      final failure = ErrorMapper.fromResponse(
          500, {'statusCode': 500, 'message': 'QueryFailedError: ...'});
      expect(failure.message, ServerFailure.defaultMessage);
    });

    test('JSON como texto se decodifica', () {
      final failure = ErrorMapper.fromResponse(
          404, '{"statusCode":404,"code":"NOT_FOUND","message":"No existe"}');
      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, 'No existe');
    });

    test('cuerpo vacío → por HTTP con texto por defecto', () {
      final failure = ErrorMapper.fromResponse(403, null);
      expect(failure, isA<ForbiddenFailure>());
      expect(failure.message, ForbiddenFailure.defaultMessage);
    });
  });

  group('ErrorMapper errores de red', () {
    final options = RequestOptions(path: '/x');
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.badCertificate,
    ]) {
      test('$type → NetworkFailure', () {
        final failure = ErrorMapper.fromDioException(
            DioException(requestOptions: options, type: type));
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, isNotEmpty);
      });
    }

    test('cancel → CancelledFailure', () {
      expect(
          ErrorMapper.fromDioException(DioException(
              requestOptions: options, type: DioExceptionType.cancel)),
          isA<CancelledFailure>());
    });

    test('unknown sin respuesta → ServerFailure', () {
      expect(
          ErrorMapper.fromDioException(
              DioException(requestOptions: options, error: Exception('x'))),
          isA<ServerFailure>());
    });

    test('un Failure dentro del DioException se respeta', () {
      expect(
          ErrorMapper.fromDioException(DioException(
              requestOptions: options, error: const NotFoundFailure())),
          const NotFoundFailure());
    });

    test('fromObject: Failure tal cual; otros errores → ServerFailure', () {
      expect(ErrorMapper.fromObject(const NetworkFailure()),
          const NetworkFailure());
      expect(ErrorMapper.fromObject(TypeError()), isA<ServerFailure>());
    });
  });
}
