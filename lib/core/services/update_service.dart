import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';

/// Force-update check via Remote Config (SRS §5.1, R-17).
///
/// Villages will not update an app on their own, and there is no support desk
/// to walk them through it. When a fix has to reach every device — a booking
/// bug, a security change — this is the only lever available, so it needs to
/// exist before the pilot rather than after the first incident.
class UpdateService {
  UpdateService([FirebaseRemoteConfig? config])
      : _config = config ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _config;

  static const String _minimumVersionKey = 'minimum_app_version';

  /// Fetches config with a short timeout. Failure is non-fatal: a device that
  /// cannot reach Remote Config is not blocked from using the app.
  Future<void> initialise() async {
    try {
      await _config.setDefaults({_minimumVersionKey: AppConstants.appVersion});
      await _config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Rural connectivity is intermittent; an hour-old value is fine and
        // avoids a fetch on every cold start.
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _config.fetchAndActivate();
    } catch (e) {
      debugPrint('[RemoteConfig] fetch failed: $e');
    }
  }

  /// True when the installed build is older than the configured minimum.
  bool isUpdateRequired({String currentVersion = AppConstants.appVersion}) {
    final minimum = _config.getString(_minimumVersionKey);
    if (minimum.isEmpty) return false;
    return compareVersions(currentVersion, minimum) < 0;
  }

  /// Semantic version comparison. Returns <0, 0 or >0.
  ///
  /// String comparison is wrong here — `"1.10.0" < "1.9.0"` lexically — and
  /// getting it wrong means either locking everyone out or never prompting.
  @visibleForTesting
  static int compareVersions(String a, String b) {
    final left = _parts(a);
    final right = _parts(b);
    for (var i = 0; i < 3; i++) {
      final diff = left[i] - right[i];
      if (diff != 0) return diff < 0 ? -1 : 1;
    }
    return 0;
  }

  static List<int> _parts(String version) {
    // Tolerates "1.2.3+45" build suffixes and short forms like "1.2".
    final core = version.split('+').first.trim();
    final segments = core.split('.');
    return List.generate(
      3,
      (i) => i < segments.length ? (int.tryParse(segments[i]) ?? 0) : 0,
    );
  }
}
