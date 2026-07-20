import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../domain/entities/attachment_entity.dart';
import '../../domain/i_repositories/i_attachment_repository.dart';

class AttachmentRepositoryImp implements IAttachmentRepository {
  final Dio _dio;

  AttachmentRepositoryImp({required Dio dio}) : _dio = dio;

  @override
  Future<Either<String, List<AttachmentEntity>>> getAttachments(String taskId) async {
    try {
      final response = await _dio.get(TaskEndpoints.attachments(taskId));
      final List<dynamic> data = response.data;
      
      final attachments = data.map<AttachmentEntity>((json) {
        return AttachmentEntity(
          id: json['id'],
          taskId: json['taskId'],
          fileName: json['fileName'],
          fileUrl: json['fileUrl'],
          fileSize: json['fileSize'],
          uploadedBy: json['uploadedById'],
          createdAt: DateTime.tryParse(json['uploadedAt']?.toString() ?? '') ?? DateTime.now(),
          uploaderFullName: json['uploaderFullName'] ?? 'Unknown User',
        );
      }).toList();

      return Right(attachments);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? 'Failed to fetch attachments');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, AttachmentEntity>> uploadAttachmentBytes(
      String taskId, String fileName, List<int> bytes) async {
    try {
      final formData = FormData.fromMap({
        // Must match `IFormFile file` on AttachmentsController.UploadAttachment.
        "file": MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dio.post(
        TaskEndpoints.attachments(taskId),
        data: formData,
      );
      return Right(_parse(response.data));
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? 'Failed to upload file');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> deleteAttachment(String taskId, String attachmentId) async {
    try {
      await _dio.delete(TaskEndpoints.attachmentById(taskId, attachmentId));
      return const Right(true);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to delete file');
    } catch (e) {
      return Left(e.toString());
    }
  }

  AttachmentEntity _parse(dynamic json) => AttachmentEntity(
        id: json['id'],
        taskId: json['taskId'],
        fileName: json['fileName'],
        fileUrl: json['fileUrl'],
        fileSize: json['fileSize'],
        uploadedBy: json['uploadedById'],
        createdAt:
            DateTime.tryParse(json['uploadedAt']?.toString() ?? '') ?? DateTime.now(),
        uploaderFullName: json['uploaderFullName'] ?? 'Unknown User',
      );

  @override
  Future<Either<String, AttachmentEntity>> uploadAttachment(String taskId, File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post(
        TaskEndpoints.attachments(taskId),
        data: formData,
      );
      final json = response.data;
      final attachment = AttachmentEntity(
          id: json['id'],
          taskId: json['taskId'],
          fileName: json['fileName'],
          fileUrl: json['fileUrl'],
          fileSize: json['fileSize'],
          uploadedBy: json['uploadedById'],
          createdAt: DateTime.tryParse(json['uploadedAt']?.toString() ?? '') ?? DateTime.now(),
          uploaderFullName: json['uploaderFullName'] ?? 'Unknown User',
      );
      return Right(attachment);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? 'Failed to upload file');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
