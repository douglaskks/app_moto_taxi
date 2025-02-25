// lib/controllers/bloc/admin/user_management_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/admin/user_management.dart';
import '../../../core/services/admin/admin_service.dart';

// Events
abstract class UserManagementEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUsers extends UserManagementEvent {}
class LoadMoreUsers extends UserManagementEvent {}

class FilterUsers extends UserManagementEvent {
  final String? role;
  final String? status;
  final String? searchQuery;
  
  FilterUsers({
    this.role,
    this.status,
    this.searchQuery,
  });
  
  @override
  List<Object?> get props => [role, status, searchQuery];
}

class UpdateUserStatus extends UserManagementEvent {
  final String userId;
  final String status;
  
  UpdateUserStatus({
    required this.userId,
    required this.status,
  });
  
  @override
  List<Object?> get props => [userId, status];
}

// States
abstract class UserManagementState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserManagementInitial extends UserManagementState {}
class UserManagementLoading extends UserManagementState {}

class UserManagementLoaded extends UserManagementState {
  final List<UserDetails> users;
  final bool hasMore;
  final String? lastUserId;
  final String? role;
  final String? status;
  final String? searchQuery;
  
  UserManagementLoaded({
    required this.users,
    this.hasMore = false,
    this.lastUserId,
    this.role,
    this.status,
    this.searchQuery,
  });
  
  @override
  List<Object?> get props => [users, hasMore, lastUserId, role, status, searchQuery];
  
  UserManagementLoaded copyWith({
    List<UserDetails>? users,
    bool? hasMore,
    String? lastUserId,
    String? role,
    String? status,
    String? searchQuery,
  }) {
    return UserManagementLoaded(
      users: users ?? this.users,
      hasMore: hasMore ?? this.hasMore,
      lastUserId: lastUserId ?? this.lastUserId,
      role: role ?? this.role,
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class UserManagementError extends UserManagementState {
  final String message;
  
  UserManagementError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class UserManagementBloc extends Bloc<UserManagementEvent, UserManagementState> {
  final AdminService _adminService = AdminService();
  
  UserManagementBloc() : super(UserManagementInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<LoadMoreUsers>(_onLoadMoreUsers);
    on<FilterUsers>(_onFilterUsers);
    on<UpdateUserStatus>(_onUpdateUserStatus);
  }
  
  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    try {
      final users = await _adminService.getUsers();
      emit(UserManagementLoaded(
        users: users,
        hasMore: users.length >= 20,
        lastUserId: users.isNotEmpty ? users.last.id : null,
      ));
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }
  
  Future<void> _onLoadMoreUsers(
    LoadMoreUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    final currentState = state;
    if (currentState is UserManagementLoaded) {
      try {
        final newUsers = await _adminService.getUsers(
          role: currentState.role,
          status: currentState.status,
          lastUserId: currentState.lastUserId,
        );
        
        emit(currentState.copyWith(
          users: [...currentState.users, ...newUsers],
          hasMore: newUsers.length >= 20,
          lastUserId: newUsers.isNotEmpty ? newUsers.last.id : currentState.lastUserId,
        ));
      } catch (e) {
        emit(UserManagementError(e.toString()));
      }
    }
  }
  
  Future<void> _onFilterUsers(
    FilterUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    try {
      final users = await _adminService.getUsers(
        role: event.role,
        status: event.status,
      );
      
      emit(UserManagementLoaded(
        users: users,
        hasMore: users.length >= 20,
        lastUserId: users.isNotEmpty ? users.last.id : null,
        role: event.role,
        status: event.status,
        searchQuery: event.searchQuery,
      ));
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }
  
  Future<void> _onUpdateUserStatus(
    UpdateUserStatus event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      await _adminService.updateUserStatus(event.userId, event.status);
      
      final currentState = state;
      if (currentState is UserManagementLoaded) {
        final updatedUsers = currentState.users.map((user) {
          if (user.id == event.userId) {
            // Criar uma cópia do usuário com o status atualizado
            // Esta é uma solução temporária já que não temos a implementação completa
            final updatedUser = UserDetails(
              id: user.id,
              name: user.name,
              email: user.email,
              role: user.role,
              status: event.status,
              registrationDate: user.registrationDate,
              stats: user.stats,
              profile: user.profile,
            );
            return updatedUser;
          }
          return user;
        }).toList();
        
        emit(currentState.copyWith(users: updatedUsers));
      }
    } catch (e) {
      // Não emitir estado de erro para não perder o estado atual
      // Mostrar mensagem de erro via SnackBar ou outro mecanismo
    }
  }
}