import '../i_services/i_attachment_service.dart';
import '../../domain/i_repositories/i_attachment_repository.dart';
import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../domain/entities/attachment_entity.dart';

class AttachmentService implements IAttachmentService {
  final IAttachmentRepository _repository;

  AttachmentService(this._repository);

  @override
  Future<Either<String, List<AttachmentEntity>>> getAttachments(String taskId) async {
    return await _repository.getAttachments(taskId);
  }
  @override
  Future<Either<String, AttachmentEntity>> uploadAttachment(String taskId, File file) async {
    return await _repository.uploadAttachment(taskId, file);
  }

  @override
  Future<Either<String, AttachmentEntity>> uploadAttachmentBytes(
      String taskId, String fileName, List<int> bytes) async {
    return await _repository.uploadAttachmentBytes(taskId, fileName, bytes);
  }

  @override
  Future<Either<String, bool>> deleteAttachment(String taskId, String attachmentId) async {
    return await _repository.deleteAttachment(taskId, attachmentId);
  }
}
