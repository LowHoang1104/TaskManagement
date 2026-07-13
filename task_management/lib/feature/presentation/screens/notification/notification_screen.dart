import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../providers/notification_provider.dart';
import '../../../domain/entities/notification_entity.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
            tooltip: 'Mark all as read',
            onPressed: () {
              // Should implement mark all as read logic here
            },
          ),
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_rounded, size: 80, color: AppColors.grey400)
                          .animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: AppSizes.md),
                      const Text('No notifications yet', style: TextStyle(color: AppColors.grey600, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
                  itemCount: state.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    return _NotificationTile(notification: notification, index: index);
                  },
                ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationEntity notification;
  final int index;

  const _NotificationTile({required this.notification, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isInvite = notification.type.toLowerCase() == 'invite';

    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          ref.read(notificationProvider.notifier).markAsRead(notification.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.md),
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: notification.isRead ? theme.colorScheme.surface : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: notification.isRead ? theme.dividerColor.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey200.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isInvite ? AppColors.primary.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isInvite ? Icons.mail_rounded : Icons.info_rounded,
                color: isInvite ? AppColors.primary : AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w700,
                      color: notification.isRead ? theme.colorScheme.onSurface : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeago.format(notification.createdAt),
                    style: theme.textTheme.labelMedium?.copyWith(color: AppColors.grey600, fontWeight: FontWeight.w600),
                  ),
                  if (isInvite && !notification.isRead && notification.relatedId != null) ...[
                    const SizedBox(height: AppSizes.md),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                              elevation: 0,
                            ),
                            child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final success = await ref.read(notificationProvider.notifier).declineProjectInvite(
                                notification.relatedId!,
                                notification.id,
                              );
                              if (context.mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Invitation declined'), backgroundColor: AppColors.grey600),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                            ),
                            child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ]
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ).animate().slideY(begin: 0.1, delay: (100 * index).ms).fadeIn(),
    );
  }
}
