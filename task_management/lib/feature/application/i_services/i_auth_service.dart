import 'package:dartz/dartz.dart';
import '../../domain/entities/user_entity.dart';

abstract class IAuthService {
  Future<Either<String, UserEntity>> login(String email, String password);
  Future<Either<String, UserEntity>> register(String fullName, String email, String password);
  Future<Either<String, void>> logout();
}
