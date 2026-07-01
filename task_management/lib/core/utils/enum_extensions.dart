import 'package:flutter/material.dart';
import '../../feature/domain/entities/enums.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// Extension helpers for domain enums – localized labels and colors.

extension TaskStatusExtension on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return AppStrings.statusTodo;
      case TaskStatus.doing:
        return AppStrings.statusDoing;
      case TaskStatus.review:
        return AppStrings.statusReview;
      case TaskStatus.done:
        return AppStrings.statusDone;
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.todo:
        return AppColors.statusTodo;
      case TaskStatus.doing:
        return AppColors.statusDoing;
      case TaskStatus.review:
        return AppColors.statusReview;
      case TaskStatus.done:
        return AppColors.statusDone;
    }
  }
}

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return AppStrings.priorityLow;
      case TaskPriority.medium:
        return AppStrings.priorityMedium;
      case TaskPriority.high:
        return AppStrings.priorityHigh;
      case TaskPriority.critical:
        return AppStrings.priorityCritical;
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return AppColors.priorityLow;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.critical:
        return AppColors.priorityCritical;
    }
  }

  IconData get icon {
    switch (this) {
      case TaskPriority.low:
        return Icons.arrow_downward_rounded;
      case TaskPriority.medium:
        return Icons.remove_rounded;
      case TaskPriority.high:
        return Icons.arrow_upward_rounded;
      case TaskPriority.critical:
        return Icons.priority_high_rounded;
    }
  }
}

extension ProjectRoleExtension on ProjectRole {
  String get label {
    switch (this) {
      case ProjectRole.leader:
        return 'Leader';
      case ProjectRole.member:
        return 'Member';
    }
  }
}

extension WorkspaceRoleExtension on WorkspaceRole {
  String get label {
    switch (this) {
      case WorkspaceRole.owner:
        return 'Owner';
      case WorkspaceRole.admin:
        return 'Admin';
      case WorkspaceRole.member:
        return 'Member';
    }
  }
}
