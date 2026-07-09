import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../providers/notification_provider.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../providers/project_members_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
              ? const Center(child: Text('No notifications yet', style: TextStyle(color: AppColors.grey600)))
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.md),
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    return _NotificationTile(notification: notification);
                  },
                ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationEntity notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isInvite = notification.type.toLowerCase() == 'invite';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
      tileColor: notification.isRead ? Colors.transparent : Colors.blue.withValues(alpha: 0.05),
      leading: CircleAvatar(
        backgroundColor: isInvite ? AppColors.primary.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        child: Icon(
          isInvite ? Icons.mail_outline_rounded : Icons.comment_rounded,
          color: isInvite ? AppColors.primary : Colors.orange,
        ),
      ),
      title: Text(
        notification.message,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            timeago.format(notification.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey600),
          ),
          if (isInvite && !notification.isRead && notification.relatedId != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final success = await ref.read(notificationProvider.notifier).acceptProjectInvite(
                      notification.relatedId!,
                      notification.id,
                    );
                    if (context.mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invitation accepted!'), backgroundColor: AppColors.success),
                        );
                      } else {
                        final error = ref.read(notificationProvider).error;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error ?? 'Failed to accept invitation'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Accept'),
                ),
                const SizedBox(width: AppSizes.sm),
                OutlinedButton(
                  onPressed: () async {
                    final success = await ref.read(notificationProvider.notifier).declineProjectInvite(
                      notification.relatedId!,
                      notification.id,
                    );
                    if (context.mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invitation declined'), backgroundColor: AppColors.success),
                        );
                      } else {
                        final error = ref.read(notificationProvider).error;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error ?? 'Failed to decline'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Decline'),
                ),
              ],
            )
          ]
        ],
      ),
      onTap: () {
        if (!notification.isRead) {
          ref.read(notificationProvider.notifier).markAsRead(notification.id);
        }
      },
    );
  }
}
