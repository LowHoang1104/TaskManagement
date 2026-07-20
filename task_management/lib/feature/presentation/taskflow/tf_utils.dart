import 'package:flutter/material.dart';
import '../../../app/theme/app_palette.dart';
import '../../domain/entities/enums.dart';

/// Small presentation helpers shared across the redesigned TaskFlow screens:
/// deriving avatar initials/colors and mapping task status/priority enums to
/// the design's colors and labels.

String initialsOf(String? name) {
  final n = (name ?? '').trim();
  if (n.isEmpty) return '?';
  final parts = n.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.length == 1) {
    final p = parts.first;
    return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

const _avatarPalette = <int>[
  0xFF2F6BFF,
  0xFFE08A13,
  0xFF22A35B,
  0xFF7C3AED,
  0xFFE5484D,
  0xFF0EA5E9,
  0xFFEC4899,
  0xFF14B8A6,
];

/// Deterministic avatar color from a stable key (user id or name).
Color avatarColorFor(String key) {
  if (key.isEmpty) return const Color(0xFF6A7280);
  return Color(_avatarPalette[key.hashCode.abs() % _avatarPalette.length]);
}

// ── Status ──────────────────────────────────────────────────────────────────
Color statusColor(AppPalette p, TaskStatus s) {
  switch (s) {
    case TaskStatus.todo:
      return p.statusTodo;
    case TaskStatus.doing:
      return p.accent;
    case TaskStatus.review:
      return p.statusReview;
    case TaskStatus.done:
      return p.statusDone;
  }
}

String statusLabel(TaskStatus s) {
  switch (s) {
    case TaskStatus.todo:
      return 'To Do';
    case TaskStatus.doing:
      return 'In Progress';
    case TaskStatus.review:
      return 'Review';
    case TaskStatus.done:
      return 'Done';
  }
}

// ── Priority ────────────────────────────────────────────────────────────────
/// Returns null for the neutral (Low / Normal) priorities so [TfTag] renders
/// its muted variant.
Color? priorityColor(AppPalette p, TaskPriority pr) {
  switch (pr) {
    case TaskPriority.low:
    case TaskPriority.medium:
      return null;
    case TaskPriority.high:
      return p.warning;
    case TaskPriority.critical:
      return p.danger;
  }
}

String priorityLabel(TaskPriority pr) {
  switch (pr) {
    case TaskPriority.low:
      return 'Low';
    case TaskPriority.medium:
      return 'Normal';
    case TaskPriority.high:
      return 'High';
    case TaskPriority.critical:
      return 'Critical';
  }
}
