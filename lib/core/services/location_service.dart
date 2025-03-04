// lib/core/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class LocationService {
  // Lista de bairros conhecidos em Lajedo
  final List<String> _knownNeighborhoods = [
    'Centro',
    'Planalto',
    'Bia Cosme',
    'Socorro',
    'Bairro Novo',
    'Multirão',
    'Cohab',
    'Vila Nova',
    'Santo Antônio',
    'São José',
  ];

  // Cidades próximas de interesse
  final List<String> _nearbyTowns = [
    'Lajedo',
    'Cortês',
    'Águas Belas',
    'Garanhuns',
    'São Bento do Una',
    'Capoeiras',
    'Belo Jardim',
  ];

  // Coordenadas de referência para Lajedo
  static const LatLng lajedoCenter = LatLng(-8.7891, -36.2448);
  
  // Chave da API do Google Maps (use sua própria chave)
  final String _apiKey = 'AIzaSyBgm2hoaSCfPQr_nW_JwDgVXnpR5AwOZEY';
  
  // Instância de PolylinePoints
  final PolylinePoints _polylinePoints = PolylinePoints();

  // Verifica se a permissão de localização está concedida
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se os serviços de localização estão habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Verifica a permissão de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Solicita permissão de localização
  Future<bool> requestLocationPermission() async {
    LocationPermission permission;

    // Solicita permissão
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Obtém a localização atual do usuário
  Future<Position> getCurrentLocation() async {
    try {
      final locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );
      
      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    } catch (e) {
      // Tentar com precisão reduzida como fallback
      final locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.medium,
      );
      
      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    }
  }

  // Configura o stream de atualizações de localização
  Stream<Position> getLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Atualiza a cada 10 metros de movimento
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  // Obtém o endereço a partir de coordenadas
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Personalizar para adicionar contexto de Lajedo
        return '${place.thoroughfare ?? ''}, ${place.subLocality ?? ''}, Lajedo - PE';
      }
      
      return 'Endereço em Lajedo';
    } catch (e) {
      return 'Endereço em Lajedo';
    }
  }

  // Obtém coordenadas a partir de um endereço
  Future<LatLng> getCoordinatesFromAddress(String address) async {
    try {
      // Melhorar o contexto do endereço para Lajedo
      String enhancedAddress = _enhanceAddressContext(address);
      
      List<Location> locations = await locationFromAddress(enhancedAddress);
      
      if (locations.isNotEmpty) {
        Location location = locations[0];
        
        // Validar se está próximo de Lajedo (raio de 20 km)
        if (_isWithinLajedoRegion(location.latitude, location.longitude)) {
          return LatLng(location.latitude, location.longitude);
        } else {
          throw Exception('Endereço muito distante de Lajedo');
        }
      }
      
      throw Exception('Endereço não encontrado');
    } catch (e) {
      throw Exception('Não foi possível obter coordenadas para este endereço');
    }
  }

  // Melhorar o contexto do endereço
  String _enhanceAddressContext(String address) {
    // Verificar se já contém referências locais
    bool containsLocalContext = _knownNeighborhoods.any((neighborhood) => 
      address.toLowerCase().contains(neighborhood.toLowerCase())) ||
      _nearbyTowns.any((town) => 
        address.toLowerCase().contains(town.toLowerCase()));
    
    // Se não tiver contexto local, adicionar Lajedo
    if (!containsLocalContext) {
      return '$address, Lajedo, Pernambuco, Brasil';
    }
    
    return address;
  }

  // Verificar se o endereço está próximo de Lajedo
  bool _isWithinLajedoRegion(double latitude, double longitude) {
    // Calcular distância do centro de Lajedo
    double distance = _calculateDistance(
      lajedoCenter.latitude, 
      lajedoCenter.longitude, 
      latitude, 
      longitude
    );
    
    // Raio de 20 km para considerar como região de Lajedo
    return distance <= 20.0;
  }
  
  
  // Calcular pontos intermediários para waypoints
  List<String> _calculateIntermediatePoints(
  double startLat, double startLng, double endLat, double endLng
) {
  List<String> waypoints = [];
  
  // Adicionar 1-2 pontos intermediários em rotas longas
  double distance = _calculateDistance(startLat, startLng, endLat, endLng);
  
  if (distance > 1.0) {  // Se a distância for maior que 1km
    // Adicionar um ponto a 1/3 do caminho
    double lat1 = startLat + (endLat - startLat) / 3;
    double lng1 = startLng + (endLng - startLng) / 3;
    waypoints.add('$lat1,$lng1');
    
    // Adicionar outro ponto a 2/3 do caminho
    double lat2 = startLat + 2 * (endLat - startLat) / 3;
    double lng2 = startLng + 2 * (endLng - startLng) / 3;
    waypoints.add('$lat2,$lng2');
  }
  
  return waypoints;
}
  
  // Calcula a rota entre dois pontos usando o Google Directions API
  Future<RouteInfo> calculateRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng
  ) async {
    try {
      // Validar se pontos estão na região de Lajedo
      if (!_isWithinLajedoRegion(startLat, startLng) || 
          !_isWithinLajedoRegion(endLat, endLng)) {
        throw Exception('Rota fora da região de Lajedo');
      }
      
      // Calcular pontos intermediários para melhorar a precisão da rota
      List<String> waypoints = _calculateIntermediatePoints(
        startLat, startLng, endLat, endLng
      );
      
      // Construir string de waypoints se houver pontos intermediários
      String waypointsParam = '';
      if (waypoints.isNotEmpty) {
        waypointsParam = '&waypoints=optimize:true|' + waypoints.join('|');
      }
      
      // Lista para armazenar pontos da polyline
      List<LatLng> polylineCoordinates = [];
      
      // Fazer requisição direta à API Directions e decodificar as polylines
      final String directionsUrl = 
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=$startLat,$startLng'
          '&destination=$endLat,$endLng'
          '&mode=driving'
          '&alternatives=false'
          '&avoid=highways,ferries'
          '&overview=full'
          '&units=metric'
          '$waypointsParam'
          '&language=pt-BR'
          '&key=$_apiKey';
      
      final response = await http.get(Uri.parse(directionsUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isEmpty) {
            throw Exception('Nenhuma rota encontrada');
          }
          
          final route = routes[0];
          final leg = route['legs'][0];
          
          // Obter o polyline codificado
          final polylineEncoded = route['overview_polyline']['points'];
          
          // Decodificar o polyline
          List<PointLatLng> decodedPoints = _polylinePoints.decodePolyline(polylineEncoded);
          
          // Converter para lista de LatLng
          polylineCoordinates = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
          
          // Extrair distância e duração
          final distanceValue = leg['distance']['value'] / 1000.0; // Converter para km
          final durationValue = leg['duration']['value'] / 60.0; // Converter para minutos
          
          // Calcular preço estimado
          double basePrice = 5.0;
          double pricePerKm = 2.0;
          double estimatedPrice = basePrice + (distanceValue * pricePerKm);
          
          return RouteInfo(
            polylinePoints: polylineCoordinates,
            distance: distanceValue,
            duration: durationValue,
            estimatedPrice: estimatedPrice,
          );
        } else {
          throw Exception('Falha na API de Directions: ${data['status']}');
        }
      } else {
        throw Exception('Falha na requisição HTTP: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback para método alternativo em caso de erro
      return _calculateRouteFallback(startLat, startLng, endLat, endLng);
    }
  }

  
  
  // Método de fallback para cálculo de rota (usando algoritmo de grade simples)
  Future<RouteInfo> _calculateRouteFallback(
    double startLat, double startLng, double endLat, double endLng
  ) async {
    // Criar uma rota mais realista usando uma abordagem de grade de ruas
    List<LatLng> points = [];
    
    // Adicionar ponto inicial
    points.add(LatLng(startLat, startLng));
    
    // Calcular distância direta
    double directDistance = _calculateDistance(startLat, startLng, endLat, endLng);
    
    // Determinar se a rota é mais horizontal ou vertical
    bool isMoreHorizontal = (endLng - startLng).abs() > (endLat - startLat).abs();
    
    if (isMoreHorizontal) {
      // Para rotas mais horizontais, primeiro movimentar horizontalmente
      double midLng = startLng + (endLng - startLng) * 0.5;
      points.add(LatLng(startLat, midLng));
      points.add(LatLng(startLat + (endLat - startLat) * 0.5, midLng));
      points.add(LatLng(startLat + (endLat - startLat) * 0.8, midLng + (endLng - midLng) * 0.5));
    } else {
      // Para rotas mais verticais, primeiro movimentar verticalmente
      double midLat = startLat + (endLat - startLat) * 0.5;
      points.add(LatLng(midLat, startLng));
      points.add(LatLng(midLat, startLng + (endLng - startLng) * 0.5));
      points.add(LatLng(midLat + (endLat - midLat) * 0.5, startLng + (endLng - startLng) * 0.8));
    }
    
    // Adicionar ponto final
    points.add(LatLng(endLat, endLng));
    
    // Estimar distância da rota (30% mais longa que a linha reta)
    double routeDistance = directDistance * 1.3;
    
    // Estimar duração (30 km/h em média)
    double durationMinutes = (routeDistance / 30) * 60;
    
    // Calcular preço estimado
    double basePrice = 5.0; // Taxa base
    double pricePerKm = 2.0; // Preço por km
    double estimatedPrice = basePrice + (routeDistance * pricePerKm);
    
    return RouteInfo(
      polylinePoints: points,
      distance: routeDistance,
      duration: durationMinutes,
      estimatedPrice: estimatedPrice,
    );
  }
  
  // Calcula a distância entre dois pontos em km usando a fórmula de Haversine
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const int earthRadius = 6371; // Raio da Terra em km
    
    // Converter graus para radianos
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    // Fórmula de Haversine
    double a = sin(dLat/2) * sin(dLat/2) +
               cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
               sin(dLon/2) * sin(dLon/2);
    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    double distance = earthRadius * c;
    
    return distance;
  }
  
  // Converte graus para radianos
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}

class RouteInfo {
  final List<LatLng> polylinePoints;
  final double distance;
  final double duration;
  final double estimatedPrice;

  RouteInfo({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.estimatedPrice,
  });
}