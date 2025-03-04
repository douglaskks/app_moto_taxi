// Arquivo: lib/core/services/realtime_database_service.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class RealtimeDatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Referências
  late DatabaseReference _driversLocationRef;
  late DatabaseReference _availableDriversRef;
  late DatabaseReference _ridesRef;
  
  // Streams
  StreamSubscription? _driverLocationSubscription;
  StreamSubscription? _rideStatusSubscription;
  
  RealtimeDatabaseService() {
    print("RealtimeDatabaseService: Inicializando serviço...");
    _driversLocationRef = _database.ref().child('drivers_locations');
    _availableDriversRef = _database.ref().child('available_drivers');
    _ridesRef = _database.ref().child('rides');
    print("RealtimeDatabaseService: Serviço inicializado com sucesso");
    
  }
  
  // MÉTODOS PARA MOTORISTAS
  
  // Atualizar localização do motorista
  Future<void> updateDriverLocation(double latitude, double longitude) async {
    if (_auth.currentUser == null) {
      print("RealtimeDatabaseService: Erro - usuário não autenticado em updateDriverLocation");
      return;
    }
    
    String driverId = _auth.currentUser!.uid;
    print("RealtimeDatabaseService: Atualizando localização do motorista $driverId");
    
    try {
      await _driversLocationRef.child(driverId).update({
        'latitude': latitude,
        'longitude': longitude,
        'last_updated': ServerValue.timestamp,
      });
      print("RealtimeDatabaseService: Localização do motorista atualizada com sucesso");
    } catch (e) {
      print("RealtimeDatabaseService: Erro ao atualizar localização do motorista: $e");
      throw e;
    }
  }
  
  // Definir motorista como disponível/indisponível
  Future<void> setDriverAvailability(bool isAvailable, String vehicleType) async {
    print("=== DEFININDO DISPONIBILIDADE DO MOTORISTA ===");
    print("isAvailable: $isAvailable, vehicleType: $vehicleType");
    
    if (_auth.currentUser == null) {
      print("ERRO: Usuário não autenticado ao definir disponibilidade");
      throw Exception("Usuário não autenticado");
    }
    
    String driverId = _auth.currentUser!.uid;
    print("ID do motorista: $driverId");
    
    if (isAvailable) {
      print("Tentando definir motorista como disponível...");
      try {
        Position position = await Geolocator.getCurrentPosition();
        print("Posição obtida: ${position.latitude}, ${position.longitude}");
        
        print("Atualizando nó available_drivers/$driverId");
        await _availableDriversRef.child(driverId).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'vehicle_type': vehicleType,
          'last_updated': ServerValue.timestamp,
        });
        
        print("Motorista definido como disponível com sucesso!");
      } catch (e) {
        print("ERRO ao definir disponibilidade: $e");
        throw e; // Propagar o erro para tratamento
      }
    } else {
      print("Removendo motorista da lista de disponíveis...");
      try {
        await _availableDriversRef.child(driverId).remove();
        print("Motorista removido com sucesso!");
      } catch (e) {
        print("ERRO ao remover motorista: $e");
        throw e;
      }
    }
    
    print("=== FIM DA DEFINIÇÃO DE DISPONIBILIDADE ===");
  }
  
  // Iniciar monitoramento automático de localização do motorista
  void startDriverLocationTracking() {
    if (_auth.currentUser == null) {
      print("RealtimeDatabaseService: Erro - usuário não autenticado em startDriverLocationTracking");
      return;
    }
    
    print("RealtimeDatabaseService: Iniciando monitoramento de localização do motorista");
    
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
    print("RealtimeDatabaseService: Parando monitoramento de localização do motorista");
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = null;
  }
  
  // Aceitar uma corrida (motorista)
  Future<void> acceptRide(String rideId, double estimatedArrivalTime) async {
    if (_auth.currentUser == null) {
      print("RealtimeDatabaseService: Erro - usuário não autenticado em acceptRide");
      throw Exception('Usuário não autenticado');
    }
    
    String driverId = _auth.currentUser!.uid;
    print("RealtimeDatabaseService: Motorista $driverId aceitando corrida $rideId");
    
    try {
      // Buscar informações do motorista no Firestore
      final driverDoc = await _firestore
          .collection('users')
          .doc(driverId)
          .get();
      
      if (!driverDoc.exists) {
        throw Exception('Perfil do motorista não encontrado');
      }
      
      final driverData = driverDoc.data() as Map<String, dynamic>;
      
      // Atualizar status da corrida e adicionar informações do motorista no Realtime Database
      await _ridesRef.child(rideId).update({
        'status': 'accepted',
        'driver_id': driverId,
        'driver_name': driverData['name'] ?? 'Motorista',
        'driver_phone': driverData['phone'] ?? '',
        'vehicle_model': driverData['vehicleModel'] ?? '',
        'vehicle_plate': driverData['vehiclePlate'] ?? '',
        'estimated_arrival_time': estimatedArrivalTime,
        'accepted_at': ServerValue.timestamp,
      });
      
      // Registrar a corrida aceita na coleção de corridas no Firestore
      // para rastreamento persistente e análise posterior
      await _firestore.collection('rides').doc(rideId).set({
        'ride_id': rideId,
        'driver_id': driverId,
        'status': 'accepted',
        'accepted_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('RealtimeDatabaseService: Corrida $rideId aceita com sucesso');
    } catch (e) {
      print('RealtimeDatabaseService: Erro ao aceitar corrida - $e');
      throw e;
    }
  }
  
  // Atualizar status da corrida (motorista)
  Future<void> updateRideStatus(String rideId, String status) async {
    print("RealtimeDatabaseService: Atualizando status da corrida $rideId para $status");
    
    try {
      // Atualizar no Realtime Database
      await _ridesRef.child(rideId).update({
        'status': status,
        '${status}_at': ServerValue.timestamp,
      });
      
      // Atualizar também no Firestore para histórico permanente
      await _firestore.collection('rides').doc(rideId).update({
        'status': status,
        '${status}_at': FieldValue.serverTimestamp(),
        'last_updated': FieldValue.serverTimestamp(),
      });
      
      print("RealtimeDatabaseService: Status da corrida atualizado com sucesso");
    } catch (e) {
      print("RealtimeDatabaseService: Erro ao atualizar status da corrida - $e");
      throw e;
    }
  }
  
  // Finalizar corrida com preço final
  Future<void> completeRide(String rideId, double finalPrice, int durationInMinutes) async {
    print("RealtimeDatabaseService: Finalizando corrida $rideId com preço $finalPrice");
    
    try {
      // Atualizar no Realtime Database
      await _ridesRef.child(rideId).update({
        'status': 'completed',
        'completed_at': ServerValue.timestamp,
        'final_price': finalPrice,
        'actual_duration_minutes': durationInMinutes,
      });
      
      // Atualizar no Firestore
      await _firestore.collection('rides').doc(rideId).update({
        'status': 'completed',
        'completed_at': FieldValue.serverTimestamp(),
        'final_price': finalPrice,
        'actual_duration_minutes': durationInMinutes,
        'last_updated': FieldValue.serverTimestamp(),
      });
      
      print("RealtimeDatabaseService: Corrida finalizada com sucesso");
    } catch (e) {
      print("RealtimeDatabaseService: Erro ao finalizar corrida - $e");
      throw e;
    }
  }
  
  // Avaliar corrida
  Future<void> rateRide(String rideId, double rating, String? comment) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Verificar se o usuário é motorista ou passageiro
      final rideSnapshot = await _ridesRef.child(rideId).get();
      if (!rideSnapshot.exists) {
        throw Exception('Corrida não encontrada');
      }
      
      final rideData = Map<String, dynamic>.from(rideSnapshot.value as Map);
      final isDriver = rideData['driver_id'] == currentUser.uid;
      
      // Nome do campo de avaliação com base em quem está avaliando
      final String ratingField = isDriver ? 'passenger_rating' : 'driver_rating';
      final String commentField = isDriver ? 'passenger_comment' : 'driver_comment';
      
      // Atualizar avaliação no Realtime Database
      await _ridesRef.child(rideId).update({
        ratingField: rating,
        if (comment != null && comment.isNotEmpty) commentField: comment,
        'rated_at': ServerValue.timestamp,
      });
      
      // Atualizar avaliação no Firestore
      await _firestore.collection('rides').doc(rideId).update({
        ratingField: rating,
        if (comment != null && comment.isNotEmpty) commentField: comment,
        'rated_at': FieldValue.serverTimestamp(),
        'last_updated': FieldValue.serverTimestamp(),
      });
      
      print('RealtimeDatabaseService: Avaliação da corrida $rideId registrada');
    } catch (e) {
      print('RealtimeDatabaseService: Erro ao avaliar corrida - $e');
      throw e;
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
    print("RealtimeDatabaseService: Solicitando nova corrida...");
    print("RealtimeDatabaseService: Origem: $pickupAddress ($pickupLat, $pickupLng)");
    print("RealtimeDatabaseService: Destino: $destinationAddress ($destinationLat, $destinationLng)");
    print("RealtimeDatabaseService: Preço estimado: $estimatedPrice, Distância: $estimatedDistance km, Duração: $estimatedDuration min");
    
    if (_auth.currentUser == null) {
      print("RealtimeDatabaseService: Erro - usuário não autenticado em requestRide");
      throw Exception("Usuário não autenticado");
    }
    
    String passengerId = _auth.currentUser!.uid;
    print("RealtimeDatabaseService: ID do passageiro: $passengerId");
    
    try {
      // Criar nova entrada para a corrida
      DatabaseReference newRideRef = _ridesRef.push();
      String rideId = newRideRef.key!;
      print("RealtimeDatabaseService: Novo ID de corrida gerado: $rideId");
      
      // Obter dados do passageiro
      DocumentSnapshot passengerDoc = await _firestore
          .collection('users')
          .doc(passengerId)
          .get();
      
      String passengerName = 'Passageiro';
      if (passengerDoc.exists) {
        final data = passengerDoc.data() as Map<String, dynamic>;
        passengerName = data['name'] ?? 'Passageiro';
      }
      
      // Gravar no Realtime Database
      await newRideRef.set({
        'passenger_id': passengerId,
        'passenger_name': passengerName,
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
      
      // Gravar no Firestore para histórico permanente
      await _firestore.collection('rides').doc(rideId).set({
        'ride_id': rideId,
        'passenger_id': passengerId,
        'passenger_name': passengerName,
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
        'status': 'searching',
        'created_at': FieldValue.serverTimestamp(),
      });
      
      print("RealtimeDatabaseService: Corrida solicitada com sucesso!");
      return rideId;
    } catch (e) {
      print("RealtimeDatabaseService: ERRO ao solicitar corrida: $e");
      throw Exception("Falha ao solicitar corrida: $e");
    }
  }
  
  // Cancelar solicitação de corrida (passageiro)
  Future<void> cancelRideRequest(String rideId, String reason) async {
    print("RealtimeDatabaseService: Cancelando corrida $rideId...");
    print("RealtimeDatabaseService: Motivo: $reason");
    
    try {
      // Atualizar no Realtime Database
      await _ridesRef.child(rideId).update({
        'status': 'cancelled',
        'cancelled_at': ServerValue.timestamp,
        'cancellation_reason': reason,
        'cancelled_by': 'passenger',
      });
      
      // Atualizar no Firestore
      await _firestore.collection('rides').doc(rideId).update({
        'status': 'cancelled',
        'cancelled_at': FieldValue.serverTimestamp(),
        'cancellation_reason': reason,
        'cancelled_by': 'passenger',
        'last_updated': FieldValue.serverTimestamp(),
      });
      
      print("RealtimeDatabaseService: Corrida cancelada com sucesso");
    } catch (e) {
      print("RealtimeDatabaseService: ERRO ao cancelar corrida: $e");
      throw Exception("Falha ao cancelar corrida: $e");
    }
  }
  
  // Obter corrida atual em andamento (passageiro ou motorista)
  Stream<Map<String, dynamic>?> getCurrentRideStream(String rideId) {
    print("RealtimeDatabaseService: Iniciando stream de monitoramento para corrida $rideId");
    
    return _ridesRef.child(rideId).onValue.map((event) {
      if (event.snapshot.value == null) {
        print("RealtimeDatabaseService: Não foram encontrados dados para a corrida $rideId");
        return null;
      }
      
      Map<String, dynamic> rideData = 
          Map<String, dynamic>.from(event.snapshot.value as Map);
      rideData['id'] = event.snapshot.key;
      
      print("RealtimeDatabaseService: Dados da corrida $rideId atualizados - Status: ${rideData['status']}");
      return rideData;
    });
  }
  
  // Obter motoristas disponíveis próximos
  Stream<List<Map<String, dynamic>>> getNearbyDrivers(double latitude, double longitude, double radiusInKm) {
    print("RealtimeDatabaseService: Buscando motoristas próximos à posição ($latitude, $longitude) em um raio de $radiusInKm km");
    
    // No Realtime Database não há consultas geoespaciais nativas como no Firestore
    // Uma abordagem simplificada é buscar todos os motoristas disponíveis e filtrar no cliente
    
    return _availableDriversRef.onValue.map((event) {
      List<Map<String, dynamic>> nearbyDrivers = [];
      
      if (event.snapshot.value == null) {
        print("RealtimeDatabaseService: Nenhum motorista disponível encontrado");
        return nearbyDrivers;
      }
      
      Map driversData = event.snapshot.value as Map;
      print("RealtimeDatabaseService: ${driversData.length} motoristas disponíveis encontrados no total");
      
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
      
      print("RealtimeDatabaseService: ${nearbyDrivers.length} motoristas encontrados dentro do raio de $radiusInKm km");
      return nearbyDrivers;
    });
  }
  
  // Obter localização em tempo real do motorista
  Stream<Map<String, dynamic>?> getDriverLocationStream(String driverId) {
    print("RealtimeDatabaseService: Iniciando stream de localização do motorista $driverId");
    
    return _driversLocationRef.child(driverId).onValue.map((event) {
      if (event.snapshot.value == null) {
        print("RealtimeDatabaseService: Localização do motorista $driverId não encontrada");
        return null;
      }
      
      try {
        // Retornar o mapa diretamente
        Map<String, dynamic> locationData = 
            Map<String, dynamic>.from(event.snapshot.value as Map);
        
        print("RealtimeDatabaseService: Localização do motorista $driverId atualizada: (${locationData['latitude']}, ${locationData['longitude']})");
        return locationData;
      } catch (e) {
        print("RealtimeDatabaseService: Erro ao processar dados de localização - $e");
        return null;
      }
    });
  }
  
  // Obter histórico de corridas do motorista
  Future<List<Map<String, dynamic>>> getDriverRideHistory({int limit = 20}) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Buscar corridas do motorista ordenadas pela data de criação
      final querySnapshot = await _firestore
          .collection('rides')
          .where('driver_id', isEqualTo: currentUser.uid)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      
      // Converter para lista de Maps
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Adicionar o ID do documento aos dados
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('RealtimeDatabaseService: Erro ao buscar histórico de corridas - $e');
      return [];
    }
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

   Future<Map<String, dynamic>?> getDriverData(String driverId) async {
    try {
      print("RealtimeDatabaseService: Buscando dados do motorista $driverId");
      
      // Primeiro, verifica se há dados no Realtime Database
      final rtdbSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('drivers/$driverId')
          .get();
      
      if (rtdbSnapshot.exists) {
        print("RealtimeDatabaseService: Dados encontrados para o motorista $driverId no Realtime Database");
        return Map<String, dynamic>.from(rtdbSnapshot.value as Map);
      }
      
      // Caso não encontre no Realtime Database, tenta buscar no Firestore
      print("RealtimeDatabaseService: Buscando dados do motorista no Firestore");
      final firestoreSnapshot = await _firestore
          .collection('users')
          .doc(driverId)
          .get();
      
      if (firestoreSnapshot.exists) {
        print("RealtimeDatabaseService: Dados encontrados para o motorista $driverId no Firestore");
        final userData = firestoreSnapshot.data() as Map<String, dynamic>;
        
        // Monta um objeto com os dados necessários
        return {
          'name': userData['name'] ?? 'Motorista',
          'phone': userData['phone'] ?? '',
          'rating': userData['rating'] ?? 0.0,
          'vehicle': {
            'model': userData['vehicleModel'] ?? 'Veículo',
            'plate': userData['vehiclePlate'] ?? '',
            'color': userData['vehicleColor'] ?? '',
          }
        };
      }
      
      print("RealtimeDatabaseService: Nenhum dado encontrado para o motorista $driverId");
      return null;
    } catch (e) {
      print("RealtimeDatabaseService: Erro ao buscar dados do motorista: $e");
      return null;
    }
  }

  
  
  // Limpar recursos ao encerrar
  void dispose() {
    print("RealtimeDatabaseService: Limpando recursos...");
    _driverLocationSubscription?.cancel();
    _rideStatusSubscription?.cancel();
  }
}

// Método para obter atualizações da localização do motorista
Stream<Map<String, dynamic>?> getDriverLocationStream(String driverId) {
  print("RealtimeDatabaseService: Iniciando stream de localização do motorista $driverId");
  
  // Usar FirebaseDatabase.instance diretamente se _database não estiver definido
  final driversLocationRef = FirebaseDatabase.instance.ref().child('drivers_locations');
  
  return driversLocationRef.child(driverId).onValue.map((event) {
    if (event.snapshot.value == null) {
      print("RealtimeDatabaseService: Localização do motorista $driverId não encontrada");
      return null;
    }
    
    try {
      Map<String, dynamic> locationData = 
          Map<String, dynamic>.from(event.snapshot.value as Map);
      
      print("RealtimeDatabaseService: Localização do motorista $driverId atualizada: (${locationData['latitude']}, ${locationData['longitude']})");
      return locationData;
    } catch (e) {
      print("RealtimeDatabaseService: Erro ao processar dados de localização - $e");
      return null;
    }
  });
}