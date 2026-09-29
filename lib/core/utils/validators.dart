/// Input validators for government IDs, phone, and other fields.
/// SRS §16 — core/utils/validators.dart
class Validators {
  Validators._();

  /// Indian mobile: exactly 10 digits, starts with 6-9.
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  /// Optional Indian mobile: blank is allowed, but anything entered must be a
  /// real 10-digit number.
  ///
  /// Both the patient's own mobile and their emergency contact are optional
  /// (SRS §7.5 — operator-registered villagers may have no phone at all), but
  /// "optional" was being read as "unvalidated", so `12` saved happily. The
  /// emergency contact is the number somebody rings in an emergency
  /// (PATIENT_MODULE.md P-09).
  static String? validateOptionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return validatePhone(value);
  }

  /// Aadhaar: exactly 12 digits.
  static String? validateAadhaar(String? value) {
    if (value == null || value.isEmpty) return 'Aadhaar number is required';
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) {
      return 'Aadhaar must be exactly 12 digits';
    }
    return null;
  }

  /// NMR ID: alphanumeric, at least 4 characters.
  static String? validateNmrId(String? value) {
    if (value == null || value.trim().isEmpty) return 'NMR ID is required';
    if (value.trim().length < 4) return 'NMR ID must be at least 4 characters';
    return null;
  }

  /// HPR ID: alphanumeric, at least 4 characters.
  static String? validateHprId(String? value) {
    if (value == null || value.trim().isEmpty) return 'HPR ID is required';
    if (value.trim().length < 4) return 'HPR ID must be at least 4 characters';
    return null;
  }

  /// Required text field: non-empty.
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  /// OTP: exactly 6 digits.
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'OTP must be 6 digits';
    return null;
  }
}
