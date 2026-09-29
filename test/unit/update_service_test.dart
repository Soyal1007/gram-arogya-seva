import 'package:flutter_test/flutter_test.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/services/notification_service.dart';
import 'package:gram_aarogya_seva/core/services/update_service.dart';

void main() {
  group('UpdateService.compareVersions', () {
    // Getting this wrong has exactly two outcomes, both bad: nobody is ever
    // prompted to update, or everybody is locked out of a working app. Naive
    // string comparison produces the second — "1.10.0" sorts below "1.9.0".
    test('orders by numeric segment, not lexically', () {
      expect(UpdateService.compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(UpdateService.compareVersions('1.9.0', '1.10.0'), lessThan(0));
      expect(UpdateService.compareVersions('2.0.0', '1.99.99'), greaterThan(0));
    });

    test('treats identical versions as equal', () {
      expect(UpdateService.compareVersions('1.2.3', '1.2.3'), equals(0));
    });

    test('compares each segment in order', () {
      expect(UpdateService.compareVersions('1.2.4', '1.2.3'), greaterThan(0));
      expect(UpdateService.compareVersions('1.3.0', '1.2.9'), greaterThan(0));
      expect(UpdateService.compareVersions('0.9.9', '1.0.0'), lessThan(0));
    });

    test('tolerates build suffixes and short forms', () {
      // pubspec versions carry "+buildNumber"; Remote Config values may not.
      expect(UpdateService.compareVersions('1.2.3+45', '1.2.3'), equals(0));
      expect(UpdateService.compareVersions('1.2', '1.2.0'), equals(0));
      expect(UpdateService.compareVersions('1.3', '1.2.9'), greaterThan(0));
    });

    test('treats unparseable segments as zero rather than throwing', () {
      // A malformed Remote Config value must not crash every client on start.
      expect(UpdateService.compareVersions('1.x.3', '1.0.3'), equals(0));
      expect(UpdateService.compareVersions('', '0.0.0'), equals(0));
    });

    test('the shipped version is not below itself', () {
      expect(
        UpdateService.compareVersions(
            AppConstants.appVersion, AppConstants.appVersion),
        equals(0),
      );
    });
  });

  group('NotificationService.routeForType', () {
    test('routes doctor lifecycle pushes to the awaiting screen', () {
      expect(
        NotificationService.routeForType('doctor_approved'),
        equals(AppConstants.routeDoctorAwaiting),
      );
      expect(
        NotificationService.routeForType('doctor_rejected'),
        equals(AppConstants.routeDoctorAwaiting),
      );
    });

    test('routes appointment pushes to the inbox', () {
      expect(
        NotificationService.routeForType('appointment_accepted'),
        equals(AppConstants.routeNotifications),
      );
      expect(
        NotificationService.routeForType('appointment_reminder_24h'),
        equals(AppConstants.routeNotifications),
      );
    });

    test('ignores a push with no type rather than navigating blindly', () {
      expect(NotificationService.routeForType(null), isNull);
    });
  });
}
