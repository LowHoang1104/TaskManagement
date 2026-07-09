import 'package:dartz/dartz.dart';
import '../entities/notification_entity.dart';

abstract class INotificationRepository {
  Future<Either<String, List<NotificationEntity>>> getMyNotifications();
  Future<Either<String, NotificationEntity>> markAsRead(String notificationId);
}
