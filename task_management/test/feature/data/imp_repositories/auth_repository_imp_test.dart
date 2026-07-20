import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:task_management/core/constants/api_endpoints.dart';
import 'package:task_management/core/storage/secure_storage.dart';
import 'package:task_management/feature/data/imp_repositories/auth_repository_imp.dart';

// Mocks
class MockDio extends Mock implements Dio {}
class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late AuthRepositoryImp repository;
  late MockDio mockDio;
  late MockSecureStorage mockSecureStorage;

  setUp(() {
    mockDio = MockDio();
    mockSecureStorage = MockSecureStorage();
    repository = AuthRepositoryImp(
      dio: mockDio,
      secureStorage: mockSecureStorage,
    );
  });

  group('AuthRepositoryImp - login', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    final tResponseData = {
      'token': 'mock_token',
      'user': {
        'id': '1',
        'fullName': 'Test User',
        'email': tEmail,
        'avatarUrl': 'http://avatar.com',
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-01T00:00:00.000Z',
      }
    };

    test('should return Right(UserEntity) and save token on successful login', () async {
      // Arrange
      when(() => mockDio.post(
            AuthEndpoints.login,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: AuthEndpoints.login),
            data: tResponseData,
            statusCode: 200,
          ));
      when(() => mockSecureStorage.saveAccessToken('mock_token')).thenAnswer((_) async => {});

      // Act
      final result = await repository.login(tEmail, tPassword);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (user) {
          expect(user.id, '1');
          expect(user.email, tEmail);
          expect(user.fullName, 'Test User');
        },
      );
      verify(() => mockDio.post(AuthEndpoints.login, data: {'email': tEmail, 'password': tPassword})).called(1);
      verify(() => mockSecureStorage.saveAccessToken('mock_token')).called(1);
    });

    test('should return Left with 401 message when login fails with 401', () async {
      // Arrange
      when(() => mockDio.post(
            AuthEndpoints.login,
            data: any(named: 'data'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: AuthEndpoints.login),
            response: Response(requestOptions: RequestOptions(path: AuthEndpoints.login), statusCode: 401),
          ));

      // Act
      final result = await repository.login(tEmail, tPassword);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (msg) => expect(msg, 'Invalid email or password.'),
        (r) => fail('Should not return right'),
      );
      verifyNever(() => mockSecureStorage.saveAccessToken(any()));
    });

    test('should return Left with generic error message on other DioExceptions', () async {
      // Arrange
      when(() => mockDio.post(
            AuthEndpoints.login,
            data: any(named: 'data'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: AuthEndpoints.login),
            message: 'Connection timeout',
          ));

      // Act
      final result = await repository.login(tEmail, tPassword);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (msg) => expect(msg, 'Connection timeout'),
        (r) => fail('Should not return right'),
      );
      verifyNever(() => mockSecureStorage.saveAccessToken(any()));
    });
  });

  group('AuthRepositoryImp - register', () {
    const tFullName = 'New User';
    const tEmail = 'new@example.com';
    const tPassword = 'password123';
    final tResponseData = {
      'token': 'mock_token',
      'user': {
        'id': '2',
        'fullName': tFullName,
        'email': tEmail,
        'createdAt': '2023-01-01T00:00:00.000Z',
      }
    };

    test('should return Right(UserEntity) on successful registration', () async {
      // Arrange
      when(() => mockDio.post(
            AuthEndpoints.register,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: AuthEndpoints.register),
            data: tResponseData,
            statusCode: 200,
          ));
      when(() => mockSecureStorage.saveAccessToken('mock_token')).thenAnswer((_) async => {});

      // Act
      final result = await repository.register(tFullName, tEmail, tPassword);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (user) {
          expect(user.id, '2');
          expect(user.email, tEmail);
          expect(user.fullName, tFullName);
        },
      );
      verify(() => mockDio.post(AuthEndpoints.register, data: {'fullName': tFullName, 'email': tEmail, 'password': tPassword})).called(1);
    });

    test('should return Left with error message when registration fails', () async {
      // Arrange
      when(() => mockDio.post(
            AuthEndpoints.register,
            data: any(named: 'data'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: AuthEndpoints.register),
            response: Response(
              requestOptions: RequestOptions(path: AuthEndpoints.register),
              statusCode: 400,
              data: {'message': 'Email already exists'},
            ),
          ));

      // Act
      final result = await repository.register(tFullName, tEmail, tPassword);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (msg) => expect(msg, 'Email already exists'),
        (r) => fail('Should not return right'),
      );
    });
  });

  group('AuthRepositoryImp - logout', () {
    test('should return Right(null) and clear secure storage on success', () async {
      // Arrange
      when(() => mockSecureStorage.clearTokens()).thenAnswer((_) async => {});

      // Act
      final result = await repository.logout();

      // Assert
      expect(result.isRight(), true);
      verify(() => mockSecureStorage.clearTokens()).called(1);
    });

    test('should return Left with error message if clearing tokens fails', () async {
      // Arrange
      when(() => mockSecureStorage.clearTokens()).thenThrow(Exception('Storage error'));

      // Act
      final result = await repository.logout();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (msg) => expect(msg, contains('Storage error')),
        (r) => fail('Should not return right'),
      );
    });
  });

  group('AuthRepositoryImp - changePassword', () {
    const tCurrentPassword = 'oldPassword';
    const tNewPassword = 'newPassword';

    test('should return Right(null) on successful password change', () async {
      // Arrange
      when(() => mockDio.post(
            AuthEndpoints.changePassword,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: AuthEndpoints.changePassword),
            statusCode: 200,
          ));

      // Act
      final result = await repository.changePassword(tCurrentPassword, tNewPassword);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockDio.post(AuthEndpoints.changePassword, data: {
        'currentPassword': tCurrentPassword,
        'newPassword': tNewPassword,
      })).called(1);
    });

    test('should return Left with error message on failure', () async {
      // Arrange
      when(() => mockDio.post(
            AuthEndpoints.changePassword,
            data: any(named: 'data'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: AuthEndpoints.changePassword),
            response: Response(
              requestOptions: RequestOptions(path: AuthEndpoints.changePassword),
              statusCode: 400,
              data: {'message': 'Incorrect current password'},
            ),
          ));

      // Act
      final result = await repository.changePassword(tCurrentPassword, tNewPassword);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (msg) => expect(msg, 'Incorrect current password'),
        (r) => fail('Should not return right'),
      );
    });
  });
}
