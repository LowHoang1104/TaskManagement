import '../i_services/i_comment_service.dart';
import '../../domain/i_repositories/i_comment_repository.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/comment_entity.dart';

class CommentService implements ICommentService {
  final ICommentRepository _repository;

  CommentService(this._repository);

  @override
  Future<Either<String, List<CommentEntity>>> getComments(String taskId) async {
    return await _repository.getComments(taskId);
  }
  @override
  Future<Either<String, CommentEntity>> createComment(String taskId, String content) async {
    return await _repository.createComment(taskId, content);
  }
}
