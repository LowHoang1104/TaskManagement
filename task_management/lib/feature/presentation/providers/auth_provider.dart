import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../application/i_services/i_auth_service.dart';
import '../../../core/di/injection_container.dart' as di;

final authServiceProvider = Provider<IAuthService>((ref) {
  return di.sl<IAuthService>();
});

class AuthState {
  final bool isLoading;
  final String? error;
  final UserEntity? user;

  AuthState({this.isLoading = false, this.error, this.user});

  AuthState copyWith({bool? isLoading, String? error, UserEntity? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // overwrite error with null if not specified, wait no, let's use a specialized method or just passing null.
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthService _service;

  AuthNotifier(this._service) : super(AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.login(email, password);
    
    return result.fold(
      (error) {
        state = AuthState(isLoading: false, error: error);
        return false;
      },
      (user) {
        state = AuthState(isLoading: false, user: user);
        return true;
      },
    );
  }

  Future<bool> register(String fullName, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.register(fullName, email, password);
    
    return result.fold(
      (error) {
        state = AuthState(isLoading: false, error: error);
        return false;
      },
      (user) {
        state = AuthState(isLoading: false, user: user);
        return true;
      },
    );
  }

  Future<void> logout() async {
    await _service.logout();
    state = AuthState();
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.changePassword(currentPassword, newPassword);
    
    return result.fold(
      (error) {
        // Retain the current user, just update error state
        state = AuthState(isLoading: false, error: error, user: state.user);
        return false;
      },
      (_) {
        // Success, clear error
        state = AuthState(isLoading: false, user: state.user);
        return true;
      },
    );
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
