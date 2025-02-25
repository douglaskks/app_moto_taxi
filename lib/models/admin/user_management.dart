// lib/models/admin/user_management.dart
class UserDetails {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime registrationDate;
  final UserStats? stats;
  final UserProfile? profile;
  
  UserDetails({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.registrationDate,
    this.stats,
    this.profile,
  });
  
  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      registrationDate: DateTime.fromMillisecondsSinceEpoch(json['registrationDate'] ?? 0),
      stats: json['stats'] != null ? UserStats.fromJson(json['stats']) : null,
      profile: json['profile'] != null ? UserProfile.fromJson(json['profile']) : null,
    );
  }
}

class UserStats {
  final int totalRides;
  final double totalSpent;
  final double totalEarned;
  final double averageRating;
  final int cancelledRides;
  
  UserStats({
    required this.totalRides,
    required this.totalSpent,
    required this.totalEarned,
    required this.averageRating,
    required this.cancelledRides,
  });
  
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalRides: json['totalRides'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      totalEarned: (json['totalEarned'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      cancelledRides: json['cancelledRides'] ?? 0,
    );
  }
}

class UserProfile {
  final String? phoneNumber;
  final String? profilePicUrl;
  final String? address;
  final DriverInfo? driverInfo;
  
  UserProfile({
    this.phoneNumber,
    this.profilePicUrl,
    this.address,
    this.driverInfo,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phoneNumber: json['phoneNumber'],
      profilePicUrl: json['profilePicUrl'],
      address: json['address'],
      driverInfo: json['driverInfo'] != null ? DriverInfo.fromJson(json['driverInfo']) : null,
    );
  }
}

class DriverInfo {
  final String licensePlate;
  final String vehicleModel;
  final String vehicleColor;
  final String driverLicense;
  final String documentNumber;
  final bool documentsVerified;
  
  DriverInfo({
    required this.licensePlate,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.driverLicense,
    required this.documentNumber,
    required this.documentsVerified,
  });
  
  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      licensePlate: json['licensePlate'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleColor: json['vehicleColor'] ?? '',
      driverLicense: json['driverLicense'] ?? '',
      documentNumber: json['documentNumber'] ?? '',
      documentsVerified: json['documentsVerified'] ?? false,
    );
  }
}