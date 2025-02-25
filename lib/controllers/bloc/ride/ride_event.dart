// Arquivo: lib/controllers/bloc/ride/ride_event.dart
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class RideEvent extends Equatable {
  const RideEvent();

  @override
  List<Object> get props => [];
}

class RequestRide extends RideEvent {
  final LatLng pickup;
  final String pickupAddress;
  final LatLng destination;
  final String destinationAddress;
  final String paymentMethod;
  final double estimatedPrice;
  final double estimatedDistance;
  final double estimatedDuration;

  const RequestRide({
    required this.pickup,
    required this.pickupAddress,
    required this.destination,
    required this.destinationAddress,
    required this.paymentMethod,
    required this.estimatedPrice,
    required this.estimatedDistance,
    required this.estimatedDuration,
  });

  @override
  List<Object> get props => [
    pickup, 
    pickupAddress, 
    destination, 
    destinationAddress, 
    paymentMethod, 
    estimatedPrice,
    estimatedDistance,
    estimatedDuration,
  ];
}

class CancelRideRequest extends RideEvent {
  final String rideId;
  final String reason;

  const CancelRideRequest({
    required this.rideId,
    required this.reason,
  });

  @override
  List<Object> get props => [rideId, reason];
}

class AcceptRide extends RideEvent {
  final String rideId;
  final double estimatedArrivalTime;

  const AcceptRide({
    required this.rideId,
    required this.estimatedArrivalTime,
  });

  @override
  List<Object> get props => [rideId, estimatedArrivalTime];
}

class UpdateRideStatus extends RideEvent {
  final String rideId;
  final String status;

  const UpdateRideStatus({
    required this.rideId,
    required this.status,
  });

  @override
  List<Object> get props => [rideId, status];
}

class TrackRide extends RideEvent {
  final String rideId;

  const TrackRide({
    required this.rideId,
  });

  @override
  List<Object> get props => [rideId];
}

class StopTrackingRide extends RideEvent {}

class RateRide extends RideEvent {
  final String rideId;
  final double rating;
  final String? comment;

  const RateRide({
    required this.rideId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object> get props => [
    rideId, 
    rating,
    if (comment != null) comment!,
  ];
}

class RideUpdated extends RideEvent {
  final Map<String, dynamic> rideData;

  const RideUpdated(this.rideData);

  @override
  List<Object> get props => [rideData];
}

