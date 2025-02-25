// Arquivo: lib/controllers/bloc/driver_location/driver_location_event.dart
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class DriverLocationEvent extends Equatable {
  const DriverLocationEvent();

  @override
  List<Object> get props => [];
}

class FetchNearbyDrivers extends DriverLocationEvent {
  final double latitude;
  final double longitude;
  final double radius;

  const FetchNearbyDrivers({
    required this.latitude,
    required this.longitude,
    this.radius = 5.0, // 5km por padrão
  });

  @override
  List<Object> get props => [latitude, longitude, radius];
}

class StopFetchingDrivers extends DriverLocationEvent {}

class UpdateDriverLocation extends DriverLocationEvent {
  final String driverId;
  final LatLng location;

  const UpdateDriverLocation({
    required this.driverId,
    required this.location,
  });

  @override
  List<Object> get props => [driverId, location];
}

class BeginTrackingDriver extends DriverLocationEvent {
  final String driverId;

  const BeginTrackingDriver(this.driverId);

  @override
  List<Object> get props => [driverId];
}

class StopTrackingDriver extends DriverLocationEvent {
  final String driverId;

  const StopTrackingDriver(this.driverId);

  @override
  List<Object> get props => [driverId];
}