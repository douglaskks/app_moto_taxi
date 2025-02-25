// Arquivo: lib/controllers/bloc/driver_location/driver_location_state.dart
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class DriverLocationState extends Equatable {
  const DriverLocationState();
  
  @override
  List<Object> get props => [];
}

class DriverLocationInitial extends DriverLocationState {}

class DriverLocationLoading extends DriverLocationState {}

class DriverLocationsLoaded extends DriverLocationState {
  final List<Map<String, dynamic>> nearbyDrivers;
  final Map<String, Marker> driverMarkers;
  
  const DriverLocationsLoaded({
    required this.nearbyDrivers,
    required this.driverMarkers,
  });
  
  @override
  List<Object> get props => [nearbyDrivers, driverMarkers];
  
  DriverLocationsLoaded copyWith({
    List<Map<String, dynamic>>? nearbyDrivers,
    Map<String, Marker>? driverMarkers,
  }) {
    return DriverLocationsLoaded(
      nearbyDrivers: nearbyDrivers ?? this.nearbyDrivers,
      driverMarkers: driverMarkers ?? this.driverMarkers,
    );
  }
}

class TrackingDriverLocation extends DriverLocationState {
  final String driverId;
  final LatLng? driverLocation;
  final double? distanceToDriver;
  final double? estimatedArrivalTime;
  
  const TrackingDriverLocation({
    required this.driverId,
    this.driverLocation,
    this.distanceToDriver,
    this.estimatedArrivalTime,
  });
  
  @override
  List<Object> get props => [
    driverId,
    if (driverLocation != null) driverLocation!,
    if (distanceToDriver != null) distanceToDriver!,
    if (estimatedArrivalTime != null) estimatedArrivalTime!,
  ];
  
  TrackingDriverLocation copyWith({
    String? driverId,
    LatLng? driverLocation,
    double? distanceToDriver,
    double? estimatedArrivalTime,
  }) {
    return TrackingDriverLocation(
      driverId: driverId ?? this.driverId,
      driverLocation: driverLocation ?? this.driverLocation,
      distanceToDriver: distanceToDriver ?? this.distanceToDriver,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
    );
  }
}

class DriverLocationError extends DriverLocationState {
  final String message;
  
  const DriverLocationError(this.message);
  
  @override
  List<Object> get props => [message];
}