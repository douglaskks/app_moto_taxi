// Arquivo: lib/blocs/auth/auth_state.dart
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String userId;
  final String userType; // 'passenger', 'driver', 'admin'

  const Authenticated(this.userId, this.userType);

  @override
  List<Object> get props => [userId, userType];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}