/// Typed application errors.
///
/// SRS §12.1 requires that every failure reaches the user as a friendly,
/// localised message — never a raw Firebase code. That is only achievable if
/// the service layer converts transport errors into a closed set of cases the
/// UI can exhaustively handle. Matching on `e.toString().contains(...)`, which
/// this replaces, breaks the moment a message is reworded or translated.
///
/// Every case carries the localisation key for its user-facing message, so
/// screens render `tr(error.messageKey)` and never compose copy themselves.
sealed class AppException implements Exception {
  const AppException(this.messageKey, [this.detail]);

  /// Key into `assets/l10n/*.json`.
  final String messageKey;

  /// Optional technical detail — for logs and Crashlytics, never for the UI.
  final String? detail;

  @override
  String toString() => '$runtimeType($messageKey)${detail == null ? '' : ': $detail'}';
}

/// The chosen slot was taken between rendering and confirming.
/// SRS §12.2: "This slot was just booked. Pick another." + refresh.
class SlotAlreadyBookedException extends AppException {
  const SlotAlreadyBookedException([String? detail])
      : super('slot_already_booked', detail);
}

/// Cancellation attempted inside the 2-hour window (SRS P-FLOW-03).
class CancelWindowClosedException extends AppException {
  const CancelWindowClosedException([String? detail])
      : super('cancel_too_late', detail);
}

/// The caller is not allowed to perform this action.
class PermissionDeniedException extends AppException {
  const PermissionDeniedException([String? detail])
      : super('error_permission_denied', detail);
}

/// The request never reached the server.
class NetworkUnavailableException extends AppException {
  const NetworkUnavailableException([String? detail])
      : super('error_no_network', detail);
}

/// A dependency (ABDM, Cloud Functions) is temporarily unavailable.
class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException([String? detail])
      : super('error_service_unavailable', detail);
}

/// The server rejected the request state — e.g. the doctor has no availability
/// on that date, or the appointment can no longer change status.
class InvalidOperationException extends AppException {
  const InvalidOperationException(super.messageKey, [super.detail]);
}

/// Anything not otherwise classified.
class UnexpectedException extends AppException {
  const UnexpectedException([String? detail]) : super('error_generic', detail);
}
