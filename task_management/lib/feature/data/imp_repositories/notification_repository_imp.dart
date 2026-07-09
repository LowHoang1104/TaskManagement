import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/i_repositories/i_notification_repository.dart';

class NotificationRepositoryImp implements INotificationRepository {
  final Dio _dio;

  NotificationRepositoryImp(this._dio);

  @override
  Future<Either<String, List<NotificationEntity>>> getMyNotifications() async {
    try {
      final response = await _dio.get(NotificationEndpoints.base);
      final List<dynamic> data = response.data;
      final notifications = data.map((json) => NotificationEntity.fromJson(json)).toList();
      return Right(notifications);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to load notifications');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, NotificationEntity>> markAsRead(String notificationId) async {
    try {
      final response = await _dio.put(NotificationEndpoints.markRead(notificationId));
      return Right(NotificationEntity.fromJson(response.data));
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to mark notification as read');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
