// lib/models/admin/ride_management.dart
class RideDetails {
  final String id;
  final String status;
  final String passengerName;
  final String? driverName;
  final String pickupAddress;
  final String destinationAddress;
  final double fare;
  final double distance;
  final int duration;
  final DateTime createdAt;
  final DateTime? completedAt;
  final PaymentInfo? paymentInfo;
  
  RideDetails({
    required this.id,
    required this.status,
    required this.passengerName,
    this.driverName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.fare,
    required this.distance,
    required this.duration,
    required this.createdAt,
    this.completedAt,
    this.paymentInfo,
  });
  
  factory RideDetails.fromJson(Map<String, dynamic> json) {
    return RideDetails(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      passengerName: json['passengerName'] ?? '',
      driverName: json['driverName'],
      pickupAddress: json['pickupAddress'] ?? '',
      destinationAddress: json['destinationAddress'] ?? '',
      fare: (json['fare'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
          : null,
      paymentInfo: json['paymentInfo'] != null
          ? PaymentInfo.fromJson(json['paymentInfo'])
          : null,
    );
  }
}

class RideDetailsFull extends RideDetails {
  final String passengerId;
  final String? driverId;
  final double platformFee;
  final List<StatusChange>? statusHistory;
  
  RideDetailsFull({
    required super.id,
    required super.status,
    required super.passengerName,
    super.driverName,
    required super.pickupAddress,
    required super.destinationAddress,
    required super.fare,
    required super.distance,
    required super.duration,
    required super.createdAt,
    super.completedAt,
    super.paymentInfo,
    required this.passengerId,
    this.driverId,
    required this.platformFee,
    this.statusHistory,
  });
  
  factory RideDetailsFull.fromJson(Map<String, dynamic> json) {
    return RideDetailsFull(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      passengerName: json['passengerName'] ?? '',
      driverName: json['driverName'],
      pickupAddress: json['pickupAddress'] ?? '',
      destinationAddress: json['destinationAddress'] ?? '',
      fare: (json['fare'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
          : null,
      paymentInfo: json['paymentInfo'] != null
          ? PaymentInfo.fromJson(json['paymentInfo'])
          : null,
      passengerId: json['passengerId'] ?? '',
      driverId: json['driverId'],
      platformFee: (json['platformFee'] ?? 0).toDouble(),
      statusHistory: json['statusHistory'] != null
          ? (json['statusHistory'] as List)
              .map((item) => StatusChange.fromJson(item))
              .toList()
          : null,
    );
  }
}

class PaymentInfo {
  final String method;
  final String status;
  final String? transactionId;
  
  PaymentInfo({
    required this.method,
    required this.status,
    this.transactionId,
  });
  
  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      method: json['method'] ?? '',
      status: json['status'] ?? '',
      transactionId: json['transactionId'],
    );
  }
}

class StatusChange {
  final String status;
  final DateTime timestamp;
  final String? comment;
  
  StatusChange({
    required this.status,
    required this.timestamp,
    this.comment,
  });
  
  factory StatusChange.fromJson(Map<String, dynamic> json) {
    return StatusChange(
      status: json['status'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      comment: json['comment'],
    );
  }
}