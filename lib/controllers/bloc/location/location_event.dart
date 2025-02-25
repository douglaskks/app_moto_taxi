// Arquivo: lib/controllers/bloc/location/location_event.dart
import 'package:equatable/equatable.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object> get props => [];
}

class LoadCurrentLocation extends LocationEvent {}

class LocationPermissionRequested extends LocationEvent {}

class LocationUpdated extends LocationEvent {
  final double latitude;
  final double longitude;

  const LocationUpdated(this.latitude, this.longitude);

  @override
  List<Object> get props => [latitude, longitude];
}

class SetDestination extends LocationEvent {
  final String destinationAddress;
  final double? latitude;
  final double? longitude;

  const SetDestination(this.destinationAddress, {this.latitude, this.longitude});

  @override
  List<Object> get props => [
        destinationAddress,
        if (latitude != null) latitude!,
        if (longitude != null) longitude!,
      ];
}

class ClearDestination extends LocationEvent {}