// Arquivo: lib/blocs/auth/auth_bloc.dart
import 'package:app_moto_taxe/core/services/auth_service.dart';
import 'package:app_moto_taxe/core/services/notification_service.dart';
import 'package:app_moto_taxe/models/user_models.dart';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  
  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
    on<SwitchUserType>(_onSwitchUserType);
  }

  void _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      final User? currentUser = _authService.getCurrentUser();
      
      if (currentUser != null) {
        final UserModel userModel = await _authService.getUserProfile(currentUser.uid);
        emit(Authenticated(currentUser.uid, userModel.userType));
      } else {
        emit(Unauthenticated());
      }
    } catch (error) {
      emit(Unauthenticated());
    }
  }

  void _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) {
    emit(Authenticated(event.userId, event.userType));
  }

  void _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
  try {
    // Obter o ID do usuário atual antes de fazer logout
    final String? userId = _authService.getCurrentUser()?.uid;
    
    // Fazer logout
    await _authService.signOut();
    
    // Se houver um ID de usuário, remover o token FCM
    if (userId != null) {
      await NotificationService().removeTokenFromDatabase(userId);
    }
    
    emit(Unauthenticated());
  } catch (error) {
    emit(AuthError('Falha ao sair. Tente novamente.'));
  }
}

  void _onSwitchUserType(SwitchUserType event, Emitter<AuthState> emit) async {
    if (state is Authenticated) {
      final currentState = state as Authenticated;
      try {
        await _authService.updateUserType(currentState.userId, event.userType);
        emit(Authenticated(currentState.userId, event.userType));
      } catch (error) {
        emit(AuthError('Falha ao mudar perfil. Tente novamente.'));
      }
    }
  }
}