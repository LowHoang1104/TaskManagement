import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../application/i_services/i_auth_service.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../data/datasources/remote/signalr_service.dart';

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
        di.sl<SignalRService>().startConnection();
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
        di.sl<SignalRService>().startConnection();
        return true;
      },
    );
  }

  Future<bool> googleLogin() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.googleLogin();
    
    return result.fold(
      (error) {
        state = AuthState(isLoading: false, error: error);
        return false;
      },
      (user) {
        state = AuthState(isLoading: false, user: user);
        di.sl<SignalRService>().startConnection();
        return true;
      },
    );
  }

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.sendOtp(email);
    
    return result.fold(
      (error) {
        state = AuthState(isLoading: false, error: error);
        return false;
      },
      (_) {
        state = AuthState(isLoading: false, user: state.user);
        return true;
      },
    );
  }

  Future<bool> verifyOtpAndRegister(String email, String otp, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.verifyOtpAndRegister(email, otp, password, fullName);
    
    return result.fold(
      (error) {
        state = AuthState(isLoading: false, error: error);
        return false;
      },
      (user) {
        state = AuthState(isLoading: false, user: user);
        di.sl<SignalRService>().startConnection();
        return true;
      },
    );
  }

  Future<void> logout() async {
    await _service.logout();
    await di.sl<SignalRService>().stopConnection();
    state = AuthState();
  }

  Future<bool> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _service.checkAuthStatus();
      
      return result.fold(
        (error) {
          state = AuthState(isLoading: false, error: error);
          return false;
        },
        (user) {
          state = AuthState(isLoading: false, user: user);
          try {
            di.sl<SignalRService>().startConnection();
          } catch (_) {} // ignore signalR errors on start
          return true;
        },
      );
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
      return false;
    }
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

  Future<bool> uploadAvatar({required String fileName, required List<int> fileBytes}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.uploadAvatar(fileName: fileName, fileBytes: fileBytes);
    
    return result.fold(
      (error) {
        state = AuthState(isLoading: false, error: error, user: state.user);
        return false;
      },
      (user) {
        state = AuthState(isLoading: false, user: user);
        return true;
      },
    );
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _service.forgotPassword(email);
    
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _service.resetPassword(email, otp, newPassword);
    
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
