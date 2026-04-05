import 'package:flutter/material.dart';

/// Utility for formatting [TimeOfDay] values into display strings.
///
/// Example:
/// ```dart
/// final time = TimeOfDay(hour: 14, minute: 30);
/// RjTimeUtils.format(time); // '2:30 PM'
/// RjTimeUtils.format(time, format: 'HH:mm'); // '14:30'
/// ```
class RjTimeUtils {
  RjTimeUtils._();

  /// Formats a [TimeOfDay] into a human-readable string.
  ///
  /// If [format] is provided, uses custom format tokens:
  /// - `HH` — 24-hour, zero-padded (e.g. `09`, `14`)
  /// - `H`  — 24-hour, no padding (e.g. `9`, `14`)
  /// - `hh` — 12-hour, zero-padded (e.g. `02`, `11`)
  /// - `h`  — 12-hour, no padding (e.g. `2`, `11`)
  /// - `mm` — minutes, zero-padded (e.g. `05`, `30`)
  /// - `a`  or `A` — AM/PM period
  ///
  /// If [format] is null, defaults to `h:mm a` (e.g. `2:30 PM`).
  static String format(TimeOfDay time, {String? format}) {
    if (format != null) {
      return _applyFormat(time, format);
    }
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  static String _applyFormat(TimeOfDay t, String format) {
    final hour24 = t.hour;
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';

    return format
        .replaceAll('HH', hour24.toString().padLeft(2, '0'))
        .replaceAll('H', hour24.toString())
        .replaceAll('hh', hour12.toString().padLeft(2, '0'))
        .replaceAll('h', hour12.toString())
        .replaceAll('mm', minute)
        .replaceAll('a', period)
        .replaceAll('A', period);
  }

  /// Formats a [DateTime] into a date string.
  ///
  /// Default format: `dd/MM/yyyy`.
  /// Supports tokens: `yyyy`, `yy`, `MM`, `M`, `dd`, `d`.
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    return format
        .replaceAll('yyyy', date.year.toString())
        .replaceAll('yy', date.year.toString().substring(2))
        .replaceAll('MM', date.month.toString().padLeft(2, '0'))
        .replaceAll('M', date.month.toString())
        .replaceAll('dd', date.day.toString().padLeft(2, '0'))
        .replaceAll('d', date.day.toString());
  }
}
