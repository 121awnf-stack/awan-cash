import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:awan_cash/core/format.dart';
import 'package:awan_cash/core/dates.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Number & Currency Formatters', () {
    test('formatRupiah formats values with Rp prefix and thousand separators', () {
      final formatted = formatRupiah(1500000);
      expect(formatted.contains('Rp'), isTrue);
      expect(formatted.contains('1.500.000'), isTrue);

      final zeroFormatted = formatRupiah(0);
      expect(zeroFormatted.contains('Rp'), isTrue);
      expect(zeroFormatted.contains('0'), isTrue);
    });

    test('formatThousands formats integer with dot thousand separators', () {
      expect(formatThousands(0), '0');
      expect(formatThousands(1000), '1.000');
      expect(formatThousands(250000), '250.000');
      expect(formatThousands(15000000), '15.000.000');
    });

    test('formatCompactRupiah formats large numbers in abbreviated form', () {
      final compactMillion = formatCompactRupiah(1500000);
      expect(compactMillion.contains('Rp'), isTrue);
      // In id_ID locale, 1.500.000 is typically compact-formatted with 'jt' (juta)
      expect(compactMillion.toLowerCase().contains('jt'), isTrue);

      final compactThousand = formatCompactRupiah(50000);
      expect(compactThousand.contains('Rp'), isTrue);
      expect(compactThousand.toLowerCase().contains('rb'), isTrue);
    });

    test('parseAmount extracts integer numbers from formatted strings', () {
      expect(parseAmount('1.500.000'), 1500000);
      expect(parseAmount('Rp 250.000'), 250000);
      expect(parseAmount('Rp 10.000.000'), 10000000);
      expect(parseAmount('0'), 0);
      expect(parseAmount(''), 0);
      expect(parseAmount('tidak ada angka'), 0);
      expect(parseAmount('abc123def456'), 123456);
    });

    test('ThousandsInputFormatter formats input numbers dynamically', () {
      final formatter = ThousandsInputFormatter();

      // Empty input
      const emptyOld = TextEditingValue.empty;
      const emptyNew = TextEditingValue(text: '');
      final emptyResult = formatter.formatEditUpdate(emptyOld, emptyNew);
      expect(emptyResult.text, '');

      // Standard digits input
      const oldVal = TextEditingValue(text: '100');
      const newVal = TextEditingValue(text: '1000');
      final result = formatter.formatEditUpdate(oldVal, newVal);
      expect(result.text, '1.000');
      expect(result.selection.baseOffset, 5);

      // Input with punctuation or formatted text
      const formattedOld = TextEditingValue(text: '1.000');
      const formattedNew = TextEditingValue(text: '1.0005');
      final result2 = formatter.formatEditUpdate(formattedOld, formattedNew);
      expect(result2.text, '10.005');

      // Input exceeding maxDigits (15 digits)
      const longInput = TextEditingValue(text: '12345678901234567890');
      final longResult = formatter.formatEditUpdate(emptyOld, longInput);
      // 15 digits formatted
      final parsed = parseAmount(longResult.text);
      expect(parsed.toString().length, 15);
    });
  });

  group('DateRange Calculations', () {
    final start = DateTime(2026, 11, 1);
    final end = DateTime(2026, 12, 1);
    final range = DateRange(start, end);

    test('contains returns true for dates strictly within [start, end)', () {
      expect(range.contains(DateTime(2026, 11, 1, 0, 0, 0)), isTrue);
      expect(range.contains(DateTime(2026, 11, 15, 12, 30)), isTrue);
      expect(range.contains(DateTime(2026, 11, 30, 23, 59, 59)), isTrue);
    });

    test('contains returns false for boundary end or dates outside range', () {
      expect(range.contains(DateTime(2026, 12, 1, 0, 0, 0)), isFalse);
      expect(range.contains(DateTime(2026, 12, 5)), isFalse);
      expect(range.contains(DateTime(2026, 10, 31, 23, 59, 59)), isFalse);
    });

    test('dayCount calculates accurate number of days', () {
      expect(range.dayCount, 30); // November has 30 days

      final singleDayRange = DateRange(DateTime(2026, 11, 19), DateTime(2026, 11, 20));
      expect(singleDayRange.dayCount, 1);

      final weekRange = DateRange(DateTime(2026, 11, 16), DateTime(2026, 11, 23));
      expect(weekRange.dayCount, 7);
    });

    test('lastDay returns the last inclusive calendar day of the range', () {
      final lastDay = range.lastDay;
      expect(lastDay.year, 2026);
      expect(lastDay.month, 11);
      expect(lastDay.day, 30);

      final yearRangeTest = DateRange(DateTime(2026, 1, 1), DateTime(2027, 1, 1));
      expect(yearRangeTest.lastDay, DateTime(2026, 12, 31));
    });
  });

  group('Date Range Helpers & Utilities', () {
    test('dateOnly strips hours, minutes, seconds and milliseconds', () {
      final complexDate = DateTime(2026, 11, 19, 15, 45, 30, 123);
      final stripped = dateOnly(complexDate);

      expect(stripped.year, 2026);
      expect(stripped.month, 11);
      expect(stripped.day, 19);
      expect(stripped.hour, 0);
      expect(stripped.minute, 0);
      expect(stripped.second, 0);
      expect(stripped.millisecond, 0);
    });

    test('dayRange spans exactly from 00:00 to 00:00 next day', () {
      final d = DateTime(2026, 11, 19, 14, 25);
      final range = dayRange(d);

      expect(range.start, DateTime(2026, 11, 19));
      expect(range.end, DateTime(2026, 11, 20));
      expect(range.dayCount, 1);
      expect(range.contains(DateTime(2026, 11, 19, 23, 59)), isTrue);
      expect(range.contains(DateTime(2026, 11, 20, 0, 0)), isFalse);
    });

    test('weekRange starts on Monday and ends on following Monday', () {
      // 2026-11-19 is Thursday (weekday 4)
      final d = DateTime(2026, 11, 19);
      final range = weekRange(d);

      expect(range.start, DateTime(2026, 11, 16)); // Monday
      expect(range.start.weekday, DateTime.monday);
      expect(range.end, DateTime(2026, 11, 23)); // Next Monday
      expect(range.dayCount, 7);
      expect(range.lastDay, DateTime(2026, 11, 22)); // Sunday
      expect(range.lastDay.weekday, DateTime.sunday);
    });

    test('monthRange spans from 1st of month to 1st of next month', () {
      final d = DateTime(2026, 11, 19);
      final range = monthRange(d);

      expect(range.start, DateTime(2026, 11, 1));
      expect(range.end, DateTime(2026, 12, 1));
      expect(range.dayCount, 30);
      expect(range.lastDay, DateTime(2026, 11, 30));
    });

    test('monthRange correctly rolls over to next year in December', () {
      final dec = DateTime(2026, 12, 15);
      final range = monthRange(dec);

      expect(range.start, DateTime(2026, 12, 1));
      expect(range.end, DateTime(2027, 1, 1));
      expect(range.dayCount, 31);
      expect(range.lastDay, DateTime(2026, 12, 31));
    });

    test('yearRange spans from Jan 1st to Jan 1st of next year', () {
      final d = DateTime(2026, 7, 15);
      final range = yearRange(d);

      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, DateTime(2027, 1, 1));
      expect(range.dayCount, 365);
      expect(range.lastDay, DateTime(2026, 12, 31));
    });

    test('isSameDay accurately compares dates regardless of time', () {
      final a = DateTime(2026, 11, 19, 8, 30);
      final b = DateTime(2026, 11, 19, 23, 15);
      final c = DateTime(2026, 11, 20, 8, 30);

      expect(isSameDay(a, b), isTrue);
      expect(isSameDay(a, c), isFalse);
    });
  });

  group('Indonesian Date & Time Formatters', () {
    final sampleDate = DateTime(2026, 11, 19, 14, 5, 30);

    test('fmtIsoDate produces yyyy-MM-dd format', () {
      expect(fmtIsoDate(sampleDate), '2026-11-19');
    });

    test('fmtFileStamp produces yyyyMMdd_HHmm format', () {
      expect(fmtFileStamp(sampleDate), '20261119_1405');
    });

    test('fmtTime produces HH:mm format', () {
      expect(fmtTime(sampleDate), '14:05');
    });

    test('fmtDate produces d MMM yyyy Indonesian format', () {
      final result = fmtDate(sampleDate);
      expect(result, contains('19'));
      expect(result, contains('Nov'));
      expect(result, contains('2026'));
    });

    test('fmtDateShort produces d MMM format', () {
      final result = fmtDateShort(sampleDate);
      expect(result, contains('19'));
      expect(result, contains('Nov'));
    });

    test('fmtMonthYear produces full month name and year', () {
      final result = fmtMonthYear(sampleDate);
      expect(result.toLowerCase(), contains('november'));
      expect(result, contains('2026'));
    });

    test('fmtDayHeader produces day name, date, month, and year', () {
      final result = fmtDayHeader(sampleDate);
      // 2026-11-19 is Kamis
      expect(result.toLowerCase(), contains('kamis'));
      expect(result, contains('19'));
      expect(result, contains('Nov'));
      expect(result, contains('2026'));
    });

    test('fmtWeekdayShort and fmtMonthShort format abbreviations', () {
      final weekday = fmtWeekdayShort(sampleDate);
      expect(weekday.isNotEmpty, isTrue);

      final month = fmtMonthShort(sampleDate);
      expect(month.isNotEmpty, isTrue);
    });
  });
}
