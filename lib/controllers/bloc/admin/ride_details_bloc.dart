// lib/controllers/bloc/admin/ride_details_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/admin/ride_management.dart';
import '../../../core/services/admin/admin_service.dart';

// Events
abstract class RideDetailsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadRideDetails extends RideDetailsEvent {
  final String rideId;
  
  LoadRideDetails(this.rideId);
  
  @override
  List<Object?> get props => [rideId];
}

class CancelRide extends RideDetailsEvent {
  final String reason;
  
  CancelRide(this.reason);
  
  @override
  List<Object?> get props => [reason];
}

// States
abstract class RideDetailsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RideDetailsInitial extends RideDetailsState {}
class RideDetailsLoading extends RideDetailsState {}

class RideDetailsLoaded extends RideDetailsState {
  final RideDetailsFull ride;
  
  RideDetailsLoaded(this.ride);
  
  @override
  List<Object?> get props => [ride];
}

class RideDetailsError extends RideDetailsState {
  final String message;
  
  RideDetailsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class RideDetailsBloc extends Bloc<RideDetailsEvent, RideDetailsState> {
  final AdminService _adminService = AdminService();
  String? _rideId;
  
  RideDetailsBloc() : super(RideDetailsInitial()) {
    on<LoadRideDetails>(_onLoadRideDetails);
    on<CancelRide>(_onCancelRide);
  }
  
  Future<void> _onLoadRideDetails(
    LoadRideDetails event,
    Emitter<RideDetailsState> emit,
  ) async {
    emit(RideDetailsLoading());
    try {
      _rideId = event.rideId;
      final ride = await _adminService.getRideDetails(event.rideId);
      emit(RideDetailsLoaded(ride));
    } catch (e) {
      emit(RideDetailsError(e.toString()));
    }
  }
  
  Future<void> _onCancelRide(
    CancelRide event,
    Emitter<RideDetailsState> emit,
  ) async {
    if (_rideId == null) return;
    
    final currentState = state;
    if (currentState is RideDetailsLoaded) {
      try {
        await _adminService.cancelRide(_rideId!, event.reason);
        // Recarregar os detalhes após o cancelamento
        add(LoadRideDetails(_rideId!));
      } catch (e) {
        emit(RideDetailsError(e.toString()));
      }
    }
  }
}