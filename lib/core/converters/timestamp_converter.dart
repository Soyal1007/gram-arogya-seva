import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralised Firestore Timestamp ↔ DateTime converters.
///
/// This is the ONLY file outside of [FirestoreService] that imports
/// `cloud_firestore`. Model files use these converters via `@JsonKey`
/// annotations without needing to import Firestore directly.
///
/// SRS §6.2 architectural rule: minimal Firestore SDK surface area.
class TimestampConverter {
  TimestampConverter._();

  /// Converts a Firestore [Timestamp] or ISO-8601 string to [DateTime].
  /// Returns null for null or unrecognised values.
  static DateTime? fromJson(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Converts a [DateTime] to a Firestore [Timestamp] for serialisation.
  /// Returns null for null input.
  static dynamic toJson(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }
}
