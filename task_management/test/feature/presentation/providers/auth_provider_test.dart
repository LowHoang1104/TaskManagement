import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:task_management/feature/domain/entities/user_entity.dart';
import 'package:task_management/feature/application/i_services/i_auth_service.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';

class MockAuthService extends Mock implements IAuthService {}

void main() {
  late AuthNotifier authNotifier;
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    authNotifier = AuthNotifier(mockAuthService);
  });

  group('AuthNotifier - login', () {
    const tEmail = 'test@test.com';
    const tPassword = 'password';
    final tUser = UserEntity(
      id: '1',
      fullName: 'Test User',
      email: tEmail,
      passwordHash: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should emit loading then success state on successful login', () async {
      // Arrange
      when(() => mockAuthService.login(tEmail, tPassword)).thenAnswer((_) async => Right(tUser));

      // Act
      // We can't easily listen to all state changes in a single await without a listener, 
      // but we can check the final state after await.
      expect(authNotifier.state.isLoading, false);
      expect(authNotifier.state.user, null);

      final result = await authNotifier.login(tEmail, tPassword);

      // Assert
      expect(result, true);
      expect(authNotifier.state.isLoading, false);
      expect(authNotifier.state.user, tUser);
      expect(authNotifier.state.error, null);
      verify(() => mockAuthService.login(tEmail, tPassword)).called(1);
    });

    test('should emit error state when login fails', () async {
      // Arrange
      when(() => mockAuthService.login(tEmail, tPassword)).thenAnswer((_) async => const Left('Login Failed'));

      // Act
      final result = await authNotifier.login(tEmail, tPassword);

      // Assert
      expect(result, false);
      expect(authNotifier.state.isLoading, false);
      expect(authNotifier.state.user, null);
      expect(authNotifier.state.error, 'Login Failed');
      verify(() => mockAuthService.login(tEmail, tPassword)).called(1);
    });
  });

  group('AuthNotifier - register', () {
    const tFullName = 'New User';
    const tEmail = 'new@test.com';
    const tPassword = 'password';
    final tUser = UserEntity(
      id: '2',
      fullName: tFullName,
      email: tEmail,
      passwordHash: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should emit success state on successful registration', () async {
      // Arrange
      when(() => mockAuthService.register(tFullName, tEmail, tPassword)).thenAnswer((_) async => Right(tUser));

      // Act
      final result = await authNotifier.register(tFullName, tEmail, tPassword);

      // Assert
      expect(result, true);
      expect(authNotifier.state.isLoading, false);
      expect(authNotifier.state.user, tUser);
      expect(authNotifier.state.error, null);
      verify(() => mockAuthService.register(tFullName, tEmail, tPassword)).called(1);
    });

    test('should emit error state when registration fails', () async {
      // Arrange
      when(() => mockAuthService.register(tFullName, tEmail, tPassword)).thenAnswer((_) async => const Left('Email already taken'));

      // Act
      final result = await authNotifier.register(tFullName, tEmail, tPassword);

      // Assert
      expect(result, false);
      expect(authNotifier.state.isLoading, false);
      expect(authNotifier.state.user, null);
      expect(authNotifier.state.error, 'Email already taken');
      verify(() => mockAuthService.register(tFullName, tEmail, tPassword)).called(1);
    });
  });

  group('AuthNotifier - logout', () {
    test('should clear user state on logout', () async {
      // Arrange
      when(() => mockAuthService.logout()).thenAnswer((_) async => const Right(null));
      
      // Mock login so we can set a dummy state without crash
      when(() => mockAuthService.login('mock', 'mock')).thenAnswer(
        (_) async => Right(UserEntity(
          id: '1', fullName: 'Mock', email: 'mock', passwordHash: '', createdAt: DateTime.now(), updatedAt: DateTime.now()
        ))
      );
      
      await authNotifier.login('mock', 'mock');
      
      // Act
      await authNotifier.logout();

      // Assert
      expect(authNotifier.state.isLoading, false);
      expect(authNotifier.state.user, null);
      expect(authNotifier.state.error, null);
      verify(() => mockAuthService.logout()).called(1);
    });
  });
}
