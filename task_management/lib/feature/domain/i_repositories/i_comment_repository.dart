import 'package:dartz/dartz.dart';
import '../entities/comment_entity.dart';

abstract class ICommentRepository {
  Future<Either<String, List<CommentEntity>>> getComments(String taskId);
  Future<Either<String, CommentEntity>> createComment(String taskId, String content);
}
