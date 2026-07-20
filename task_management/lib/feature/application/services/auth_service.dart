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

  @override
  Future<Either<String, UserEntity>> uploadAvatar({required String fileName, required List<int> fileBytes}) async {
    return await _repository.uploadAvatar(fileName: fileName, fileBytes: fileBytes);
  }

  @override
  Future<Either<String, UserEntity>> checkAuthStatus() async {
    return await _repository.checkAuthStatus();
  }

  @override
  Future<Either<String, UserEntity>> googleLogin() async {
    return await _repository.googleLogin();
  }

  @override
  Future<Either<String, void>> sendOtp(String email) async {
    return await _repository.sendOtp(email);
  }

  @override
  Future<Either<String, UserEntity>> verifyOtpAndRegister(String email, String otp, String password, String fullName) async {
    return await _repository.verifyOtpAndRegister(email, otp, password, fullName);
  }

  @override
  Future<Either<String, void>> forgotPassword(String email) async {
    return await _repository.forgotPassword(email);
  }

  @override
  Future<Either<String, void>> resetPassword(String email, String otp, String newPassword) async {
    return await _repository.resetPassword(email, otp, newPassword);
  }
}
