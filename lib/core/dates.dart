import 'package:intl/intl.dart';

/// Rentang tanggal: [start] inklusif, [end] eksklusif.
class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  int get dayCount => (end.difference(start).inHours / 24).round();

  /// Hari terakhir yang masih termasuk dalam rentang.
  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateRange dayRange(DateTime d) =>
    DateRange(dateOnly(d), DateTime(d.year, d.month, d.day + 1));

/// Minggu dimulai hari Senin.
DateRange weekRange(DateTime d) {
  final start = DateTime(d.year, d.month, d.day - (d.weekday - 1));
  return DateRange(start, DateTime(start.year, start.month, start.day + 7));
}

DateRange monthRange(DateTime d) =>
    DateRange(DateTime(d.year, d.month), DateTime(d.year, d.month + 1));

DateRange yearRange(DateTime d) =>
    DateRange(DateTime(d.year), DateTime(d.year + 1));

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');
final DateFormat _dayHeader = DateFormat('EEEE, d MMM yyyy', 'id_ID');
final DateFormat _date = DateFormat('d MMM yyyy', 'id_ID');
final DateFormat _dateShort = DateFormat('d MMM', 'id_ID');
final DateFormat _time = DateFormat('HH:mm', 'id_ID');
final DateFormat _weekdayShort = DateFormat('E', 'id_ID');
final DateFormat _monthShort = DateFormat('MMM', 'id_ID');
final DateFormat _iso = DateFormat('yyyy-MM-dd');
final DateFormat _fileStamp = DateFormat('yyyyMMdd_HHmm');

String fmtMonthYear(DateTime d) => _monthYear.format(d);
String fmtDayHeader(DateTime d) => _dayHeader.format(d);
String fmtDate(DateTime d) => _date.format(d);
String fmtDateShort(DateTime d) => _dateShort.format(d);
String fmtTime(DateTime d) => _time.format(d);
String fmtWeekdayShort(DateTime d) => _weekdayShort.format(d);
String fmtMonthShort(DateTime d) => _monthShort.format(d);
String fmtIsoDate(DateTime d) => _iso.format(d);
String fmtFileStamp(DateTime d) => _fileStamp.format(d);
