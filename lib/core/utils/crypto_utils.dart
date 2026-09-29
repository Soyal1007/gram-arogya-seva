/// Aadhaar display helpers.
///
/// Hashing deliberately does **not** live here. SRS §7.10 specifies
/// HMAC-SHA-256 "with a server secret", and a key delivered to the client —
/// including via `--dart-define`, which compiles the value into the APK — is
/// recoverable by anyone who downloads the app. That reduces the HMAC to a
/// plain hash over a 12-digit space, which is exactly the rainbow-table
/// exposure the HMAC was chosen to prevent.
///
/// The plaintext Aadhaar is therefore sent once over TLS to
/// `submitDoctorRegistration`, hashed there with a Cloud Functions secret,
/// and never persisted anywhere. This class only formats what is safe to
/// show on screen.
class CryptoUtils {
  CryptoUtils._();

  /// Extracts the last four digits for display. Empty when the input is not
  /// a well-formed 12-digit Aadhaar number.
  static String aadhaarLastFour(String aadhaarNumber) {
    if (aadhaarNumber.length != 12) return '';
    return aadhaarNumber.substring(8);
  }

  /// Formats an Aadhaar for masked display: `XXXX XXXX 1234`.
  static String maskedAadhaar(String lastFour) {
    return 'XXXX XXXX $lastFour';
  }
}
