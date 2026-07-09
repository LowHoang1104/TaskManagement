import 'package:dartz/dartz.dart';
import '../../domain/entities/workspace_entity.dart';

abstract class IWorkspaceService {
  Future<Either<String, List<WorkspaceEntity>>> getWorkspaces();
  Future<Either<String, WorkspaceEntity>> createWorkspace(String name, String? description);
  Future<Either<String, bool>> deleteWorkspace(String id);
}
