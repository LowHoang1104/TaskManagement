import 'package:dartz/dartz.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/enums.dart';

abstract class ITaskRepository {
  Future<Either<String, List<TaskEntity>>> getTasks(String projectId);
  Future<Either<String, TaskEntity>> updateTaskStatus(String projectId, String taskId, TaskStatus newStatus);
  Future<Either<String, TaskEntity>> updateTask(String projectId, String taskId, String title, String description, TaskPriority priority);
  Future<Either<String, TaskEntity>> createTask(String projectId, String title, String description, TaskStatus status, TaskPriority priority);
  Future<Either<String, bool>> deleteTask(String projectId, String id);
}
