// Arquivo: lib/models/ride_request.dart

class RideRequest {
  final String passengerId;
  final String passengerName;
  final double passengerRating;
  final String pickupAddress;
  final String destinationAddress;
  final double estimatedDistance;
  final int estimatedDuration;
  final double estimatedFare;
  final double distanceToPickup;

  RideRequest({
    required this.passengerId,
    required this.passengerName,
    required this.passengerRating,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.estimatedFare,
    required this.distanceToPickup,
  });
  
  // Construtor de fábrica para criar a partir de dados do Firebase
  factory RideRequest.fromMap(Map<String, dynamic> data, {double distanceToPickup = 0.0}) {
    return RideRequest(
      passengerId: data['passenger_id'] ?? '',
      passengerName: data['passenger_name'] ?? 'Passageiro',
      passengerRating: (data['passenger_rating'] ?? 5.0).toDouble(),
      pickupAddress: data['pickup']['address'] ?? '',
      destinationAddress: data['destination']['address'] ?? '',
      estimatedDistance: (data['estimated_distance'] ?? 0.0).toDouble(),
      estimatedDuration: (data['estimated_duration'] ?? 0).toInt(),
      estimatedFare: (data['estimated_price'] ?? 0.0).toDouble(),
      distanceToPickup: distanceToPickup,
    );
  }
  
  // Método para converter em Map (útil para salvar no Firebase)
  Map<String, dynamic> toMap() {
    return {
      'passenger_id': passengerId,
      'passenger_name': passengerName,
      'passenger_rating': passengerRating,
      'pickup_address': pickupAddress,
      'destination_address': destinationAddress,
      'estimated_distance': estimatedDistance,
      'estimated_duration': estimatedDuration,
      'estimated_fare': estimatedFare,
    };
  }
}