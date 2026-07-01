import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  /// Format: "01 Jul 2026"
  String get displayDate => DateFormat('dd MMM yyyy', 'vi').format(this);

  /// Format: "01/07/2026"
  String get shortDate => DateFormat('dd/MM/yyyy').format(this);

  /// Format: "14:30"
  String get timeOnly => DateFormat('HH:mm').format(this);

  /// Format: "01 Jul 2026, 14:30"
  String get displayDateTime =>
      DateFormat('dd MMM yyyy, HH:mm', 'vi').format(this);

  /// Relative time: "2 giờ trước", "vừa xong", "3 ngày trước", etc.
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
    return '${(diff.inDays / 365).floor()} năm trước';
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
  String displayOrDefault([String fallback = 'Không có hạn']) =>
      this?.displayDate ?? fallback;
}
