import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/i_repositories/i_comment_repository.dart';

class CommentRepositoryImp implements ICommentRepository {
  final Dio _dio;

  CommentRepositoryImp({required Dio dio}) : _dio = dio;

  @override
  Future<Either<String, List<CommentEntity>>> getComments(String taskId) async {
    try {
      final response = await _dio.get(TaskEndpoints.comments(taskId));
      final List<dynamic> data = response.data;
      
      final comments = data.map<CommentEntity>((json) {
        return CommentEntity(
          id: json['id'],
          taskId: json['taskId'],
          userId: json['userId'],
          content: json['content'],
          createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
          userFullName: json['userFullName'] ?? 'Unknown User',
          userAvatarUrl: json['userAvatarUrl'],
        );
      }).toList();

      return Right(comments);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? 'Failed to fetch comments');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, CommentEntity>> createComment(String taskId, String content) async {
    try {
      final response = await _dio.post(
        TaskEndpoints.comments(taskId),
        data: {
          'content': content,
        },
      );
      final json = response.data;
      final comment = CommentEntity(
          id: json['id'],
          taskId: json['taskId'],
          userId: json['userId'],
          content: json['content'],
          createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
          userFullName: json['userFullName'] ?? 'Unknown User',
          userAvatarUrl: json['userAvatarUrl'],
      );
      return Right(comment);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? 'Failed to create comment');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
