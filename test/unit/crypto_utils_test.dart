import 'package:flutter_test/flutter_test.dart';
import 'package:gram_aarogya_seva/core/utils/crypto_utils.dart';

/// Aadhaar *hashing* is intentionally absent from the client and therefore
/// from these tests: it happens in `submitDoctorRegistration` with a server
/// secret, because a key compiled into the APK provides no protection over a
/// 12-digit input space (SRS §7.10).
void main() {
  group('CryptoUtils', () {
    const testAadhaar = '123456789012';

    test('aadhaarLastFour returns the last four digits', () {
      expect(CryptoUtils.aadhaarLastFour(testAadhaar), equals('9012'));
    });

    test('aadhaarLastFour rejects anything that is not 12 digits', () {
      expect(CryptoUtils.aadhaarLastFour('123'), isEmpty);
      expect(CryptoUtils.aadhaarLastFour(''), isEmpty);
      expect(CryptoUtils.aadhaarLastFour('1234567890123'), isEmpty);
    });

    test('maskedAadhaar shows only the last four digits', () {
      final masked = CryptoUtils.maskedAadhaar('9012');
      expect(masked, equals('XXXX XXXX 9012'));
      expect(masked.contains('12345678'), isFalse);
    });
  });
}
