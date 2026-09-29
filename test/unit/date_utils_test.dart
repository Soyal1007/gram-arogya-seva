import 'package:flutter_test/flutter_test.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils — schema dates', () {
    test('toSchemaDate formats as YYYY-MM-DD', () {
      expect(AppDateUtils.toSchemaDate(DateTime(2026, 7, 23)),
          equals('2026-07-23'));
    });

    test('parseSchemaDate round-trips', () {
      expect(AppDateUtils.parseSchemaDate('2026-07-23'),
          equals(DateTime(2026, 7, 23)));
    });

    test('toDisplayDate formats as DD MMM YYYY', () {
      expect(AppDateUtils.toDisplayDate('2026-07-23'), equals('23 Jul 2026'));
    });

    test('toDisplayDate returns the input unchanged when unparseable', () {
      expect(AppDateUtils.toDisplayDate('not-a-date'), equals('not-a-date'));
    });

    test('availabilityDocId builds {doctorId}_{date}', () {
      expect(
        AppDateUtils.availabilityDocId('doc_123', DateTime(2026, 7, 23)),
        equals('doc_123_2026-07-23'),
      );
    });
  });

  group('AppDateUtils — slot parsing', () {
    // The regression that motivated this suite: availability was written as
    // 24-hour "09:00" but parsed as "hh:mm a", which threw on every slot and
    // disabled cancellation app-wide (TECHNICAL_ASSESSMENT.md §11.4).
    test('parses the canonical 24-hour form', () {
      expect(AppDateUtils.parseSlotMinutes('09:00'), equals(540));
      expect(AppDateUtils.parseSlotMinutes('14:30'), equals(870));
      expect(AppDateUtils.parseSlotMinutes('00:00'), equals(0));
      expect(AppDateUtils.parseSlotMinutes('23:59'), equals(1439));
    });

    test('parses the legacy 12-hour form written by earlier builds', () {
      expect(AppDateUtils.parseSlotMinutes('09:00 AM'), equals(540));
      expect(AppDateUtils.parseSlotMinutes('2:30 PM'), equals(870));
      expect(AppDateUtils.parseSlotMinutes('12:00 AM'), equals(0));
      expect(AppDateUtils.parseSlotMinutes('12:00 PM'), equals(720));
      expect(AppDateUtils.parseSlotMinutes('12:30 pm'), equals(750));
    });

    test('returns null rather than throwing on malformed input', () {
      expect(AppDateUtils.parseSlotMinutes(''), isNull);
      expect(AppDateUtils.parseSlotMinutes('9'), isNull);
      expect(AppDateUtils.parseSlotMinutes('25:00'), isNull);
      expect(AppDateUtils.parseSlotMinutes('09:75'), isNull);
      expect(AppDateUtils.parseSlotMinutes('13:00 PM'), isNull);
      expect(AppDateUtils.parseSlotMinutes('morning'), isNull);
    });

    test('formatSlotForDisplay renders 12-hour time', () {
      expect(AppDateUtils.formatSlotForDisplay('09:00'), equals('9:00 AM'));
      expect(AppDateUtils.formatSlotForDisplay('14:30'), equals('2:30 PM'));
      expect(AppDateUtils.formatSlotForDisplay('00:15'), equals('12:15 AM'));
      expect(AppDateUtils.formatSlotForDisplay('12:00'), equals('12:00 PM'));
    });

    test('formatSlotForDisplay passes through what it cannot parse', () {
      expect(AppDateUtils.formatSlotForDisplay('later'), equals('later'));
    });

    test('slotDateTime combines date and slot', () {
      expect(
        AppDateUtils.slotDateTime('2026-07-23', '14:30'),
        equals(DateTime(2026, 7, 23, 14, 30)),
      );
      expect(AppDateUtils.slotDateTime('2026-07-23', 'nope'), isNull);
    });
  });

  group('AppDateUtils — cancellation window (SRS P-FLOW-03)', () {
    test('allows cancellation more than 2 hours ahead', () {
      expect(
        AppDateUtils.canCancel(
          date: '2026-07-23',
          timeSlot: '14:00',
          now: DateTime(2026, 7, 23, 11, 0),
        ),
        isTrue,
      );
    });

    test('refuses cancellation inside the 2-hour window', () {
      expect(
        AppDateUtils.canCancel(
          date: '2026-07-23',
          timeSlot: '14:00',
          now: DateTime(2026, 7, 23, 12, 30),
        ),
        isFalse,
      );
    });

    test('treats the boundary itself as too late', () {
      expect(
        AppDateUtils.canCancel(
          date: '2026-07-23',
          timeSlot: '14:00',
          now: DateTime(2026, 7, 23, 12, 0),
        ),
        isFalse,
      );
    });

    test('refuses cancellation after the appointment has passed', () {
      expect(
        AppDateUtils.canCancel(
          date: '2026-07-23',
          timeSlot: '14:00',
          now: DateTime(2026, 7, 23, 15, 0),
        ),
        isFalse,
      );
    });

    test('prefers the server-computed slotStartAt over the strings', () {
      expect(
        AppDateUtils.canCancel(
          date: 'unparseable',
          timeSlot: 'unparseable',
          slotStartAt: DateTime(2026, 7, 23, 14, 0),
          now: DateTime(2026, 7, 23, 9, 0),
        ),
        isTrue,
      );
    });

    test('fails closed when the time cannot be determined', () {
      // Better to show nothing and let the server decide than to offer a
      // cancel button whose write will be rejected.
      expect(AppDateUtils.canCancel(date: 'nope', timeSlot: 'nope'), isFalse);
    });
  });

  group('AppDateUtils — outcome gating (SRS D-FLOW-03)', () {
    test('hasSlotPassed is false before the appointment', () {
      expect(
        AppDateUtils.hasSlotPassed(
          date: '2026-07-23',
          timeSlot: '14:00',
          now: DateTime(2026, 7, 23, 13, 59),
        ),
        isFalse,
      );
    });

    test('hasSlotPassed is true after the appointment', () {
      expect(
        AppDateUtils.hasSlotPassed(
          date: '2026-07-23',
          timeSlot: '14:00',
          now: DateTime(2026, 7, 23, 14, 1),
        ),
        isTrue,
      );
    });
  });

  group('AppDateUtils — booking range', () {
    test('accepts today and up to 30 days ahead', () {
      final today = DateTime.now();
      expect(AppDateUtils.isWithinBookingRange(today), isTrue);
      expect(
        AppDateUtils.isWithinBookingRange(today.add(const Duration(days: 7))),
        isTrue,
      );
    });

    test('rejects the past and beyond 30 days', () {
      final today = DateTime.now();
      expect(
        AppDateUtils.isWithinBookingRange(
            today.subtract(const Duration(days: 1))),
        isFalse,
      );
      expect(
        AppDateUtils.isWithinBookingRange(today.add(const Duration(days: 60))),
        isFalse,
      );
    });
  });
}
