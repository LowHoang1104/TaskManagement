import 'package:dartz/dartz.dart';
import '../../domain/entities/user_entity.dart';

abstract class IAuthService {
  Future<Either<String, UserEntity>> login(String email, String password);
  Future<Either<String, UserEntity>> register(String fullName, String email, String password);
  Future<Either<String, void>> logout();
  Future<Either<String, void>> changePassword(String currentPassword, String newPassword);
  Future<Either<String, UserEntity>> uploadAvatar({required String fileName, required List<int> fileBytes});
  Future<Either<String, UserEntity>> googleLogin();
  Future<Either<String, void>> sendOtp(String email);
  Future<Either<String, UserEntity>> verifyOtpAndRegister(String email, String otp, String password, String fullName);
  Future<Either<String, UserEntity>> checkAuthStatus();
  Future<Either<String, void>> forgotPassword(String email);
  Future<Either<String, void>> resetPassword(String email, String otp, String newPassword);
}
