import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:login_signup/core/errors/failures.dart';

/// Traduce errores de red y respuestas de error a `Failure` (ARQUITECTURA.md §3).
///
/// Decide por `code`. Si la respuesta no trae `code` (formato antiguo o cuerpo
/// que no es JSON) recurre al HTTP. Nunca compara el texto de `message`.
typedef _Build = Failure Function(_Parts parts);

/// Lo que se lee de una respuesta de error. `info` = `details` cuando llega
/// como objeto (13.04).
typedef _Parts = ({
  String? message,
  String? code,
  int? statusCode,
  List<String> details,
  Map<String, Object?> info,
});

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
    final (message, details, info) = _messageAndDetails(body);
    final parts = (
      message: message,
      code: code,
      statusCode: statusCode,
      details: details,
      info: info,
    );

    final byCode = code == null ? null : _byCode[code];
    if (byCode != null) return byCode(parts);

    // Sin `code` reconocido: decide por HTTP. Conserva un `code` desconocido
    // para que la feature pueda mirarlo.
    final byStatus = _byStatus[statusCode];
    if (byStatus != null) return byStatus(parts);

    // 5xx y cualquier otro. Sin `code`, el texto de un 5xx no se muestra
    // (puede ser HTML de un proxy o un mensaje interno).
    final hideMessage =
        code == null && (statusCode == null || statusCode >= 500);
    return ServerFailure(
        message: hideMessage ? null : message,
        code: code,
        statusCode: statusCode,
        details: details);
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
    ApiErrorCode.serviceNotOfferedByProfessional: _conflict,
    ApiErrorCode.appointmentNotStarted: _conflict,
    ApiErrorCode.serviceInactive: _conflict,
    ApiErrorCode.outsideBusinessHours: _conflict,
    ApiErrorCode.bookingLimitReached: _conflict,
    ApiErrorCode.onlineBookingUnavailable: _conflict,
    ApiErrorCode.emailDeliveryFailed: _emailDelivery,
    ApiErrorCode.invalidVerificationCode: _invalidVerificationCode,
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

  static Failure _validation(_Parts p) => ValidationFailure(
      message: p.message,
      code: p.code,
      statusCode: p.statusCode,
      details: p.details);
  static Failure _invalidVerificationCode(_Parts p) =>
      InvalidVerificationCodeFailure(
          message: p.message, statusCode: p.statusCode, details: p.details);
  static Failure _unauthorized(_Parts p) => UnauthorizedFailure(
      message: p.message,
      code: p.code,
      statusCode: p.statusCode,
      details: p.details);
  static Failure _forbidden(_Parts p) => ForbiddenFailure(
      message: p.message,
      code: p.code,
      statusCode: p.statusCode,
      details: p.details);
  static Failure _notFound(_Parts p) => NotFoundFailure(
      message: p.message,
      code: p.code,
      statusCode: p.statusCode,
      details: p.details);

  /// Con `info`: los conflictos de negocio traen su motivo (13.04).
  static Failure _conflict(_Parts p) => ConflictFailure(
      message: p.message,
      code: p.code,
      statusCode: p.statusCode,
      details: p.details,
      info: p.info);
  static Failure _duplicateEmail(_Parts p) => DuplicateEmailFailure(
      message: p.message, statusCode: p.statusCode, details: p.details);
  static Failure _duplicatePhone(_Parts p) => DuplicatePhoneFailure(
      message: p.message, statusCode: p.statusCode, details: p.details);
  static Failure _paymentRequired(_Parts p) => PaymentRequiredFailure(
      message: p.message,
      code: p.code,
      statusCode: p.statusCode,
      details: p.details);
  static Failure _tooManyRequests(_Parts p) => TooManyRequestsFailure(
      message: p.message,
      code: p.code,
      statusCode: p.statusCode,
      details: p.details);
  static Failure _emailDelivery(_Parts p) => EmailDeliveryFailure(
      message: p.message, statusCode: p.statusCode, details: p.details);
  static Failure _server(_Parts p) => ServerFailure(
      message: p.message,
      code: p.code,
      statusCode: p.statusCode,
      details: p.details);

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
  /// `details` como objeto (13.04, `{reason, hours…}`) → tercer valor
  /// (`Failure.info`), con la lista vacía.
  static (String?, List<String>, Map<String, Object?>) _messageAndDetails(
      Map<String, dynamic>? body) {
    if (body == null) return (null, const [], const {});
    final rawMessage = body['message'];
    final rawDetails = body['details'];
    final info = rawDetails is Map
        ? Map<String, Object?>.unmodifiable(
            rawDetails.map((key, value) => MapEntry(key.toString(), value)))
        : const <String, Object?>{};

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
        info,
      );
    }
    if (rawMessage is String && rawMessage.trim().isNotEmpty) {
      return (rawMessage.trim(), details, info);
    }
    return (null, details, info);
  }
}
