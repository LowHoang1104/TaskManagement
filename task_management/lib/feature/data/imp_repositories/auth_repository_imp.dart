import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/i_repositories/i_auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepositoryImp implements IAuthRepository {
  final Dio _dio;
  final SecureStorage _secureStorage;
  bool _isGoogleSignInInitialized = false;

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
      if (userJson != null) {
        await _secureStorage.saveUserJson(json.encode(userJson));
      }
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

      final token = response.data['token'] as String?;
      if (token != null) {
        await _secureStorage.saveAccessToken(token);
      } else {
        // If register API does not return a token, log the user in automatically
        return await login(email, password);
      }

      final userJson = response.data['user'] ?? response.data;
      if (userJson != null) {
        await _secureStorage.saveUserJson(json.encode(userJson));
      }
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
  Future<Either<String, UserEntity>> googleLogin() async {
    try {
      if (!_isGoogleSignInInitialized) {
        await GoogleSignIn.instance.initialize(
          serverClientId: '687953212793-59akc1q3e9ss6285nh0ffe49dihs219r.apps.googleusercontent.com',
        );
        _isGoogleSignInInitialized = true;
      }

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication auth = account.authentication;
      if (auth.idToken == null) {
        return const Left('Failed to get Google ID Token.');
      }

      // Send idToken to Backend
      final response = await _dio.post(
        AuthEndpoints.googleLogin,
        data: {
          'idToken': auth.idToken,
        },
      );

      final token = response.data['token'] as String?;
      if (token != null) {
        await _secureStorage.saveAccessToken(token);
      }

      final userJson = response.data['user'] ?? response.data;
      if (userJson != null) {
        await _secureStorage.saveUserJson(json.encode(userJson));
      }
      final user = UserEntity(
        id: userJson['id'] ?? '',
        fullName: userJson['fullName'] ?? '',
        email: userJson['email'] ?? '',
        passwordHash: '',
        avatarUrl: userJson['avatarUrl'],
        createdAt: DateTime.tryParse(userJson['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(userJson['updatedAt'] ?? '') ?? DateTime.now(),
      );

      return Right(user);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Google Login failed on server');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> sendOtp(String email) async {
    try {
      await _dio.post(
        AuthEndpoints.sendOtp,
        data: {
          'email': email,
        },
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to send OTP');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> verifyOtpAndRegister(String email, String otp, String password, String fullName) async {
    try {
      final response = await _dio.post(
        AuthEndpoints.verifyOtp,
        data: {
          'email': email,
          'otp': otp,
          'password': password,
          'fullName': fullName,
        },
      );

      final token = response.data['token'] as String?;
      if (token != null) {
        await _secureStorage.saveAccessToken(token);
      }

      final userJson = response.data['user'] ?? response.data;
      if (userJson != null) {
        await _secureStorage.saveUserJson(json.encode(userJson));
      }
      
      final user = UserEntity(
        id: userJson['id'] ?? '',
        fullName: userJson['fullName'] ?? fullName,
        email: userJson['email'] ?? email,
        passwordHash: '',
        avatarUrl: userJson['avatarUrl'],
        createdAt: DateTime.tryParse(userJson['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(userJson['updatedAt'] ?? '') ?? DateTime.now(),
      );

      return Right(user);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to verify OTP and register');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> forgotPassword(String email) async {
    try {
      await _dio.post(
        AuthEndpoints.forgotPassword,
        data: {'email': email},
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to send password reset OTP');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> resetPassword(String email, String otp, String newPassword) async {
    try {
      await _dio.post(
        AuthEndpoints.resetPassword,
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to reset password');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> logout() async {
    try {
      if (_isGoogleSignInInitialized) {
        try {
          await GoogleSignIn.instance.disconnect();
        } catch (_) {}
      }
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

  @override
  Future<Either<String, UserEntity>> uploadAvatar({required String fileName, required List<int> fileBytes}) async {
    try {
      final formData = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final response = await _dio.post(
        AuthEndpoints.uploadAvatar,
        data: formData,
      );

      print('Upload Avatar Response: ${response.data}');

      final userJson = response.data['user'] ?? response.data;
      if (userJson != null) {
        await _secureStorage.saveUserJson(json.encode(userJson));
      }
      
      String? avatarUrl = userJson['avatarUrl'];
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        if (!avatarUrl.startsWith('http')) {
          final baseUrl = kBaseUrl.replaceAll('/api', '');
          avatarUrl = avatarUrl.startsWith('/') ? '$baseUrl$avatarUrl' : '$baseUrl/$avatarUrl';
        }
        // Cache-busting param so Flutter always loads the latest image for the same URL.
        final separator = avatarUrl.contains('?') ? '&' : '?';
        avatarUrl = '$avatarUrl${separator}t=${DateTime.now().millisecondsSinceEpoch}';
      }

      final user = UserEntity(
        id: userJson['id'] ?? '',
        fullName: userJson['fullName'] ?? '',
        email: userJson['email'] ?? '',
        passwordHash: '',
        avatarUrl: avatarUrl,
        createdAt: DateTime.tryParse(userJson['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(userJson['updatedAt'] ?? '') ?? DateTime.now(),
      );

      return Right(user);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to upload avatar');
    } catch (e) {
      return Left(e.toString());
    }
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      String payloadStr = parts[1];
      payloadStr = payloadStr.replaceAll('-', '+').replaceAll('_', '/');
      switch (payloadStr.length % 4) {
        case 0: break;
        case 2: payloadStr += '=='; break;
        case 3: payloadStr += '='; break;
        default: return true;
      }
      final payload = utf8.decode(base64Decode(payloadStr));
      final payloadMap = json.decode(payload);
      final exp = payloadMap['exp'] as int?;
      if (exp == null) return false;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Add a 1 minute buffer
      return now >= (exp - 60);
    } catch (e) {
      return true;
    }
  }

  @override
  Future<Either<String, UserEntity>> checkAuthStatus() async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        return const Left('No token found');
      }

      if (_isTokenExpired(token)) {
        await _secureStorage.clearTokens();
        return const Left('Session expired');
      }

      // Fast path: use cached user profile
      final cachedUserStr = await _secureStorage.getUserJson();
      if (cachedUserStr != null && cachedUserStr.isNotEmpty) {
        final userJson = json.decode(cachedUserStr);
        String? avatarUrl = userJson['avatarUrl'];
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          if (!avatarUrl.startsWith('http')) {
            final baseUrl = kBaseUrl.replaceAll('/api', '');
            avatarUrl = avatarUrl.startsWith('/') ? '$baseUrl$avatarUrl' : '$baseUrl/$avatarUrl';
          }
        }
        final user = UserEntity(
          id: userJson['id'] ?? '',
          fullName: userJson['fullName'] ?? '',
          email: userJson['email'] ?? '',
          passwordHash: '',
          avatarUrl: avatarUrl,
          createdAt: DateTime.tryParse(userJson['createdAt'] ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(userJson['updatedAt'] ?? '') ?? DateTime.now(),
        );
        return Right(user);
      }

      // Fallback: fetch from API
      final response = await _dio.get(AuthEndpoints.me).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );
      final userJson = response.data['user'] ?? response.data;
      
      String? avatarUrl = userJson['avatarUrl'];
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        if (!avatarUrl.startsWith('http')) {
          final baseUrl = kBaseUrl.replaceAll('/api', '');
          avatarUrl = avatarUrl.startsWith('/') ? '$baseUrl$avatarUrl' : '$baseUrl/$avatarUrl';
        }
      }

      final user = UserEntity(
        id: userJson['id'] ?? '',
        fullName: userJson['fullName'] ?? '',
        email: userJson['email'] ?? '',
        passwordHash: '',
        avatarUrl: avatarUrl,
        createdAt: DateTime.tryParse(userJson['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(userJson['updatedAt'] ?? '') ?? DateTime.now(),
      );

      return Right(user);
    } catch (e) {
      // Token invalid or expired
      try {
        await _secureStorage.clearTokens();
      } catch (_) {}
      return const Left('Session expired');
    }
  }
}
