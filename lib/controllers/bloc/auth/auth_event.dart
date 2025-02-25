// Arquivo: lib/blocs/auth/auth_event.dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final String userId;
  final String userType; // 'passenger', 'driver', 'admin'

  const LoggedIn(this.userId, this.userType);

  @override
  List<Object> get props => [userId, userType];
}

class LoggedOut extends AuthEvent {}

class SwitchUserType extends AuthEvent {
  final String userType; // 'passenger', 'driver'

  const SwitchUserType(this.userType);

  @override
  List<Object> get props => [userType];
}

