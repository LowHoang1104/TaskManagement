import 'package:dartz/dartz.dart';
import '../../domain/entities/comment_entity.dart';

abstract class ICommentService {
  Future<Either<String, List<CommentEntity>>> getComments(String taskId);
  Future<Either<String, CommentEntity>> createComment(String taskId, String content);
}
