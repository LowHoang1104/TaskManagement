import 'package:dartz/dartz.dart';
import '../../domain/entities/user_entity.dart';

abstract class IAuthRepository {
  Future<Either<String, UserEntity>> login(String email, String password);
  Future<Either<String, UserEntity>> register(String fullName, String email, String password);
  Future<Either<String, void>> logout();
  Future<Either<String, void>> changePassword(String currentPassword, String newPassword);
}
