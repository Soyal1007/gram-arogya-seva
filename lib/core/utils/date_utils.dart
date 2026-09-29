import 'package:intl/intl.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';

/// Date, slot and cancellation-window helpers.
///
/// Two rules govern this file:
///
/// 1. **Every formatter is pinned to `en_US`.** These strings are a storage
///    and parsing format, not user-facing copy. An unpinned `DateFormat`
///    binds whatever `Intl.defaultLocale` happens to be at first use, which
///    in a trilingual app makes parsing non-deterministic.
/// 2. **Slot times are stored as 24-hour `HH:mm`** and only rendered as
///    `9:00 AM`. Earlier builds wrote `HH:mm` but parsed with `hh:mm a`,
///    which threw on every slot and silently disabled appointment
///    cancellation app-wide (TECHNICAL_ASSESSMENT.md §11.4). The parser below
///    accepts both forms so documents written by those builds still work.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _schemaDate = DateFormat('yyyy-MM-dd', 'en_US');
  static final DateFormat _displayDate = DateFormat('dd MMM yyyy', 'en_US');
  static final DateFormat _displayDayMonth = DateFormat('EEE, dd MMM', 'en_US');

  /// Formats a [DateTime] as the `YYYY-MM-DD` schema date (SRS §7.7).
  static String toSchemaDate(DateTime date) => _schemaDate.format(date);

  /// Parses a `YYYY-MM-DD` schema date.
  static DateTime parseSchemaDate(String date) => _schemaDate.parse(date);

  /// Formats a schema date for display: `23 Jul 2026`.
  static String toDisplayDate(String schemaDate) {
    final parsed = DateTime.tryParse(schemaDate);
    if (parsed == null) return schemaDate;
    return _displayDate.format(parsed);
  }

  /// Formats a schema date as `Thu, 23 Jul` for compact list rows.
  static String toShortDisplayDate(String schemaDate) {
    final parsed = DateTime.tryParse(schemaDate);
    if (parsed == null) return schemaDate;
    return _displayDayMonth.format(parsed);
  }

  /// Today as a schema date.
  static String todaySchemaDate() => toSchemaDate(DateTime.now());

  /// Builds the availability document id, `{doctorId}_{YYYY-MM-DD}`.
  static String availabilityDocId(String doctorId, DateTime date) {
    return '${doctorId}_${toSchemaDate(date)}';
  }

  // ── Slot times ────────────────────────────────────────────────────────

  /// Parses a slot time into minutes past midnight, or null if unparseable.
  ///
  /// Accepts the canonical `HH:mm` and the legacy `hh:mm AM/PM`.
  static int? parseSlotMinutes(String timeSlot) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$')
        .firstMatch(timeSlot.trim().toUpperCase());
    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = match.group(3);

    if (meridiem != null) {
      if (hour < 1 || hour > 12) return null;
      if (meridiem == 'AM') {
        hour = hour == 12 ? 0 : hour;
      } else {
        hour = hour == 12 ? 12 : hour + 12;
      }
    }

    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }

  /// Renders a stored slot time for the user: `09:00` → `9:00 AM`.
  static String formatSlotForDisplay(String timeSlot) {
    final minutes = parseSlotMinutes(timeSlot);
    if (minutes == null) return timeSlot;
    final hour24 = minutes ~/ 60;
    final minute = minutes % 60;
    final suffix = hour24 < 12 ? 'AM' : 'PM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
  }

  /// Combines a schema date and a slot time into a local [DateTime].
  /// Returns null when either part is unparseable.
  static DateTime? slotDateTime(String date, String timeSlot) {
    final day = DateTime.tryParse(date);
    final minutes = parseSlotMinutes(timeSlot);
    if (day == null || minutes == null) return null;
    return DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
  }

  // ── Cancellation window ───────────────────────────────────────────────

  /// Whether the patient may still cancel.
  ///
  /// [slotStartAt] is the server-computed instant when available and is
  /// preferred; the date/slot strings are the fallback for documents written
  /// before that field existed.
  ///
  /// The client check is a courtesy so the button can be hidden with an
  /// explanation — `cancelAppointment` enforces the same rule server-side,
  /// which is what SRS P-FLOW-03 actually requires.
  static bool canCancel({
    required String date,
    required String timeSlot,
    DateTime? slotStartAt,
    DateTime? now,
  }) {
    final start = slotStartAt ?? slotDateTime(date, timeSlot);
    if (start == null) return false; // unparseable → let the server decide
    final cutoff =
        start.subtract(const Duration(hours: AppConstants.cancelWindowHours));
    return (now ?? DateTime.now()).isBefore(cutoff);
  }

  /// True when the appointment time has passed — gates the doctor's
  /// "complete" / "no-show" actions (SRS §D-FLOW-03).
  static bool hasSlotPassed({
    required String date,
    required String timeSlot,
    DateTime? slotStartAt,
    DateTime? now,
  }) {
    final start = slotStartAt ?? slotDateTime(date, timeSlot);
    if (start == null) return false;
    return (now ?? DateTime.now()).isAfter(start);
  }

  /// Whether a date is bookable: today through +30 days (SRS §5.1).
  static bool isWithinBookingRange(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final maxDate =
        today.add(const Duration(days: AppConstants.maxBookingDaysAhead));
    return !target.isBefore(today) && !target.isAfter(maxDate);
  }
}
