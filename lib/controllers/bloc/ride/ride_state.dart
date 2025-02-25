// Arquivo: lib/controllers/bloc/ride/ride_state.dart
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class RideState extends Equatable {
  const RideState();
  
  @override
  List<Object> get props => [];
}

class RideInitial extends RideState {}

class RequestingRide extends RideState {}

class SearchingDriver extends RideState {
  final String rideId;
  final LatLng pickup;
  final LatLng destination;
  final String pickupAddress;
  final String destinationAddress;
  final double estimatedPrice;
  final int searchTimeElapsed; // Em segundos

  const SearchingDriver({
    required this.rideId,
    required this.pickup,
    required this.destination,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.estimatedPrice,
    this.searchTimeElapsed = 0,
  });

  @override
  List<Object> get props => [
    rideId,
    pickup,
    destination,
    pickupAddress,
    destinationAddress,
    estimatedPrice,
    searchTimeElapsed,
  ];

  SearchingDriver copyWith({
    String? rideId,
    LatLng? pickup,
    LatLng? destination,
    String? pickupAddress,
    String? destinationAddress,
    double? estimatedPrice,
    int? searchTimeElapsed,
  }) {
    return SearchingDriver(
      rideId: rideId ?? this.rideId,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      searchTimeElapsed: searchTimeElapsed ?? this.searchTimeElapsed,
    );
  }
}

class DriverAccepted extends RideState {
  final String rideId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String? driverPhoto;
  final double driverRating;
  final String vehicleModel;
  final String licensePlate;
  final double estimatedArrivalTime; // Em minutos
  final LatLng pickup;
  final LatLng destination;
  final String pickupAddress;
  final String destinationAddress;
  final LatLng? driverLocation;

  const DriverAccepted({
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    this.driverPhoto,
    required this.driverRating,
    required this.vehicleModel,
    required this.licensePlate,
    required this.estimatedArrivalTime,
    required this.pickup,
    required this.destination,
    required this.pickupAddress,
    required this.destinationAddress,
    this.driverLocation,
  });

  @override
  List<Object> get props => [
    rideId,
    driverId,
    driverName,
    driverPhone,
    if (driverPhoto != null) driverPhoto!,
    driverRating,
    vehicleModel,
    licensePlate,
    estimatedArrivalTime,
    pickup,
    destination,
    pickupAddress,
    destinationAddress,
    if (driverLocation != null) driverLocation!,
  ];

  DriverAccepted copyWith({
    String? rideId,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverPhoto,
    double? driverRating,
    String? vehicleModel,
    String? licensePlate,
    double? estimatedArrivalTime,
    LatLng? pickup,
    LatLng? destination,
    String? pickupAddress,
    String? destinationAddress,
    LatLng? driverLocation,
  }) {
    return DriverAccepted(
      rideId: rideId ?? this.rideId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      driverRating: driverRating ?? this.driverRating,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      licensePlate: licensePlate ?? this.licensePlate,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      driverLocation: driverLocation ?? this.driverLocation,
    );
  }
}

class DriverArrived extends RideState {
  final String rideId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String? driverPhoto;
  final LatLng pickup;
  final LatLng destination;
  final int waitingTime; // Em segundos

  const DriverArrived({
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    this.driverPhoto,
    required this.pickup,
    required this.destination,
    this.waitingTime = 0,
  });

  @override
  List<Object> get props => [
    rideId,
    driverId,
    driverName,
    driverPhone,
    if (driverPhoto != null) driverPhoto!,
    pickup,
    destination,
    waitingTime,
  ];

  DriverArrived copyWith({
    String? rideId,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverPhoto,
    LatLng? pickup,
    LatLng? destination,
    int? waitingTime,
  }) {
    return DriverArrived(
      rideId: rideId ?? this.rideId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      waitingTime: waitingTime ?? this.waitingTime,
    );
  }
}

class RideInProgress extends RideState {
  final String rideId;
  final String driverId;
  final String driverName;
  final LatLng destination;
  final String destinationAddress;
  final LatLng? currentLocation;
  final double rideProgress; // De 0.0 a 1.0
  final double distanceRemaining; // Em km
  final double timeRemaining; // Em minutos
  final int rideTimeElapsed; // Em segundos

  const RideInProgress({
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.destination,
    required this.destinationAddress,
    this.currentLocation,
    this.rideProgress = 0.0,
    this.distanceRemaining = 0.0,
    this.timeRemaining = 0.0,
    this.rideTimeElapsed = 0,
  });

  @override
  List<Object> get props => [
    rideId,
    driverId,
    driverName,
    destination,
    destinationAddress,
    if (currentLocation != null) currentLocation!,
    rideProgress,
    distanceRemaining,
    timeRemaining,
    rideTimeElapsed,
  ];

  RideInProgress copyWith({
    String? rideId,
    String? driverId,
    String? driverName,
    LatLng? destination,
    String? destinationAddress,
    LatLng? currentLocation,
    double? rideProgress,
    double? distanceRemaining,
    double? timeRemaining,
    int? rideTimeElapsed,
  }) {
    return RideInProgress(
      rideId: rideId ?? this.rideId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      destination: destination ?? this.destination,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      currentLocation: currentLocation ?? this.currentLocation,
      rideProgress: rideProgress ?? this.rideProgress,
      distanceRemaining: distanceRemaining ?? this.distanceRemaining,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      rideTimeElapsed: rideTimeElapsed ?? this.rideTimeElapsed,
    );
  }
}

class RideCompleted extends RideState {
  final String rideId;
  final String driverId;
  final String driverName;
  final String? driverPhoto;
  final double finalPrice;
  final int rideTime; // Em segundos
  final double distance; // Em km
  final bool isRated;
  final double? rating;

  const RideCompleted({
    required this.rideId,
    required this.driverId,
    required this.driverName,
    this.driverPhoto,
    required this.finalPrice,
    required this.rideTime,
    required this.distance,
    this.isRated = false,
    this.rating,
  });

  @override
  List<Object> get props => [
    rideId,
    driverId,
    driverName,
    if (driverPhoto != null) driverPhoto!,
    finalPrice,
    rideTime,
    distance,
    isRated,
    if (rating != null) rating!,
  ];

  RideCompleted copyWith({
    String? rideId,
    String? driverId,
    String? driverName,
    String? driverPhoto,
    double? finalPrice,
    int? rideTime,
    double? distance,
    bool? isRated,
    double? rating,
  }) {
    return RideCompleted(
      rideId: rideId ?? this.rideId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      finalPrice: finalPrice ?? this.finalPrice,
      rideTime: rideTime ?? this.rideTime,
      distance: distance ?? this.distance,
      isRated: isRated ?? this.isRated,
      rating: rating ?? this.rating,
    );
  }
}

class RideCancelled extends RideState {
  final String rideId;
  final String reason;
  final String cancelledBy; // 'passenger', 'driver', 'system'
  final double? cancellationFee;

  const RideCancelled({
    required this.rideId,
    required this.reason,
    required this.cancelledBy,
    this.cancellationFee,
  });

  @override
  List<Object> get props => [
    rideId,
    reason,
    cancelledBy,
    if (cancellationFee != null) cancellationFee!,
  ];
}

class RideError extends RideState {
  final String message;

  const RideError(this.message);

  @override
  List<Object> get props => [message];
}

