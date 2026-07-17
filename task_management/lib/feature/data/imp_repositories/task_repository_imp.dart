import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/task_dependency_entity.dart';
import '../../domain/i_repositories/i_task_repository.dart';

class TaskRepositoryImp implements ITaskRepository {
  final Dio _dio;

  TaskRepositoryImp({required Dio dio}) : _dio = dio;

  @override
  Future<Either<String, List<TaskEntity>>> getTasks(String projectId) async {
    try {
      final response = await _dio.get(TaskEndpoints.byProject(projectId));
      final List<dynamic> data = response.data;
      
      final tasks = data.map<TaskEntity>((json) {
        return TaskEntity(
          id: json['id'],
          projectId: json['projectId'],
          title: json['title'],
          description: json['description'],
          status: TaskStatus.values.firstWhere((e) => e.toString().split('.').last == json['status']?.toString().toLowerCase(), orElse: () => TaskStatus.todo),
          priority: TaskPriority.values.firstWhere((e) => e.toString().split('.').last == json['priority']?.toString().toLowerCase(), orElse: () => TaskPriority.medium),
          assigneeId: json['assigneeId'],
          reporterId: json['reporterId'] ?? 'unknown',
          assigneeName: json['assigneeName'],
          reporterName: json['reporterName'],
          reviewerId: json['reviewerId'],
          order: json['order'] ?? 0,
          deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
          createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
          dependencies: json['dependencies'] != null ? (json['dependencies'] as List).map((e) => TaskDependencyEntity.fromJson(e)).toList() : const [],
        );
      }).toList();

      return Right(tasks);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? 'Failed to fetch tasks');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, TaskEntity>> updateTaskStatus(String projectId, String taskId, TaskStatus newStatus) async {
    try {
      final response = await _dio.put(
        '${TaskEndpoints.byProject(projectId)}/$taskId',
        data: {
          'status': newStatus.toString().split('.').last,
        },
      );
      
      final json = response.data;
      final task = TaskEntity(
          id: json['id'],
          projectId: json['projectId'],
          title: json['title'],
          description: json['description'],
          status: newStatus,
          priority: TaskPriority.values.firstWhere((e) => e.toString().split('.').last == json['priority'].toString().toLowerCase(), orElse: () => TaskPriority.medium),
          assigneeId: json['assigneeId'],
          reporterId: json['reporterId'],
          assigneeName: json['assigneeName'],
          reporterName: json['reporterName'],
          reviewerId: json['reviewerId'],
          order: json['order'] ?? 0,
          deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
          createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
          dependencies: json['dependencies'] != null ? (json['dependencies'] as List).map((e) => TaskDependencyEntity.fromJson(e)).toList() : const [],
      );
      return Right(task);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? 'Failed to update task');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, TaskEntity>> updateTaskAssignee(String projectId, String taskId, String? assigneeId) async {
    try {
      final response = await _dio.put(
        '${TaskEndpoints.byProject(projectId)}/$taskId',
        data: {
          'assigneeId': assigneeId,
        },
      );
      
      final json = response.data;
      final task = TaskEntity(
          id: json['id'],
          projectId: json['projectId'],
          title: json['title'],
          description: json['description'],
          status: TaskStatus.values.firstWhere((e) => e.toString().split('.').last == json['status']?.toString().toLowerCase(), orElse: () => TaskStatus.todo),
          priority: TaskPriority.values.firstWhere((e) => e.toString().split('.').last == json['priority'].toString().toLowerCase(), orElse: () => TaskPriority.medium),
          assigneeId: json['assigneeId'],
          reporterId: json['reporterId'] ?? 'unknown',
          assigneeName: json['assigneeName'],
          reporterName: json['reporterName'],
          reviewerId: json['reviewerId'],
          order: json['order'] ?? 0,
          deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
          createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
          dependencies: json['dependencies'] != null ? (json['dependencies'] as List).map((e) => TaskDependencyEntity.fromJson(e)).toList() : const [],
      );
      return Right(task);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? 'Failed to update task assignee');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, TaskEntity>> updateTaskDeadline(
      String projectId, String taskId, DateTime deadline) async {
    try {
      final response = await _dio.put(
        '${TaskEndpoints.byProject(projectId)}/$taskId',
        data: {'deadline': deadline.toIso8601String()},
      );

      final json = response.data;
      final task = TaskEntity(
        id: json['id'],
        projectId: json['projectId'],
        title: json['title'],
        description: json['description'],
        status: TaskStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status']?.toString().toLowerCase(),
            orElse: () => TaskStatus.todo),
        priority: TaskPriority.values.firstWhere(
            (e) => e.toString().split('.').last == json['priority']?.toString().toLowerCase(),
            orElse: () => TaskPriority.medium),
        assigneeId: json['assigneeId'],
        reporterId: json['reporterId'] ?? 'unknown',
        assigneeName: json['assigneeName'],
        reporterName: json['reporterName'],
        reviewerId: json['reviewerId'],
        order: json['order'] ?? 0,
        deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
        dependencies: json['dependencies'] != null
            ? (json['dependencies'] as List).map((e) => TaskDependencyEntity.fromJson(e)).toList()
            : const [],
      );
      return Right(task);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to update deadline');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, TaskEntity>> updateTask(String projectId, String taskId, String title, String description, TaskPriority priority) async {
    try {
      final response = await _dio.put(
        '${TaskEndpoints.byProject(projectId)}/$taskId',
        data: {
          'title': title,
          'description': description,
          'priority': priority.toString().split('.').last,
        },
      );
      
      final json = response.data;
      final task = TaskEntity(
          id: json['id'],
          projectId: json['projectId'],
          title: json['title'],
          description: json['description'],
          status: TaskStatus.values.firstWhere((e) => e.toString().split('.').last == json['status']?.toString().toLowerCase(), orElse: () => TaskStatus.todo),
          priority: priority,
          assigneeId: json['assigneeId'],
          reporterId: json['reporterId'] ?? 'unknown',
          assigneeName: json['assigneeName'],
          reporterName: json['reporterName'],
          reviewerId: json['reviewerId'],
          order: json['order'] ?? 0,
          deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
          createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
          dependencies: json['dependencies'] != null ? (json['dependencies'] as List).map((e) => TaskDependencyEntity.fromJson(e)).toList() : const [],
      );
      return Right(task);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? 'Failed to update task');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, TaskEntity>> createTask(String projectId, String title, String description, TaskStatus status, TaskPriority priority) async {
    try {
      final response = await _dio.post(
        TaskEndpoints.byProject(projectId),
        data: {
          'title': title,
          'description': description,
          'status': status.toString().split('.').last,
          'priority': priority.toString().split('.').last,
        },
      );
      final json = response.data;
      final task = TaskEntity(
        id: json['id'],
        projectId: json['projectId'],
        title: json['title'],
        description: json['description'],
        status: TaskStatus.values.firstWhere((e) => e.toString().split('.').last == json['status']?.toString().toLowerCase(), orElse: () => TaskStatus.todo),
        priority: TaskPriority.values.firstWhere((e) => e.toString().split('.').last == json['priority']?.toString().toLowerCase(), orElse: () => TaskPriority.medium),
        assigneeId: json['assigneeId'],
        reporterId: json['reporterId'] ?? 'unknown',
        assigneeName: json['assigneeName'],
        reporterName: json['reporterName'],
        reviewerId: json['reviewerId'],
        order: json['order'] ?? 0,
        deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
        dependencies: json['dependencies'] != null ? (json['dependencies'] as List).map((e) => TaskDependencyEntity.fromJson(e)).toList() : const [],
      );
      return Right(task);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to create task');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> deleteTask(String projectId, String id) async {
    try {
      await _dio.delete(TaskEndpoints.delete(projectId, id));
      return const Right(true);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to delete task');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<TaskDependencyEntity>>> getTaskDependencies(String taskId) async {
    try {
      final response = await _dio.get(TaskEndpoints.byId(taskId) + '/dependencies');
      final data = response.data as List;
      final deps = data.map((d) => TaskDependencyEntity.fromJson(d)).toList();
      return Right(deps);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to fetch dependencies');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> setTaskDependency(String taskId, String predecessorTaskId, String dependencyType) async {
    try {
      await _dio.post(TaskEndpoints.byId(taskId) + '/dependencies', data: {
        'predecessorTaskId': predecessorTaskId,
        'dependencyType': dependencyType
      });
      return const Right(true);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to set dependency');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
