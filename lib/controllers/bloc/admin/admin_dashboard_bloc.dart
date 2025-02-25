// lib/controllers/bloc/admin/admin_dashboard_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/admin/dashboard_stats.dart';
import '../../../core/services/admin/admin_service.dart';

// Events
abstract class AdminDashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDashboardStats extends AdminDashboardEvent {}
class RefreshDashboardStats extends AdminDashboardEvent {}

// States
abstract class AdminDashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}
class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final DashboardStats stats;
  
  AdminDashboardLoaded(this.stats);
  
  @override
  List<Object?> get props => [stats];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  
  AdminDashboardError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class AdminDashboardBloc extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminService _adminService = AdminService();
  
  AdminDashboardBloc() : super(AdminDashboardInitial()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
    on<RefreshDashboardStats>(_onRefreshDashboardStats);
  }
  
  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(AdminDashboardLoading());
    try {
      final stats = await _adminService.getDashboardStats();
      emit(AdminDashboardLoaded(stats));
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }
  
  Future<void> _onRefreshDashboardStats(
    RefreshDashboardStats event,
    Emitter<AdminDashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminDashboardLoaded) {
      emit(AdminDashboardLoading());
      try {
        final stats = await _adminService.getDashboardStats();
        emit(AdminDashboardLoaded(stats));
      } catch (e) {
        emit(AdminDashboardError(e.toString()));
      }
    }
  }
}