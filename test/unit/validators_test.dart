import 'package:flutter_test/flutter_test.dart';
import 'package:gram_aarogya_seva/core/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('validatePhone validates 10-digit Indian numbers', () {
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('6123456789'), isNull);
      expect(Validators.validatePhone('123'), isNotNull);
      expect(Validators.validatePhone(''), isNotNull);
      expect(Validators.validatePhone(null), isNotNull);
      expect(Validators.validatePhone('abcdefghij'), isNotNull);
    });

    test('validateAadhaar validates 12-digit Aadhaar numbers', () {
      expect(Validators.validateAadhaar('123456789012'), isNull);
      expect(Validators.validateAadhaar('12345678901'), isNotNull);
      expect(Validators.validateAadhaar('1234567890123'), isNotNull);
      expect(Validators.validateAadhaar(null), isNotNull);
    });

    test('validateOtp validates 6-digit OTP', () {
      expect(Validators.validateOtp('123456'), isNull);
      expect(Validators.validateOtp('12345'), isNotNull);
      expect(Validators.validateOtp('abcdef'), isNotNull);
    });

    test('validateRequired validates mandatory fields', () {
      expect(Validators.validateRequired('John Doe', 'Name'), isNull);
      expect(Validators.validateRequired('', 'Name'), isNotNull);
      expect(Validators.validateRequired(null, 'Name'), isNotNull);
    });

    test('validateNmrId validates NMR ID format', () {
      expect(Validators.validateNmrId('NMR-123456'), isNull);
      expect(Validators.validateNmrId(''), isNotNull);
    });

    test('validateHprId validates HPR ID format', () {
      expect(Validators.validateHprId('HPR-123456'), isNull);
      expect(Validators.validateHprId(''), isNotNull);
    });
  });
}
