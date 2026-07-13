import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/i_repositories/i_auth_repository.dart';

class AuthRepositoryImp implements IAuthRepository {
  final Dio _dio;
  final SecureStorage _secureStorage;

  AuthRepositoryImp({required Dio dio, required SecureStorage secureStorage})
      : _dio = dio,
        _secureStorage = secureStorage;

  @override
  Future<Either<String, UserEntity>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        AuthEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['token'] as String?;
      if (token != null) {
        await _secureStorage.saveAccessToken(token);
      }

      final userJson = response.data['user'];
      final user = UserEntity(
        id: userJson['id'],
        fullName: userJson['fullName'],
        email: userJson['email'],
        passwordHash: '', // API does not return password hash
        avatarUrl: userJson['avatarUrl'],
        createdAt: DateTime.tryParse(userJson['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(userJson['updatedAt'] ?? '') ?? DateTime.now(),
      );

      return Right(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left('Invalid email or password.');
      }
      return Left(e.message ?? 'An error occurred during login');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> register(String fullName, String email, String password) async {
    try {
      final response = await _dio.post(
        AuthEndpoints.register,
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );

      final userJson = response.data['user'] ?? response.data;
      final user = UserEntity(
        id: userJson['id'] ?? '',
        fullName: userJson['fullName'] ?? fullName,
        email: userJson['email'] ?? email,
        passwordHash: '', // API does not return password hash
        avatarUrl: userJson['avatarUrl'],
        createdAt: DateTime.tryParse(userJson['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(userJson['updatedAt'] ?? '') ?? DateTime.now(),
      );

      return Right(user);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Registration failed');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> logout() async {
    try {
      await _secureStorage.clearTokens();
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> changePassword(String currentPassword, String newPassword) async {
    try {
      await _dio.post(
        AuthEndpoints.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to change password');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
