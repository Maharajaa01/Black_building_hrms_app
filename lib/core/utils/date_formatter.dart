import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _frappeDate = DateFormat('yyyy-MM-dd');
  static final _frappeDateTime = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final _displayDate = DateFormat('d MMM yyyy');
  static final _displayDateLong = DateFormat('EEEE, d MMM yyyy');
  static final _displayTime = DateFormat('hh:mm a');
  static final _displayMonth = DateFormat('MMMM yyyy');

  static String toFrappeDate(DateTime d) => _frappeDate.format(d);
  static String toFrappeDateTime(DateTime d) => _frappeDateTime.format(d);
  static String displayDate(DateTime d) => _displayDate.format(d);
  static String displayDateLong(DateTime d) => _displayDateLong.format(d);
  static String displayTime(DateTime d) => _displayTime.format(d);
  static String displayMonth(DateTime d) => _displayMonth.format(d);

  static DateTime? parseFrappeDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _displayDate.format(d);
  }

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}
