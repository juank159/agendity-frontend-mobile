/// Códigos de error del contrato HTTP (ARQUITECTURA.md §3).
///
/// Son los mismos que `backend/src/common/constants/error-codes.ts`.
/// Para añadir uno: §3, el backend y el `ErrorMapper`, en la misma tarea.
abstract final class ApiErrorCode {
  static const validationError = 'VALIDATION_ERROR';
  static const badRequest = 'BAD_REQUEST';
  static const unauthorized = 'UNAUTHORIZED';
  static const forbidden = 'FORBIDDEN';
  static const accountInactive = 'ACCOUNT_INACTIVE';
  static const notFound = 'NOT_FOUND';
  static const conflict = 'CONFLICT';
  static const slotUnavailable = 'SLOT_UNAVAILABLE';
  static const professionalInactive = 'PROFESSIONAL_INACTIVE';
  static const invalidStateTransition = 'INVALID_STATE_TRANSITION';
  static const appointmentPaid = 'APPOINTMENT_PAID';
  static const paymentAlreadyExists = 'PAYMENT_ALREADY_EXISTS';
  static const emailNotVerified = 'EMAIL_NOT_VERIFIED';
  static const ownerNotDeletable = 'OWNER_NOT_DELETABLE';
  static const categoryHasServices = 'CATEGORY_HAS_SERVICES';
  static const appointmentInPast = 'APPOINTMENT_IN_PAST';
  static const duplicateEmail = 'DUPLICATE_EMAIL';
  static const duplicatePhone = 'DUPLICATE_PHONE';
  static const trialLimitReached = 'TRIAL_LIMIT_REACHED';
  static const subscriptionInactive = 'SUBSCRIPTION_INACTIVE';
  static const tooManyRequests = 'TOO_MANY_REQUESTS';
  static const internalError = 'INTERNAL_ERROR';
}
