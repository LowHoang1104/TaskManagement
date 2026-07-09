import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/i_repositories/i_notification_repository.dart';
import '../../domain/i_repositories/i_project_repository.dart';

class NotificationState {
  final bool isLoading;
  final String? error;
  final List<NotificationEntity> notifications;

  const NotificationState({
    this.isLoading = false,
    this.error,
    this.notifications = const [],
  });

  NotificationState copyWith({
    bool? isLoading,
    String? error,
    List<NotificationEntity>? notifications,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      notifications: notifications ?? this.notifications,
    );
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await sl<INotificationRepository>().getMyNotifications();

    result.fold(
      (error) => state = state.copyWith(isLoading: false, error: error),
      (notifications) => state = state.copyWith(isLoading: false, notifications: notifications),
    );
  }

  Future<void> markAsRead(String id) async {
    final result = await sl<INotificationRepository>().markAsRead(id);
    result.fold(
      (error) => state = state.copyWith(error: error),
      (updated) {
        final updatedList = state.notifications.map((n) => n.id == id ? updated : n).toList();
        state = state.copyWith(notifications: updatedList);
      },
    );
  }

  Future<bool> acceptProjectInvite(String projectId, String notificationId) async {
    state = state.copyWith(isLoading: true);
    final result = await sl<IProjectRepository>().acceptProjectInvitation(projectId);
    
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      },
      (member) async {
        // Mark notification as read
        await markAsRead(notificationId);
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  Future<bool> declineProjectInvite(String projectId, String notificationId) async {
    state = state.copyWith(isLoading: true);
    final result = await sl<IProjectRepository>().declineProjectInvitation(projectId);
    
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      },
      (_) async {
        await markAsRead(notificationId);
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);
