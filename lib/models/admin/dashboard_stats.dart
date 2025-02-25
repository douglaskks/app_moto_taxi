// lib/models/admin/dashboard_stats.dart
class DashboardStats {
  final int activeUsers;
  final int onlineDrivers;
  final int ridesCount;
  final double dailyRevenue;
  final List<int> hourlyRides;
  final List<ActiveRide> activeRides;
  
  DashboardStats({
    required this.activeUsers,
    required this.onlineDrivers,
    required this.ridesCount,
    required this.dailyRevenue,
    required this.hourlyRides,
    required this.activeRides,
  });
  
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeUsers: json['activeUsers'] ?? 0,
      onlineDrivers: json['onlineDrivers'] ?? 0,
      ridesCount: json['ridesCount'] ?? 0,
      dailyRevenue: (json['dailyRevenue'] ?? 0).toDouble(),
      hourlyRides: List<int>.from(json['hourlyRides'] ?? List<int>.filled(24, 0)),
      activeRides: (json['activeRides'] as List? ?? [])
          .map((rideJson) => ActiveRide.fromJson(rideJson))
          .toList(),
    );
  }
}

class ActiveRide {
  final String id;
  final String passengerName;
  final String driverName;
  final String pickupAddress;
  final String destinationAddress;
  final double fare;
  final DateTime startTime;
  
  ActiveRide({
    required this.id,
    required this.passengerName,
    required this.driverName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.fare,
    required this.startTime,
  });
  
  factory ActiveRide.fromJson(Map<String, dynamic> json) {
    return ActiveRide(
      id: json['id'] ?? '',
      passengerName: json['passengerName'] ?? '',
      driverName: json['driverName'] ?? '',
      pickupAddress: json['pickupAddress'] ?? '',
      destinationAddress: json['destinationAddress'] ?? '',
      fare: (json['fare'] ?? 0).toDouble(),
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] ?? 0),
    );
  }
}