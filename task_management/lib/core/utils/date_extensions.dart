import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  /// Format: "01 Jul 2026"
  String get displayDate => DateFormat('dd MMM yyyy', 'en_US').format(this);

  /// Format: "01/07/2026"
  String get shortDate => DateFormat('dd/MM/yyyy').format(this);

  /// Format: "14:30"
  String get timeOnly => DateFormat('HH:mm').format(this);

  /// Format: "01 Jul 2026, 14:30"
  String get displayDateTime =>
      DateFormat('dd MMM yyyy, HH:mm', 'en_US').format(this);

  /// Relative time: "2 hours ago", "just now", "3 days ago", etc.
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// True if deadline is overdue.
  bool get isOverdue => isBefore(DateTime.now());

  /// True if deadline is within the next 24 hours.
  bool get isDueSoon {
    final now = DateTime.now();
    return isAfter(now) && difference(now).inHours <= 24;
  }
}

extension NullableDateTimeExtensions on DateTime? {
  /// Returns displayDate or a fallback string.
  String displayOrDefault([String fallback = 'No deadline']) =>
      this?.displayDate ?? fallback;
}
