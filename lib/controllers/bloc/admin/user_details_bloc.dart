// lib/controllers/bloc/admin/user_details_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/admin/user_management.dart';
import '../../../core/services/admin/admin_service.dart';

// Events
abstract class UserDetailsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUserDetails extends UserDetailsEvent {
  final String userId;
  
  LoadUserDetails(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

class UpdateUserStatus extends UserDetailsEvent {
  final String status;
  
  UpdateUserStatus(this.status);
  
  @override
  List<Object?> get props => [status];
}

// States
abstract class UserDetailsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserDetailsInitial extends UserDetailsState {}
class UserDetailsLoading extends UserDetailsState {}

class UserDetailsLoaded extends UserDetailsState {
  final UserDetails user;
  
  UserDetailsLoaded(this.user);
  
  @override
  List<Object?> get props => [user];
}

class UserDetailsError extends UserDetailsState {
  final String message;
  
  UserDetailsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class UserDetailsBloc extends Bloc<UserDetailsEvent, UserDetailsState> {
  final AdminService _adminService = AdminService();
  String? _userId;
  
  UserDetailsBloc() : super(UserDetailsInitial()) {
    on<LoadUserDetails>(_onLoadUserDetails);
    on<UpdateUserStatus>(_onUpdateUserStatus);
  }
  
  Future<void> _onLoadUserDetails(
    LoadUserDetails event,
    Emitter<UserDetailsState> emit,
  ) async {
    emit(UserDetailsLoading());
    try {
      _userId = event.userId;
      final user = await _adminService.getUserDetails(event.userId);
      emit(UserDetailsLoaded(user));
    } catch (e) {
      emit(UserDetailsError(e.toString()));
    }
  }
  
  Future<void> _onUpdateUserStatus(
    UpdateUserStatus event,
    Emitter<UserDetailsState> emit,
  ) async {
    if (_userId == null) return;
    
    final currentState = state;
    if (currentState is UserDetailsLoaded) {
      try {
        await _adminService.updateUserStatus(_userId!, event.status);
        
        // Criar cópia do usuário com o status atualizado
        final updatedUser = UserDetails(
          id: currentState.user.id,
          name: currentState.user.name,
          email: currentState.user.email,
          role: currentState.user.role,
          status: event.status,
          registrationDate: currentState.user.registrationDate,
          stats: currentState.user.stats,
          profile: currentState.user.profile,
        );
        
        emit(UserDetailsLoaded(updatedUser));
      } catch (e) {
        // Você pode optar por emitir um estado de erro ou
        // manter o estado atual e mostrar um SnackBar
      }
    }
  }
}