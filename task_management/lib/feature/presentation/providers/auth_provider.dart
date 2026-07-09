import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/i_repositories/i_auth_repository.dart';
import '../../../core/di/injection_container.dart' as di;

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return di.sl<IAuthRepository>();
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
  final IAuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.login(email, password);
    
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
    
    final result = await _repository.register(fullName, email, password);
    
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
    await _repository.logout();
    state = AuthState();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
