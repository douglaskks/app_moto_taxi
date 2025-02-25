// lib/controllers/bloc/admin/ride_management_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/admin/ride_management.dart';
import '../../../core/services/admin/admin_service.dart';

// Events
abstract class RideManagementEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadRides extends RideManagementEvent {}
class LoadMoreRides extends RideManagementEvent {}

class FilterRides extends RideManagementEvent {
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  
  FilterRides({
    this.status,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });
  
  @override
  List<Object?> get props => [status, startDate, endDate, searchQuery];
}

// States
abstract class RideManagementState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RideManagementInitial extends RideManagementState {}
class RideManagementLoading extends RideManagementState {}

class RideManagementLoaded extends RideManagementState {
  final List<RideDetails> rides;
  final bool hasMore;
  final String? lastRideId;
  final String? statusFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  
  RideManagementLoaded({
    required this.rides,
    this.hasMore = false,
    this.lastRideId,
    this.statusFilter,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });
  
  @override
  List<Object?> get props => [
    rides,
    hasMore,
    lastRideId,
    statusFilter,
    startDate,
    endDate,
    searchQuery,
  ];
  
  RideManagementLoaded copyWith({
    List<RideDetails>? rides,
    bool? hasMore,
    String? lastRideId,
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    return RideManagementLoaded(
      rides: rides ?? this.rides,
      hasMore: hasMore ?? this.hasMore,
      lastRideId: lastRideId ?? this.lastRideId,
      statusFilter: statusFilter ?? this.statusFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class RideManagementError extends RideManagementState {
  final String message;
  
  RideManagementError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class RideManagementBloc extends Bloc<RideManagementEvent, RideManagementState> {
  final AdminService _adminService = AdminService();
  
  RideManagementBloc() : super(RideManagementInitial()) {
    on<LoadRides>(_onLoadRides);
    on<LoadMoreRides>(_onLoadMoreRides);
    on<FilterRides>(_onFilterRides);
  }
  
  Future<void> _onLoadRides(
    LoadRides event,
    Emitter<RideManagementState> emit,
  ) async {
    emit(RideManagementLoading());
    try {
      final rides = await _adminService.getRides();
      emit(RideManagementLoaded(
        rides: rides,
        hasMore: rides.length >= 20,
        lastRideId: rides.isNotEmpty ? rides.last.id : null,
      ));
    } catch (e) {
      emit(RideManagementError(e.toString()));
    }
  }
  
  Future<void> _onLoadMoreRides(
    LoadMoreRides event,
    Emitter<RideManagementState> emit,
  ) async {
    final currentState = state;
    if (currentState is RideManagementLoaded) {
      try {
        final newRides = await _adminService.getRides(
          status: currentState.statusFilter,
          startDate: currentState.startDate,
          endDate: currentState.endDate,
          lastRideId: currentState.lastRideId,
        );
        
        emit(currentState.copyWith(
          rides: [...currentState.rides, ...newRides],
          hasMore: newRides.length >= 20,
          lastRideId: newRides.isNotEmpty ? newRides.last.id : currentState.lastRideId,
        ));
      } catch (e) {
        emit(RideManagementError(e.toString()));
      }
    }
  }
  
  Future<void> _onFilterRides(
    FilterRides event,
    Emitter<RideManagementState> emit,
  ) async {
    emit(RideManagementLoading());
    try {
      final rides = await _adminService.getRides(
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        searchQuery: event.searchQuery,
      );
      
      emit(RideManagementLoaded(
        rides: rides,
        hasMore: rides.length >= 20,
        lastRideId: rides.isNotEmpty ? rides.last.id : null,
        statusFilter: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        searchQuery: event.searchQuery,
      ));
    } catch (e) {
      emit(RideManagementError(e.toString()));
    }
  }
}