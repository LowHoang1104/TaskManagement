import 'package:dartz/dartz.dart';
import '../../domain/entities/notification_entity.dart';

abstract class INotificationService {
  Future<Either<String, List<NotificationEntity>>> getMyNotifications();
  Future<Either<String, NotificationEntity>> markAsRead(String notificationId);
}
