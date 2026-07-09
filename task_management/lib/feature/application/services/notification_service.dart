import '../i_services/i_notification_service.dart';
import '../../domain/i_repositories/i_notification_repository.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationService implements INotificationService {
  final INotificationRepository _repository;

  NotificationService(this._repository);

  @override
  Future<Either<String, List<NotificationEntity>>> getMyNotifications() async {
    return await _repository.getMyNotifications();
  }
  @override
  Future<Either<String, NotificationEntity>> markAsRead(String notificationId) async {
    return await _repository.markAsRead(notificationId);
  }
}
