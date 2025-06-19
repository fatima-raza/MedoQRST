import 'package:intl/intl.dart';

/// Formats a [DateTime] object into a readable date string, e.g., "5 Jan 2025"
String formatDate(DateTime? date) {
  if (date == null) return "N/A";
  return DateFormat('d MMM yyyy').format(date);
}

/// Formats a [DateTime] object into "dd-MM-yyyy", e.g., "05-01-2025"
String formatDateCompact(DateTime? date) {
  if (date == null) return "N/A";
  return DateFormat('dd-MM-yyyy').format(date);
}

/// Formats a [DateTime] object into a readable time string, e.g., "10:30 AM"
String formatTime(DateTime? dateTime) {
  if (dateTime == null) return "N/A";
  return DateFormat('hh:mm a').format(dateTime);
}

/// Merges separate date and time strings into a single [DateTime] object
DateTime mergeDateAndTime(String dateStr, String timeStr) {
  final date = DateTime.parse(dateStr);
  final time = DateTime.parse(timeStr);

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
    time.second,
  );
}

/// Returns a formatted date and time map from separate strings
Map<String, String> getFormattedDateTime(String dateStr, String timeStr,
    {bool useCompactDate = false}) {
  final mergedDateTime = mergeDateAndTime(dateStr, timeStr);
  return {
    'date': useCompactDate
        ? formatDateCompact(mergedDateTime)
        : formatDate(mergedDateTime),
    'time': formatTime(mergedDateTime),
  };
}
