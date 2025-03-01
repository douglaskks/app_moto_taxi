// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String userType; // 'passenger', 'driver', 'admin'
  final String? phoneNumber;
  final String? profileImage;
  final DateTime createdAt;
  
  UserModel({
    required this.id, 
    required this.name, 
    required this.email, 
    required this.userType,
    this.phoneNumber,
    this.profileImage,
    required this.createdAt,
  });
  
  // Getter para verificar se o usuário é admin
  bool get isAdmin => userType == 'admin';
  
  // Getter para verificar se o usuário é motorista
  bool get isDriver => userType == 'driver';
  
  // Getter para verificar se o usuário é passageiro
  bool get isPassenger => userType == 'passenger';
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    userType: json['userType'] ?? 'passenger',
    phoneNumber: json['phoneNumber'],
    profileImage: json['profileImage'],
    createdAt: json['createdAt'] is Timestamp 
      ? (json['createdAt'] as Timestamp).toDate()
      : DateTime.parse(json['createdAt'].toString()),
  );
}

  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'userType': userType,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  // Método para atualizar informações do usuário
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? userType,
    String? phoneNumber,
    String? profileImage,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  // Método para validar o modelo de usuário
  bool get isValid {
    return id.isNotEmpty && 
           name.isNotEmpty && 
           email.isNotEmpty && 
           ['passenger', 'driver', 'admin'].contains(userType);
  }
  
  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, userType: $userType)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserModel &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.userType == userType;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^ 
           name.hashCode ^ 
           email.hashCode ^ 
           userType.hashCode;
  }
}