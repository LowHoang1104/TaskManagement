import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:task_management/core/constants/api_endpoints.dart';
import 'package:task_management/core/storage/secure_storage.dart';
import 'package:task_management/feature/data/imp_repositories/auth_repository_imp.dart';

class MockDio extends Mock implements Dio {}

class MockSecureStorage extends Mock implements SecureStorage {}

// Fake for DioException requestOptions fallback (needed by mocktail for any())
class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late MockDio mockDio;
  late MockSecureStorage mockSecureStorage;
  late AuthRepositoryImp repository;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(Options());
  });

  setUp(() {
    mockDio = MockDio();
    mockSecureStorage = MockSecureStorage();
    repository = AuthRepositoryImp(
      dio: mockDio,
      secureStorage: mockSecureStorage,
    );
  });

  /// Helper to build a fake JWT with a given expiry (seconds since epoch).
  /// If [exp] is null, the payload will not include an "exp" claim.
  String buildFakeJwt({int? exp}) {
    final header = base64Url.encode(utf8.encode(json.encode({'alg': 'HS256', 'typ': 'JWT'})));
    final payloadMap = <String, dynamic>{'sub': 'user123'};
    if (exp != null) payloadMap['exp'] = exp;
    final payload = base64Url.encode(utf8.encode(json.encode(payloadMap)));
    // Strip padding to mimic real JWTs (repository code re-pads it)
    final headerNoPad = header.replaceAll('=', '');
    final payloadNoPad = payload.replaceAll('=', '');
    return '$headerNoPad.$payloadNoPad.fakesignature';
  }

  Map<String, dynamic> sampleUserJson({String id = '1'}) => {
        'id': id,
        'fullName': 'Jane Doe',
        'email': 'jane@example.com',
        'avatarUrl': null,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

  DioException dioError({int? statusCode, dynamic data, String? message}) {
    final requestOptions = RequestOptions(path: '/');
    return DioException(
      requestOptions: requestOptions,
      response: statusCode != null
          ? Response(requestOptions: requestOptions, statusCode: statusCode, data: data)
          : null,
      message: message,
    );
  }

  group('login', () {
    test('returns Right(UserEntity) and saves token on success', () async {
      when(() => mockDio.post(AuthEndpoints.login, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: AuthEndpoints.login),
          statusCode: 200,
          data: {'token': 'abc123', 'user': sampleUserJson()},
        ),
      );
      when(() => mockSecureStorage.saveAccessToken(any())).thenAnswer((_) async {});
      when(() => mockSecureStorage.saveUserJson(any())).thenAnswer((_) async {});

      final result = await repository.login('jane@example.com', 'password123');

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('expected Right, got Left($l)'),
        (user) {
          expect(user.email, 'jane@example.com');
          expect(user.fullName, 'Jane Doe');
        },
      );
      verify(() => mockSecureStorage.saveAccessToken('abc123')).called(1);
      verify(() => mockSecureStorage.saveUserJson(any())).called(1);
    });

    test('returns Left("Invalid email or password.") on 401', () async {
      when(() => mockDio.post(AuthEndpoints.login, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 401));

      final result = await repository.login('jane@example.com', 'wrongpass');

      expect(result, const Left('Invalid email or password.'));
    });

    test('returns Left(message) on other DioException', () async {
      when(() => mockDio.post(AuthEndpoints.login, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 500, message: 'Server error'));

      final result = await repository.login('jane@example.com', 'password123');

      expect(result.isLeft(), true);
    });

    test('returns Left(error) on generic exception', () async {
      when(() => mockDio.post(AuthEndpoints.login, data: any(named: 'data')))
          .thenThrow(Exception('network down'));

      final result = await repository.login('jane@example.com', 'password123');

      expect(result.isLeft(), true);
    });

    test('does not save token if token is null in response', () async {
      when(() => mockDio.post(AuthEndpoints.login, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: AuthEndpoints.login),
          statusCode: 200,
          data: {'user': sampleUserJson()},
        ),
      );
      when(() => mockSecureStorage.saveUserJson(any())).thenAnswer((_) async {});

      final result = await repository.login('jane@example.com', 'password123');

      expect(result.isRight(), true);
      verifyNever(() => mockSecureStorage.saveAccessToken(any()));
    });
  });

  group('register', () {
    test('returns Right(UserEntity) when token is returned directly', () async {
      when(() => mockDio.post(AuthEndpoints.register, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: AuthEndpoints.register),
          statusCode: 201,
          data: {'token': 'tok', 'user': sampleUserJson()},
        ),
      );
      when(() => mockSecureStorage.saveAccessToken(any())).thenAnswer((_) async {});
      when(() => mockSecureStorage.saveUserJson(any())).thenAnswer((_) async {});

      final result = await repository.register('Jane Doe', 'jane@example.com', 'password123');

      expect(result.isRight(), true);
      verify(() => mockSecureStorage.saveAccessToken('tok')).called(1);
    });

    test('falls back to login() when no token is returned', () async {
      when(() => mockDio.post(AuthEndpoints.register, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: AuthEndpoints.register),
          statusCode: 200,
          data: {'user': sampleUserJson()},
        ),
      );
      when(() => mockDio.post(AuthEndpoints.login, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: AuthEndpoints.login),
          statusCode: 200,
          data: {'token': 'loginTok', 'user': sampleUserJson()},
        ),
      );
      when(() => mockSecureStorage.saveAccessToken(any())).thenAnswer((_) async {});
      when(() => mockSecureStorage.saveUserJson(any())).thenAnswer((_) async {});

      final result = await repository.register('Jane Doe', 'jane@example.com', 'password123');

      expect(result.isRight(), true);
      verify(() => mockDio.post(AuthEndpoints.login, data: any(named: 'data'))).called(1);
    });

    test('returns Left with server message on DioException', () async {
      when(() => mockDio.post(AuthEndpoints.register, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 400, data: {'message': 'Email already exists'}));

      final result = await repository.register('Jane Doe', 'jane@example.com', 'password123');

      expect(result, const Left('Email already exists'));
    });
  });

  group('sendOtp', () {
    test('returns Right(null) on success', () async {
      when(() => mockDio.post(AuthEndpoints.sendOtp, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: AuthEndpoints.sendOtp), statusCode: 200),
      );

      final result = await repository.sendOtp('jane@example.com');

      expect(result, const Right(null));
    });

    test('returns Left(message) on failure', () async {
      when(() => mockDio.post(AuthEndpoints.sendOtp, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 400, data: {'message': 'Invalid email'}));

      final result = await repository.sendOtp('bad-email');

      expect(result, const Left('Invalid email'));
    });
  });

  group('verifyOtpAndRegister', () {
    test('returns Right(UserEntity) on success', () async {
      when(() => mockDio.post(AuthEndpoints.verifyOtp, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: AuthEndpoints.verifyOtp),
          statusCode: 200,
          data: {'token': 'tok', 'user': sampleUserJson()},
        ),
      );
      when(() => mockSecureStorage.saveAccessToken(any())).thenAnswer((_) async {});
      when(() => mockSecureStorage.saveUserJson(any())).thenAnswer((_) async {});

      final result = await repository.verifyOtpAndRegister(
        'jane@example.com',
        '123456',
        'password123',
        'Jane Doe',
      );

      expect(result.isRight(), true);
    });

    test('returns Left(message) on invalid OTP', () async {
      when(() => mockDio.post(AuthEndpoints.verifyOtp, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 400, data: {'message': 'Invalid OTP'}));

      final result = await repository.verifyOtpAndRegister(
        'jane@example.com',
        '000000',
        'password123',
        'Jane Doe',
      );

      expect(result, const Left('Invalid OTP'));
    });
  });

  group('forgotPassword', () {
    test('returns Right(null) on success', () async {
      when(() => mockDio.post(AuthEndpoints.forgotPassword, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: AuthEndpoints.forgotPassword), statusCode: 200),
      );

      final result = await repository.forgotPassword('jane@example.com');

      expect(result, const Right(null));
    });

    test('returns Left(message) when email not found', () async {
      when(() => mockDio.post(AuthEndpoints.forgotPassword, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 404, data: {'message': 'Email not found'}));

      final result = await repository.forgotPassword('unknown@example.com');

      expect(result, const Left('Email not found'));
    });
  });

  group('resetPassword', () {
    test('returns Right(null) on success', () async {
      when(() => mockDio.post(AuthEndpoints.resetPassword, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: AuthEndpoints.resetPassword), statusCode: 200),
      );

      final result = await repository.resetPassword('jane@example.com', '123456', 'newPassword123');

      expect(result, const Right(null));
    });

    test('returns Left(message) on invalid/expired OTP', () async {
      when(() => mockDio.post(AuthEndpoints.resetPassword, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 400, data: {'message': 'OTP expired'}));

      final result = await repository.resetPassword('jane@example.com', '000000', 'newPassword123');

      expect(result, const Left('OTP expired'));
    });
  });

  group('changePassword', () {
    test('returns Right(null) on success', () async {
      when(() => mockDio.post(AuthEndpoints.changePassword, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: AuthEndpoints.changePassword), statusCode: 200),
      );

      final result = await repository.changePassword('oldPass123', 'newPass123');

      expect(result, const Right(null));
    });

    test('returns Left(message) when current password is wrong', () async {
      when(() => mockDio.post(AuthEndpoints.changePassword, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 400, data: {'message': 'Current password is incorrect'}));

      final result = await repository.changePassword('wrongPass', 'newPass123');

      expect(result, const Left('Current password is incorrect'));
    });
  });

  group('logout', () {
    test('clears tokens and returns Right(null)', () async {
      when(() => mockSecureStorage.clearTokens()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result, const Right(null));
      verify(() => mockSecureStorage.clearTokens()).called(1);
    });

    test('returns Left(error) if clearTokens throws', () async {
      when(() => mockSecureStorage.clearTokens()).thenThrow(Exception('storage error'));

      final result = await repository.logout();

      expect(result.isLeft(), true);
    });
  });

  group('uploadAvatar', () {
    test('returns Right(UserEntity) with absolute avatarUrl unchanged (plus cache-buster)', () async {
      when(() => mockDio.post(AuthEndpoints.uploadAvatar, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: AuthEndpoints.uploadAvatar),
          statusCode: 200,
          data: {
            'user': {
              ...sampleUserJson(),
              'avatarUrl': 'https://cdn.example.com/avatars/jane.png',
            },
          },
        ),
      );
      when(() => mockSecureStorage.saveUserJson(any())).thenAnswer((_) async {});

      final result = await repository.uploadAvatar(fileName: 'avatar.png', fileBytes: [1, 2, 3]);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('expected Right, got Left($l)'),
        (user) {
          expect(user.avatarUrl, startsWith('https://cdn.example.com/avatars/jane.png?t='));
        },
      );
    });

    test('returns Right(UserEntity) with relative avatarUrl prefixed with base URL', () async {
      when(() => mockDio.post(AuthEndpoints.uploadAvatar, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: AuthEndpoints.uploadAvatar),
          statusCode: 200,
          data: {
            'user': {
              ...sampleUserJson(),
              'avatarUrl': '/uploads/jane.png',
            },
          },
        ),
      );
      when(() => mockSecureStorage.saveUserJson(any())).thenAnswer((_) async {});

      final result = await repository.uploadAvatar(fileName: 'avatar.png', fileBytes: [1, 2, 3]);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('expected Right, got Left($l)'),
        (user) {
          expect(user.avatarUrl, contains('/uploads/jane.png?t='));
          expect(user.avatarUrl, isNot(contains('/api')));
        },
      );
    });

    test('returns Left(message) on upload failure', () async {
      when(() => mockDio.post(AuthEndpoints.uploadAvatar, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 413, data: {'message': 'File too large'}));

      final result = await repository.uploadAvatar(fileName: 'avatar.png', fileBytes: List.filled(10, 0));

      expect(result, const Left('File too large'));
    });
  });

  group('checkAuthStatus', () {
    test('returns Left("No token found") when token is null', () async {
      when(() => mockSecureStorage.getAccessToken()).thenAnswer((_) async => null);
      when(() => mockSecureStorage.clearTokens()).thenAnswer((_) async {});

      final result = await repository.checkAuthStatus();

      expect(result, const Left('No token found'));
      // Note: current implementation's catch-all wraps the "No token found"
      // path too, since it's thrown/caught within the same try block.
    });

    test('returns Left("Session expired") and clears tokens when token is expired', () async {
      final expiredToken = buildFakeJwt(exp: DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000);
      when(() => mockSecureStorage.getAccessToken()).thenAnswer((_) async => expiredToken);
      when(() => mockSecureStorage.clearTokens()).thenAnswer((_) async {});

      final result = await repository.checkAuthStatus();

      expect(result, const Left('Session expired'));
      verify(() => mockSecureStorage.clearTokens()).called(greaterThanOrEqualTo(1));
    });

    test('returns Right(UserEntity) from cached user JSON when token is valid', () async {
      final validToken = buildFakeJwt(exp: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000);
      when(() => mockSecureStorage.getAccessToken()).thenAnswer((_) async => validToken);
      when(() => mockSecureStorage.getUserJson()).thenAnswer((_) async => json.encode(sampleUserJson()));

      final result = await repository.checkAuthStatus();

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('expected Right, got Left($l)'),
        (user) => expect(user.email, 'jane@example.com'),
      );
      verifyNever(() => mockDio.get(AuthEndpoints.me));
    });

    test('falls back to API when no cached user JSON exists', () async {
      final validToken = buildFakeJwt(exp: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000);
      when(() => mockSecureStorage.getAccessToken()).thenAnswer((_) async => validToken);
      when(() => mockSecureStorage.getUserJson()).thenAnswer((_) async => null);
      when(() => mockDio.get(AuthEndpoints.me)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: AuthEndpoints.me),
          statusCode: 200,
          data: {'user': sampleUserJson()},
        ),
      );

      final result = await repository.checkAuthStatus();

      expect(result.isRight(), true);
      verify(() => mockDio.get(AuthEndpoints.me)).called(1);
    });

    test('returns Left("Session expired") and clears tokens when API call fails', () async {
      final validToken = buildFakeJwt(exp: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000);
      when(() => mockSecureStorage.getAccessToken()).thenAnswer((_) async => validToken);
      when(() => mockSecureStorage.getUserJson()).thenAnswer((_) async => null);
      when(() => mockDio.get(AuthEndpoints.me)).thenThrow(dioError(statusCode: 401));
      when(() => mockSecureStorage.clearTokens()).thenAnswer((_) async {});

      final result = await repository.checkAuthStatus();

      expect(result, const Left('Session expired'));
      verify(() => mockSecureStorage.clearTokens()).called(1);
    });

    test('treats a malformed token (not 3 parts) as expired', () async {
      when(() => mockSecureStorage.getAccessToken()).thenAnswer((_) async => 'not-a-real-jwt');
      when(() => mockSecureStorage.clearTokens()).thenAnswer((_) async {});

      final result = await repository.checkAuthStatus();

      expect(result, const Left('Session expired'));
    });
  });
}