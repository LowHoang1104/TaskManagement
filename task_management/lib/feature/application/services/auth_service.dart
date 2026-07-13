import '../i_services/i_auth_service.dart';
import '../../domain/i_repositories/i_auth_repository.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/user_entity.dart';

class AuthService implements IAuthService {
  final IAuthRepository _repository;

  AuthService(this._repository);

  @override
  Future<Either<String, UserEntity>> login(String email, String password) async {
    return await _repository.login(email, password);
  }
  @override
  Future<Either<String, UserEntity>> register(String fullName, String email, String password) async {
    return await _repository.register(fullName, email, password);
  }
  @override
  Future<Either<String, void>> logout() async {
    return await _repository.logout();
  }
  @override
  Future<Either<String, void>> changePassword(String currentPassword, String newPassword) async {
    return await _repository.changePassword(currentPassword, newPassword);
  }
}
