import '../i_services/i_task_service.dart';
import '../../domain/i_repositories/i_task_repository.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/enums.dart';

class TaskService implements ITaskService {
  final ITaskRepository _repository;

  TaskService(this._repository);

  @override
  Future<Either<String, List<TaskEntity>>> getTasks(String projectId) async {
    return await _repository.getTasks(projectId);
  }
  @override
  Future<Either<String, TaskEntity>> updateTaskStatus(String projectId, String taskId, TaskStatus newStatus) async {
    return await _repository.updateTaskStatus(projectId, taskId, newStatus);
  }
  @override
  Future<Either<String, TaskEntity>> updateTask(String projectId, String taskId, String title, String description, TaskPriority priority) async {
    return await _repository.updateTask(projectId, taskId, title, description, priority);
  }
  @override
  Future<Either<String, TaskEntity>> createTask(String projectId, String title, String description, TaskStatus status, TaskPriority priority) async {
    return await _repository.createTask(projectId, title, description, status, priority);
  }
  @override
  Future<Either<String, bool>> deleteTask(String projectId, String id) async {
    return await _repository.deleteTask(projectId, id);
  }
}
