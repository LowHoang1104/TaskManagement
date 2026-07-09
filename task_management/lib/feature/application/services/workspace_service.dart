import '../i_services/i_workspace_service.dart';
import '../../domain/i_repositories/i_workspace_repository.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/workspace_entity.dart';

class WorkspaceService implements IWorkspaceService {
  final IWorkspaceRepository _repository;

  WorkspaceService(this._repository);

  @override
  Future<Either<String, List<WorkspaceEntity>>> getWorkspaces() async {
    return await _repository.getWorkspaces();
  }
  @override
  Future<Either<String, WorkspaceEntity>> createWorkspace(String name, String? description) async {
    return await _repository.createWorkspace(name, description);
  }
  @override
  Future<Either<String, bool>> deleteWorkspace(String id) async {
    return await _repository.deleteWorkspace(id);
  }
}
