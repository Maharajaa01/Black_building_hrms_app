import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_user.dart';

/// Top-level auth state. Watched by the router to redirect.
class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  const AuthState.initial() : this(status: AuthStatus.unknown);

  AuthState copyWith({AuthStatus? status, AuthUser? user, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

enum AuthStatus { unknown, unauthenticated, authenticating, authenticated, error }

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState.initial()) {
    _bootstrap();
  }

  final AuthRepository _repo;

  Future<void> _bootstrap() async {
    final hasSession = await _repo.hasSession();
    if (!hasSession) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repo.fetchCurrentUser();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on ApiException catch (e) {
      // Session no longer valid — drop it and show login.
      await _repo.logout();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.isUnauthorized ? null : e.message,
      );
    }
  }

  Future<void> login({
    required String usr,
    required String pwd,
    required bool remember,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final user = await _repo.login(usr: usr, pwd: pwd, remember: remember);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on ApiException catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.message);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<String?> get savedUsername => _repo.rememberedUsername;
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

/// Convenience selector for the current user.
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});
