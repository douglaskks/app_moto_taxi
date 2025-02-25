// Arquivo: lib/controllers/bloc/location/location_state.dart
import 'package:equatable/equatable.dart';

abstract class LocationState extends Equatable {
  const LocationState();
  
  @override
  List<Object> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationPermissionDenied extends LocationState {
  final String message;

  const LocationPermissionDenied(this.message);

  @override
  List<Object> get props => [message];
}

class LocationLoaded extends LocationState {
  final double currentLatitude;
  final double currentLongitude;
  final String? currentAddress;
  final String? destinationAddress;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final double? distance;
  final double? duration;
  final double? estimatedPrice;

  const LocationLoaded({
    required this.currentLatitude,
    required this.currentLongitude,
    this.currentAddress,
    this.destinationAddress,
    this.destinationLatitude,
    this.destinationLongitude,
    this.distance,
    this.duration,
    this.estimatedPrice,
  });

  LocationLoaded copyWith({
    double? currentLatitude,
    double? currentLongitude,
    String? currentAddress,
    String? destinationAddress,
    double? destinationLatitude,
    double? destinationLongitude,
    double? distance,
    double? duration,
    double? estimatedPrice,
  }) {
    return LocationLoaded(
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      currentAddress: currentAddress ?? this.currentAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
    );
  }

  @override
  List<Object> get props => [
        currentLatitude,
        currentLongitude,
        if (currentAddress != null) currentAddress!,
        if (destinationAddress != null) destinationAddress!,
        if (destinationLatitude != null) destinationLatitude!,
        if (destinationLongitude != null) destinationLongitude!,
        if (distance != null) distance!,
        if (duration != null) duration!,
        if (estimatedPrice != null) estimatedPrice!,
      ];
}

class LocationError extends LocationState {
  final String message;

  const LocationError(this.message);

  @override
  List<Object> get props => [message];
}
