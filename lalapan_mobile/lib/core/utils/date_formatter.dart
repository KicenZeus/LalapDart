import 'package:intl/intl.dart';

class DateFormatter {
  /// Format tanggal standar: 22 Oktober 2026
  static String formatFullDate(dynamic date) {
    if (date == null) return '-';
    try {
      final parsed = date is DateTime ? date : DateTime.parse(date.toString());
      return DateFormat('d MMMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      try {
        final parsed = DateTime.parse(date.toString());
        return DateFormat('d MMM yyyy').format(parsed);
      } catch (e) {
        return date.toString();
      }
    }
  }

  /// Format tanggal dan waktu: 22 Okt 2026, 06:45
  static String formatDateTime(dynamic date) {
    if (date == null) return '-';
    try {
      final parsed = date is DateTime ? date : DateTime.parse(date.toString());
      return DateFormat('d MMM yyyy, HH:mm').format(parsed);
    } catch (_) {
      return date.toString();
    }
  }
}
