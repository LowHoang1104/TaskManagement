import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_management/feature/application/i_services/i_auth_service.dart';
import 'package:task_management/feature/data/datasources/remote/signalr_service.dart';
import 'package:task_management/feature/domain/entities/user_entity.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';

class MockAuthService extends Mock implements IAuthService {}

class MockSignalRService extends Mock implements SignalRService {}

void main() {
  late MockAuthService mockAuthService;
  late MockSignalRService mockSignalRService;
  late AuthNotifier notifier;

  final testUser = UserEntity(
    id: '1',
    fullName: 'Jane Doe',
    email: 'jane@example.com',
    passwordHash: '',
    avatarUrl: null,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  setUp(() {
    mockAuthService = MockAuthService();
    mockSignalRService = MockSignalRService();

    // Register the mock SignalRService into GetIt so `di.sl<SignalRService>()`
    // resolves to our mock inside AuthNotifier's methods.
    GetIt.instance.registerLazySingleton<SignalRService>(() => mockSignalRService);

    when(() => mockSignalRService.startConnection()).thenAnswer((_) async {});
    when(() => mockSignalRService.stopConnection()).thenAnswer((_) async {});

    notifier = AuthNotifier(mockAuthService);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('AuthState.copyWith', () {
    test('overwrites error with null when not explicitly passed', () {
      final original = AuthState(isLoading: false, error: 'some error', user: null);
      final copy = original.copyWith(isLoading: true);

      // Known behavior per the inline comment in the source:
      // error is NOT preserved via `?? this.error`, it's always overwritten,
      // so omitting it resets it to null.
      expect(copy.error, isNull);
      expect(copy.isLoading, true);
    });

    test('preserves user when not explicitly passed', () {
      final original = AuthState(user: testUser);
      final copy = original.copyWith(isLoading: true);

      expect(copy.user, testUser);
    });

    test('sets error explicitly when passed', () {
      final original = AuthState();
      final copy = original.copyWith(error: 'new error');

      expect(copy.error, 'new error');
    });

    test('overrides user when explicitly passed', () {
      final newUser = testUser.copyWith
          is Function // no-op guard in case UserEntity lacks copyWith; harmless
          ? testUser
          : testUser;
      final original = AuthState(user: testUser);
      final otherUser = UserEntity(
        id: '2',
        fullName: 'John Smith',
        email: 'john@example.com',
        passwordHash: '',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final copy = original.copyWith(user: otherUser);

      expect(copy.user, otherUser);
    });
  });

  group('login', () {
    test('sets isLoading true then success state and starts SignalR on success', () async {
      when(() => mockAuthService.login(any(), any())).thenAnswer((_) async => Right(testUser));

      final success = await notifier.login('jane@example.com', 'password123');

      expect(success, true);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.user, testUser);
      expect(notifier.state.error, isNull);
      verify(() => mockSignalRService.startConnection()).called(1);
    });

    test('sets error state and does not start SignalR on failure', () async {
      when(() => mockAuthService.login(any(), any())).thenAnswer((_) async => const Left('Invalid credentials'));

      final success = await notifier.login('jane@example.com', 'wrongpass');

      expect(success, false);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Invalid credentials');
      expect(notifier.state.user, isNull);
      verifyNever(() => mockSignalRService.startConnection());
    });

    test('passes correct email and password to the service', () async {
      when(() => mockAuthService.login(any(), any())).thenAnswer((_) async => Right(testUser));

      await notifier.login('jane@example.com', 'password123');

      verify(() => mockAuthService.login('jane@example.com', 'password123')).called(1);
    });
  });

  group('register', () {
    test('sets success state and starts SignalR on success', () async {
      when(() => mockAuthService.register(any(), any(), any())).thenAnswer((_) async => Right(testUser));

      final success = await notifier.register('Jane Doe', 'jane@example.com', 'password123');

      expect(success, true);
      expect(notifier.state.user, testUser);
      verify(() => mockSignalRService.startConnection()).called(1);
    });

    test('sets error state on failure', () async {
      when(() => mockAuthService.register(any(), any(), any()))
          .thenAnswer((_) async => const Left('Email already exists'));

      final success = await notifier.register('Jane Doe', 'jane@example.com', 'password123');

      expect(success, false);
      expect(notifier.state.error, 'Email already exists');
      verifyNever(() => mockSignalRService.startConnection());
    });
  });

  group('googleLogin', () {
    test('sets success state and starts SignalR on success', () async {
      when(() => mockAuthService.googleLogin()).thenAnswer((_) async => Right(testUser));

      final success = await notifier.googleLogin();

      expect(success, true);
      expect(notifier.state.user, testUser);
      verify(() => mockSignalRService.startConnection()).called(1);
    });

    test('sets error state on failure', () async {
      when(() => mockAuthService.googleLogin()).thenAnswer((_) async => const Left('Google Login failed'));

      final success = await notifier.googleLogin();

      expect(success, false);
      expect(notifier.state.error, 'Google Login failed');
    });
  });

  group('sendOtp', () {
    test('keeps existing user and returns true on success', () async {
      // Simulate a user already logged in before sending OTP for some flow
      notifier.state = AuthState(user: testUser);
      when(() => mockAuthService.sendOtp(any())).thenAnswer((_) async => const Right(null));

      final success = await notifier.sendOtp('jane@example.com');

      expect(success, true);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.user, testUser); // preserved via state.user
      verifyNever(() => mockSignalRService.startConnection());
    });

    test('sets error state on failure', () async {
      when(() => mockAuthService.sendOtp(any())).thenAnswer((_) async => const Left('Invalid email'));

      final success = await notifier.sendOtp('bad-email');

      expect(success, false);
      expect(notifier.state.error, 'Invalid email');
    });
  });

  group('verifyOtpAndRegister', () {
    test('sets success state and starts SignalR on success', () async {
      when(() => mockAuthService.verifyOtpAndRegister(any(), any(), any(), any()))
          .thenAnswer((_) async => Right(testUser));

      final success = await notifier.verifyOtpAndRegister(
        'jane@example.com',
        '123456',
        'password123',
        'Jane Doe',
      );

      expect(success, true);
      expect(notifier.state.user, testUser);
      verify(() => mockSignalRService.startConnection()).called(1);
    });

    test('sets error state on invalid OTP', () async {
      when(() => mockAuthService.verifyOtpAndRegister(any(), any(), any(), any()))
          .thenAnswer((_) async => const Left('Invalid OTP'));

      final success = await notifier.verifyOtpAndRegister(
        'jane@example.com',
        '000000',
        'password123',
        'Jane Doe',
      );

      expect(success, false);
      expect(notifier.state.error, 'Invalid OTP');
    });
  });

  group('logout', () {
    test('calls service logout, stops SignalR, and resets state', () async {
      notifier.state = AuthState(user: testUser);
      when(() => mockAuthService.logout()).thenAnswer((_) async => const Right(null));

      await notifier.logout();

      verify(() => mockAuthService.logout()).called(1);
      verify(() => mockSignalRService.stopConnection()).called(1);
      expect(notifier.state.user, isNull);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('resets state to default even if service.logout() returns Left', () async {
      when(() => mockAuthService.logout()).thenAnswer((_) async => const Left('some error'));

      await notifier.logout();

      // logout() ignores the Either result entirely and always resets state.
      expect(notifier.state.user, isNull);
      expect(notifier.state.error, isNull);
      verify(() => mockSignalRService.stopConnection()).called(1);
    });
  });

  group('checkAuthStatus', () {
    test('sets success state and starts SignalR on success', () async {
      when(() => mockAuthService.checkAuthStatus()).thenAnswer((_) async => Right(testUser));

      final success = await notifier.checkAuthStatus();

      expect(success, true);
      expect(notifier.state.user, testUser);
      verify(() => mockSignalRService.startConnection()).called(1);
    });

    test('sets error state on failure ("Session expired")', () async {
      when(() => mockAuthService.checkAuthStatus()).thenAnswer((_) async => const Left('Session expired'));

      final success = await notifier.checkAuthStatus();

      expect(success, false);
      expect(notifier.state.error, 'Session expired');
      verifyNever(() => mockSignalRService.startConnection());
    });

    test('swallows SignalR startConnection errors and still returns true', () async {
      when(() => mockAuthService.checkAuthStatus()).thenAnswer((_) async => Right(testUser));
      when(() => mockSignalRService.startConnection()).thenThrow(Exception('signalR failed'));

      final success = await notifier.checkAuthStatus();

      expect(success, true); // error is caught and ignored per the inner try/catch
      expect(notifier.state.user, testUser);
    });

    test('returns false and sets error when the service itself throws', () async {
      when(() => mockAuthService.checkAuthStatus()).thenThrow(Exception('unexpected'));

      final success = await notifier.checkAuthStatus();

      expect(success, false);
      expect(notifier.state.error, contains('unexpected'));
    });
  });

  group('changePassword', () {
    test('retains current user and returns true on success', () async {
      notifier.state = AuthState(user: testUser);
      when(() => mockAuthService.changePassword(any(), any())).thenAnswer((_) async => const Right(null));

      final success = await notifier.changePassword('oldPass', 'newPass');

      expect(success, true);
      expect(notifier.state.user, testUser);
      expect(notifier.state.error, isNull);
    });

    test('retains current user and sets error on failure', () async {
      notifier.state = AuthState(user: testUser);
      when(() => mockAuthService.changePassword(any(), any()))
          .thenAnswer((_) async => const Left('Current password is incorrect'));

      final success = await notifier.changePassword('wrongPass', 'newPass');

      expect(success, false);
      expect(notifier.state.error, 'Current password is incorrect');
      expect(notifier.state.user, testUser); // user preserved even on failure
    });
  });

  group('uploadAvatar', () {
    test('updates user with new avatar on success', () async {
      final updatedUser = testUser.copyWith(avatarUrl: 'https://cdn.example.com/avatar.png');
      when(() => mockAuthService.uploadAvatar(fileName: any(named: 'fileName'), fileBytes: any(named: 'fileBytes')))
          .thenAnswer((_) async => Right(updatedUser));

      final success = await notifier.uploadAvatar(fileName: 'avatar.png', fileBytes: [1, 2, 3]);

      expect(success, true);
      expect(notifier.state.user?.avatarUrl, 'https://cdn.example.com/avatar.png');
    });

    test('retains current user and sets error on failure', () async {
      notifier.state = AuthState(user: testUser);
      when(() => mockAuthService.uploadAvatar(fileName: any(named: 'fileName'), fileBytes: any(named: 'fileBytes')))
          .thenAnswer((_) async => const Left('File too large'));

      final success = await notifier.uploadAvatar(fileName: 'avatar.png', fileBytes: List.filled(10, 0));

      expect(success, false);
      expect(notifier.state.error, 'File too large');
      expect(notifier.state.user, testUser);
    });
  });

  group('forgotPassword', () {
    test('clears loading and error on success', () async {
      when(() => mockAuthService.forgotPassword(any())).thenAnswer((_) async => const Right(null));

      final success = await notifier.forgotPassword('jane@example.com');

      expect(success, true);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('sets error state on failure', () async {
      when(() => mockAuthService.forgotPassword(any())).thenAnswer((_) async => const Left('Email not found'));

      final success = await notifier.forgotPassword('unknown@example.com');

      expect(success, false);
      expect(notifier.state.error, 'Email not found');
    });
  });

  group('resetPassword', () {
    test('clears loading and error on success', () async {
      when(() => mockAuthService.resetPassword(any(), any(), any())).thenAnswer((_) async => const Right(null));

      final success = await notifier.resetPassword('jane@example.com', '123456', 'newPassword123');

      expect(success, true);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('sets error state on invalid/expired OTP', () async {
      when(() => mockAuthService.resetPassword(any(), any(), any()))
          .thenAnswer((_) async => const Left('OTP expired'));

      final success = await notifier.resetPassword('jane@example.com', '000000', 'newPassword123');

      expect(success, false);
      expect(notifier.state.error, 'OTP expired');
    });
  });
}