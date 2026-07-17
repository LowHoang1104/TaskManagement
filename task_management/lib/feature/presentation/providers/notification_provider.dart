import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/notification_entity.dart';
import '../../application/i_services/i_notification_service.dart';
import '../../application/i_services/i_project_service.dart';
import '../../application/i_services/i_workspace_service.dart';

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
    final result = await sl<INotificationService>().getMyNotifications();

    result.fold(
      (error) => state = state.copyWith(isLoading: false, error: error),
      (notifications) => state = state.copyWith(isLoading: false, notifications: notifications),
    );
  }

  Future<void> markAsRead(String id) async {
    final result = await sl<INotificationService>().markAsRead(id);
    result.fold(
      (error) => state = state.copyWith(error: error),
      (updated) {
        final updatedList = state.notifications.map((n) => n.id == id ? updated : n).toList();
        state = state.copyWith(notifications: updatedList);
      },
    );
  }

  /// Workspace invites require acceptance (project members are added directly),
  /// so "Invite" notifications resolve to these.
  Future<bool> acceptWorkspaceInvite(String workspaceId, String notificationId) async {
    state = state.copyWith(isLoading: true);
    final result = await sl<IWorkspaceService>().acceptWorkspaceInvite(workspaceId);

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

  Future<bool> declineWorkspaceInvite(String workspaceId, String notificationId) async {
    state = state.copyWith(isLoading: true);
    final result = await sl<IWorkspaceService>().declineWorkspaceInvite(workspaceId);

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

  Future<bool> acceptProjectInvite(String projectId, String notificationId) async {
    state = state.copyWith(isLoading: true);
    final result = await sl<IProjectService>().acceptProjectInvitation(projectId);
    
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
    final result = await sl<IProjectService>().declineProjectInvitation(projectId);
    
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
