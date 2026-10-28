import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:login_signup/core/errors/failures.dart';

/// Traduce errores de red y respuestas de error a `Failure` (ARQUITECTURA.md §3).
///
/// Decide por `code`. Si la respuesta no trae `code` (formato antiguo o cuerpo
/// que no es JSON) recurre al HTTP. Nunca compara el texto de `message`.
typedef _Build = Failure Function(
    String? message, String? code, int? statusCode, List<String> details);

abstract final class ErrorMapper {
  /// Cualquier error capturado por `safeCall`.
  static Failure fromObject(Object error) {
    if (error is Failure) return error;
    if (error is DioException) return fromDioException(error);
    return const ServerFailure(
        message: 'Respuesta inesperada del servidor. Intenta de nuevo.');
  }

  static Failure fromDioException(DioException error) {
    final inner = error.error;
    if (inner is Failure) return inner;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(
            message: 'El servidor tardó demasiado en responder. '
                'Revisa tu conexión e intenta de nuevo.');
      case DioExceptionType.connectionError:
        return const NetworkFailure(
            message: 'No hay conexión con el servidor. Revisa tu internet.');
      case DioExceptionType.badCertificate:
        return const NetworkFailure(
            message:
                'No se pudo establecer una conexión segura con el servidor.');
      case DioExceptionType.cancel:
        return const CancelledFailure();
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final response = error.response;
        if (response != null) {
          return fromResponse(response.statusCode, response.data);
        }
        return const ServerFailure(
            message: 'No se pudo completar la solicitud. Intenta de nuevo.');
    }
  }

  /// Respuesta HTTP de error: `{ statusCode, code, message, details? }`.
  static Failure fromResponse(int? statusCode, Object? data) {
    final body = _asMap(data);
    final code = _code(body?['code']);
    final (message, details) = _messageAndDetails(body);

    final byCode = code == null ? null : _byCode[code];
    if (byCode != null) return byCode(message, code, statusCode, details);

    // Sin `code` reconocido: decide por HTTP. Conserva un `code` desconocido
    // para que la feature pueda mirarlo.
    final byStatus = _byStatus[statusCode];
    if (byStatus != null) return byStatus(message, code, statusCode, details);

    // 5xx y cualquier otro. Sin `code`, el texto de un 5xx no se muestra
    // (puede ser HTML de un proxy o un mensaje interno).
    final hideMessage =
        code == null && (statusCode == null || statusCode >= 500);
    return _server(hideMessage ? null : message, code, statusCode, details);
  }

  static const Map<String, _Build> _byCode = {
    ApiErrorCode.validationError: _validation,
    ApiErrorCode.badRequest: _validation,
    ApiErrorCode.unauthorized: _unauthorized,
    ApiErrorCode.forbidden: _forbidden,
    ApiErrorCode.accountInactive: _forbidden,
    ApiErrorCode.notFound: _notFound,
    ApiErrorCode.duplicateEmail: _duplicateEmail,
    ApiErrorCode.duplicatePhone: _duplicatePhone,
    ApiErrorCode.conflict: _conflict,
    ApiErrorCode.slotUnavailable: _conflict,
    ApiErrorCode.professionalInactive: _conflict,
    ApiErrorCode.invalidStateTransition: _conflict,
    ApiErrorCode.appointmentPaid: _conflict,
    ApiErrorCode.paymentAlreadyExists: _conflict,
    ApiErrorCode.emailNotVerified: _conflict,
    ApiErrorCode.ownerNotDeletable: _conflict,
    ApiErrorCode.categoryHasServices: _conflict,
    ApiErrorCode.appointmentInPast: _validation,
    ApiErrorCode.invalidVerificationCode: _validation,
    ApiErrorCode.trialLimitReached: _paymentRequired,
    ApiErrorCode.subscriptionInactive: _paymentRequired,
    ApiErrorCode.tooManyRequests: _tooManyRequests,
    ApiErrorCode.internalError: _server,
  };

  static const Map<int, _Build> _byStatus = {
    400: _validation,
    422: _validation,
    401: _unauthorized,
    402: _paymentRequired,
    403: _forbidden,
    404: _notFound,
    409: _conflict,
    429: _tooManyRequests,
  };

  static Failure _validation(String? m, String? c, int? s, List<String> d) =>
      ValidationFailure(message: m, code: c, statusCode: s, details: d);
  static Failure _unauthorized(String? m, String? c, int? s, List<String> d) =>
      UnauthorizedFailure(message: m, code: c, statusCode: s, details: d);
  static Failure _forbidden(String? m, String? c, int? s, List<String> d) =>
      ForbiddenFailure(message: m, code: c, statusCode: s, details: d);
  static Failure _notFound(String? m, String? c, int? s, List<String> d) =>
      NotFoundFailure(message: m, code: c, statusCode: s, details: d);
  static Failure _conflict(String? m, String? c, int? s, List<String> d) =>
      ConflictFailure(message: m, code: c, statusCode: s, details: d);
  static Failure _duplicateEmail(
          String? m, String? c, int? s, List<String> d) =>
      DuplicateEmailFailure(message: m, statusCode: s, details: d);
  static Failure _duplicatePhone(
          String? m, String? c, int? s, List<String> d) =>
      DuplicatePhoneFailure(message: m, statusCode: s, details: d);
  static Failure _paymentRequired(
          String? m, String? c, int? s, List<String> d) =>
      PaymentRequiredFailure(message: m, code: c, statusCode: s, details: d);
  static Failure _tooManyRequests(
          String? m, String? c, int? s, List<String> d) =>
      TooManyRequestsFailure(message: m, code: c, statusCode: s, details: d);
  static Failure _server(String? m, String? c, int? s, List<String> d) =>
      ServerFailure(message: m, code: c, statusCode: s, details: d);

  static Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.trimLeft().startsWith('{')) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  static String? _code(Object? raw) {
    if (raw is! String) return null;
    final code = raw.trim().toUpperCase();
    return code.isEmpty ? null : code;
  }

  /// `message` siempre como texto; `details` siempre como lista.
  /// Formato antiguo de Nest: `message` es una lista → se une con saltos de
  /// línea y la lista pasa a `details` si no venía ninguna.
  static (String?, List<String>) _messageAndDetails(
      Map<String, dynamic>? body) {
    if (body == null) return (null, const []);
    final rawMessage = body['message'];
    final rawDetails = body['details'];

    final details = rawDetails is List
        ? rawDetails.map((e) => e.toString()).toList(growable: false)
        : rawDetails is String && rawDetails.trim().isNotEmpty
            ? [rawDetails]
            : <String>[];

    if (rawMessage is List) {
      final items = rawMessage
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      return (
        items.isEmpty ? null : items.join('\n'),
        details.isEmpty ? items : details,
      );
    }
    if (rawMessage is String && rawMessage.trim().isNotEmpty) {
      return (rawMessage.trim(), details);
    }
    return (null, details);
  }
}
