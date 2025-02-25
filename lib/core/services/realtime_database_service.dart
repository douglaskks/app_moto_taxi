// Arquivo: lib/core/services/realtime_database_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class RealtimeDatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Referências
  late DatabaseReference _driversLocationRef;
  late DatabaseReference _availableDriversRef;
  late DatabaseReference _ridesRef;
  
  // Streams
  StreamSubscription? _driverLocationSubscription;
  StreamSubscription? _rideStatusSubscription;
  
  RealtimeDatabaseService() {
    _driversLocationRef = _database.ref().child('drivers_locations');
    _availableDriversRef = _database.ref().child('available_drivers');
    _ridesRef = _database.ref().child('rides');
  }
  
  // MÉTODOS PARA MOTORISTAS
  
  // Atualizar localização do motorista
  Future<void> updateDriverLocation(double latitude, double longitude) async {
    if (_auth.currentUser == null) return;
    
    String driverId = _auth.currentUser!.uid;
    
    await _driversLocationRef.child(driverId).update({
      'latitude': latitude,
      'longitude': longitude,
      'last_updated': ServerValue.timestamp,
    });
  }
  
  // Definir motorista como disponível/indisponível
  Future<void> setDriverAvailability(bool isAvailable, String vehicleType) async {
    if (_auth.currentUser == null) return;
    
    String driverId = _auth.currentUser!.uid;
    
    if (isAvailable) {
      // Obter a localização atual
      try {
        Position position = await Geolocator.getCurrentPosition();
        await _availableDriversRef.child(driverId).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'vehicle_type': vehicleType,
          'last_updated': ServerValue.timestamp,
        });
      } catch (e) {
        print("Erro ao obter localização: $e");
      }
    } else {
      // Remover da lista de motoristas disponíveis
      await _availableDriversRef.child(driverId).remove();
    }
  }
  
  // Iniciar monitoramento automático de localização do motorista
  void startDriverLocationTracking() {
    if (_auth.currentUser == null) return;
    
    // Cancelar monitoramento existente, se houver
    _driverLocationSubscription?.cancel();
    
    // Iniciar novo monitoramento
    _driverLocationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // atualizar a cada 10 metros
      ),
    ).listen((Position position) {
      updateDriverLocation(position.latitude, position.longitude);
    });
  }
  
  // Parar monitoramento de localização
  void stopDriverLocationTracking() {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = null;
  }
  
  // Aceitar uma corrida (motorista)
  Future<void> acceptRide(String rideId, double estimatedArrivalTime) async {
    if (_auth.currentUser == null) return;
    
    String driverId = _auth.currentUser!.uid;
    
    await _ridesRef.child(rideId).update({
      'status': 'accepted',
      'driver_id': driverId,
      'estimated_arrival_time': estimatedArrivalTime,
      'accepted_at': ServerValue.timestamp,
    });
  }
  
  // Atualizar status da corrida (motorista)
  Future<void> updateRideStatus(String rideId, String status) async {
    await _ridesRef.child(rideId).update({
      'status': status,
      'updated_at': ServerValue.timestamp,
    });
    
    // Se a corrida foi finalizada, adicionar timestamp de conclusão
    if (status == 'completed') {
      await _ridesRef.child(rideId).update({
        'completed_at': ServerValue.timestamp,
      });
    }
  }
  
  // MÉTODOS PARA PASSAGEIROS
  
  // Solicitar corrida
  Future<String> requestRide({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double destinationLat,
    required double destinationLng,
    required String destinationAddress,
    required String paymentMethod,
    required double estimatedPrice,
    required double estimatedDistance,
    required double estimatedDuration,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception("Usuário não autenticado");
    }
    
    String passengerId = _auth.currentUser!.uid;
    
    // Criar nova entrada para a corrida
    DatabaseReference newRideRef = _ridesRef.push();
    String rideId = newRideRef.key!;
    
    await newRideRef.set({
      'passenger_id': passengerId,
      'pickup': {
        'latitude': pickupLat,
        'longitude': pickupLng,
        'address': pickupAddress,
      },
      'destination': {
        'latitude': destinationLat,
        'longitude': destinationLng,
        'address': destinationAddress,
      },
      'payment_method': paymentMethod,
      'estimated_price': estimatedPrice,
      'estimated_distance': estimatedDistance,
      'estimated_duration': estimatedDuration,
      'status': 'searching', // searching, accepted, arrived, in_progress, completed, cancelled
      'created_at': ServerValue.timestamp,
    });
    
    return rideId;
  }
  
  // Cancelar solicitação de corrida (passageiro)
  Future<void> cancelRideRequest(String rideId, String reason) async {
    await _ridesRef.child(rideId).update({
      'status': 'cancelled',
      'cancelled_at': ServerValue.timestamp,
      'cancellation_reason': reason,
      'cancelled_by': 'passenger',
    });
  }
  
  // Avaliar corrida (passageiro)
  Future<void> rateRide(String rideId, double rating, String? comment) async {
    await _ridesRef.child(rideId).child('rating').set({
      'stars': rating,
      'comment': comment,
      'rated_at': ServerValue.timestamp,
    });
  }
  
  // Obter corrida atual em andamento (passageiro ou motorista)
  Stream<Map<String, dynamic>?> getCurrentRideStream(String rideId) {
    return _ridesRef.child(rideId).onValue.map((event) {
      if (event.snapshot.value == null) return null;
      
      Map<String, dynamic> rideData = 
          Map<String, dynamic>.from(event.snapshot.value as Map);
      rideData['id'] = event.snapshot.key;
      
      return rideData;
    });
  }
  
  // Obter motoristas disponíveis próximos
  Stream<List<Map<String, dynamic>>> getNearbyDrivers(double latitude, double longitude, double radiusInKm) {
    // No Realtime Database não há consultas geoespaciais nativas como no Firestore
    // Uma abordagem simplificada é buscar todos os motoristas disponíveis e filtrar no cliente
    
    return _availableDriversRef.onValue.map((event) {
      List<Map<String, dynamic>> nearbyDrivers = [];
      
      if (event.snapshot.value == null) return nearbyDrivers;
      
      Map driversData = event.snapshot.value as Map;
      
      driversData.forEach((key, value) {
        Map<String, dynamic> driverData = Map<String, dynamic>.from(value);
        driverData['id'] = key;
        
        // Calcular distância entre a posição do usuário e do motorista
        double driverLat = driverData['latitude'];
        double driverLng = driverData['longitude'];
        
        double distance = _calculateDistance(
          latitude, longitude, driverLat, driverLng
        );
        
        // Adicionar apenas motoristas dentro do raio especificado
        if (distance <= radiusInKm) {
          driverData['distance'] = distance;
          nearbyDrivers.add(driverData);
        }
      });
      
      // Ordenar por proximidade
      nearbyDrivers.sort((a, b) => 
        (a['distance'] as double).compareTo(b['distance'] as double));
      
      return nearbyDrivers;
    });
  }
  
  // Obter localização em tempo real do motorista
  Stream<LatLng?> getDriverLocationStream(String driverId) {
    return _driversLocationRef.child(driverId).onValue.map((event) {
      if (event.snapshot.value == null) return null;
      
      Map<String, dynamic> locationData = 
          Map<String, dynamic>.from(event.snapshot.value as Map);
      
      return LatLng(
        locationData['latitude'] as double,
        locationData['longitude'] as double,
      );
    });
  }
  
  // Método auxiliar para calcular distância entre coordenadas (fórmula de Haversine)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // km
  double dLat = _degreesToRadians(lat2 - lat1);
  double dLon = _degreesToRadians(lon2 - lon1);
  
  double a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
      
  double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  double distance = earthRadius * c;
  
  return distance;
}
  
  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
  
  // Limpar recursos ao encerrar
  void dispose() {
    _driverLocationSubscription?.cancel();
    _rideStatusSubscription?.cancel();
  }
}