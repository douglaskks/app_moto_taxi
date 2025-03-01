// Arquivo: lib/core/services/ride_listener_service.dart

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../views/driver/ride_request_screen.dart';
import 'dart:math' as math;

class RideListenerService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Referências e streams
  late DatabaseReference _ridesRef;
  StreamSubscription? _rideRequestsSubscription;
  
  // Configurações
  final double maxDistanceInKm = 5.0; // Distância máxima para mostrar solicitações (5 km)
  
  // Estado atual
  Position? _currentPosition;
  final List<String> _processedRideIds = [];
  
  // Construtor
  RideListenerService() {
    _ridesRef = _database.ref().child('rides');
    print("RideListenerService: Inicializado");
  }
  
  // Iniciar monitoramento de novas solicitações de corrida
  void startListeningForRideRequests(
    Position currentPosition,
    BuildContext context,
    Function(String rideId) onAccept,
  ) {
    print("RideListenerService: Iniciando monitoramento de corridas");
    _currentPosition = currentPosition;
    
    // Cancelar assinatura existente
    _rideRequestsSubscription?.cancel();
    
    // Monitorar novas corridas no status "searching"
    _rideRequestsSubscription = _ridesRef
      .orderByChild('status')
      .equalTo('searching')
      .onChildAdded
      .listen((event) {
        _handleNewRideRequest(event, context, onAccept);
      });
      
    print("RideListenerService: Monitoramento de corridas ativo");
  }
  
  // Parar monitoramento
  void stopListeningForRideRequests() {
    print("RideListenerService: Parando monitoramento de corridas");
    _rideRequestsSubscription?.cancel();
    _rideRequestsSubscription = null;
  }
  
  // Atualizar posição atual
  void updateCurrentPosition(Position position) {
    _currentPosition = position;
  }
  
  // Manipular nova solicitação de corrida
  void _handleNewRideRequest(
    DatabaseEvent event, 
    BuildContext context,
    Function(String rideId) onAccept,
  ) {
    try {
      // Obter ID e dados da corrida
      final rideId = event.snapshot.key;
      
      if (rideId == null) {
        print("RideListenerService: Corrida sem ID ignorada");
        return;
      }
      
      // Verificar se já processamos esta corrida
      if (_processedRideIds.contains(rideId)) {
        print("RideListenerService: Corrida $rideId já processada anteriormente");
        return;
      }
      
      // Adicionar à lista de corridas processadas
      _processedRideIds.add(rideId);
      
      // Limitar o tamanho da lista para não crescer indefinidamente
      if (_processedRideIds.length > 50) {
        _processedRideIds.removeAt(0);
      }
      
      // Converter dados para Map
      final rideData = Map<String, dynamic>.from(
        event.snapshot.value as Map
      );
      
      print("RideListenerService: Nova corrida detectada - ID: $rideId");
      
      // Verificar se a corrida ainda está no status de busca
      if (rideData['status'] != 'searching') {
        print("RideListenerService: Corrida $rideId não está mais no status 'searching'");
        return;
      }
      
      // Verificar se a posição atual está disponível
      if (_currentPosition == null) {
        print("RideListenerService: Posição atual não disponível");
        return;
      }
      
      // Calcular distância até o ponto de partida
      final pickupLat = rideData['pickup']['latitude'] as double;
      final pickupLng = rideData['pickup']['longitude'] as double;
      
      final distanceToPickup = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        pickupLat,
        pickupLng
      );
      
      // Verificar se está dentro do raio permitido
      if (distanceToPickup > maxDistanceInKm) {
        print("RideListenerService: Corrida $rideId está fora do raio de alcance (${distanceToPickup.toStringAsFixed(2)} km)");
        return;
      }
      
      print("RideListenerService: Corrida $rideId está a ${distanceToPickup.toStringAsFixed(2)} km de distância");
      
      // Obter informações do passageiro (normalmente seria buscado no Firestore)
      // Aqui estamos usando valores padrão para simplificar
      final passengerId = rideData['passenger_id'] as String;
      final passengerName = "Passageiro"; // Valor padrão
      final passengerRating = 4.5; // Valor padrão
      
      // Extrair informações de endereço e estimativas
      final pickupAddress = rideData['pickup']['address'] as String;
      final destinationAddress = rideData['destination']['address'] as String;
      final estimatedPrice = rideData['estimated_price'] as double;
      final estimatedDistance = rideData['estimated_distance'] as double;
      final estimatedDuration = rideData['estimated_duration'] as double;
      
      // Mostrar tela de solicitação de corrida
      _showRideRequestScreen(
        context,
        rideId,
        passengerId,
        passengerName,
        passengerRating,
        pickupAddress,
        destinationAddress,
        distanceToPickup,
        estimatedDistance,
        estimatedDuration,
        estimatedPrice,
        onAccept,
      );
      
    } catch (e) {
      print("RideListenerService: Erro ao processar solicitação de corrida - $e");
    }
  }
  
  // Mostrar tela de solicitação de corrida
  void _showRideRequestScreen(
    BuildContext context,
    String rideId,
    String passengerId,
    String passengerName,
    double passengerRating,
    String pickupAddress,
    String destinationAddress,
    double distanceToPickup,
    double estimatedDistance,
    double estimatedDuration,
    double estimatedPrice,
    Function(String rideId) onAccept,
  ) {
    // Garantir que estamos em um contexto seguro
    if (context.mounted) {
      print("RideListenerService: Mostrando tela de solicitação para corrida $rideId");
      
      // Navegar para a tela de solicitação de corrida
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RideRequestScreen(
            rideId: rideId,
            passengerId: passengerId,
            passengerName: passengerName,
            passengerRating: passengerRating,
            pickupAddress: pickupAddress,
            destinationAddress: destinationAddress,
            estimatedDistance: estimatedDistance,
            estimatedDuration: estimatedDuration,
            estimatedFare: estimatedPrice,
            distanceToPickup: distanceToPickup,
            onAccept: () {
              // Chamar função de callback
              onAccept(rideId);
              
              // Fechar tela de solicitação
              Navigator.pop(context);
            },
            onReject: () {
              // Apenas fechar a tela por enquanto
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else {
      print("RideListenerService: Não foi possível mostrar a tela - contexto não disponível");
    }
  }
  
  // Método para calcular distância entre coordenadas (fórmula de Haversine)
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
  
  // Limpar recursos
  void dispose() {
    stopListeningForRideRequests();
  }
}