import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/entities/user_entity.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  @override List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String emailOrUsername;
  final String password;
  LoginRequested({required this.emailOrUsername, required this.password});
  @override List<Object?> get props => [emailOrUsername, password];
}

class RegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String phoneNumber;
  final int age;
  RegisterRequested({
    required this.username, required this.email, required this.password,
    required this.phoneNumber, required this.age,
  });
}

class VerifyEmailRequested extends AuthEvent {
  final String email;
  final String code;
  VerifyEmailRequested({required this.email, required this.code});
}

class LogoutRequested extends AuthEvent {}
class GoogleSignInRequested extends AuthEvent {}
class AppleSignInRequested extends AuthEvent {}
class TokenRefreshRequested extends AuthEvent {}

// ── States ────────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  @override List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  AuthAuthenticated(this.user);
  @override List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override List<Object?> get props => [message];
}

class AuthEmailVerificationRequired extends AuthState {
  final String email;
  AuthEmailVerificationRequired(this.email);
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
  }) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<VerifyEmailRequested>(_onVerifyEmail);
    on<LogoutRequested>(_onLogout);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<AppleSignInRequested>(_onAppleSignIn);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      final user = await loginUseCase.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await loginUseCase(LoginParams(
        emailOrUsername: event.emailOrUsername,
        password: event.password,
      ));
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(AuthAuthenticated(user)),
      );
    } catch (e) {
      emit(AuthError('An unexpected error occurred'));
    }
  }

  Future<void> _onRegisterRequested(
      RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await registerUseCase(RegisterParams(
        username: event.username,
        email: event.email,
        password: event.password,
        phoneNumber: event.phoneNumber,
        age: event.age,
      ));
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) => emit(AuthEmailVerificationRequired(event.email)),
      );
    } catch (e) {
      emit(AuthError('Registration failed'));
    }
  }

  Future<void> _onVerifyEmail(
      VerifyEmailRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await loginUseCase.verifyEmail(event.email, event.code);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(AuthAuthenticated(user)),
      );
    } catch (e) {
      emit(AuthError('Verification failed'));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await logoutUseCase();
    emit(AuthUnauthenticated());
  }

  Future<void> _onGoogleSignIn(
      GoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    // TODO: Implement Google Sign-In flow
    emit(AuthError('Google Sign-In coming soon'));
  }

  Future<void> _onAppleSignIn(
      AppleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    // TODO: Implement Apple Sign-In flow
    emit(AuthError('Apple Sign-In coming soon'));
  }
}
