import 'package:dartz/dartz.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/task_dependency_entity.dart';

abstract class ITaskService {
  Future<Either<String, List<TaskEntity>>> getTasks(String projectId);
  Future<Either<String, TaskEntity>> updateTaskStatus(String projectId, String taskId, TaskStatus newStatus);
  Future<Either<String, TaskEntity>> updateTaskAssignee(String projectId, String taskId, String? assigneeId);
  Future<Either<String, TaskEntity>> updateTaskDeadline(String projectId, String taskId, DateTime deadline);
  Future<Either<String, TaskEntity>> updateTask(String projectId, String taskId, String title, String description, TaskPriority priority);
  Future<Either<String, TaskEntity>> createTask(String projectId, String title, String description, TaskStatus status, TaskPriority priority);
  Future<Either<String, bool>> deleteTask(String projectId, String id);
  Future<Either<String, List<TaskDependencyEntity>>> getTaskDependencies(String taskId);
  Future<Either<String, bool>> setTaskDependency(String taskId, String predecessorTaskId, String dependencyType);
}
