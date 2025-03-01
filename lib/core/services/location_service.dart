// lib/core/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';

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
  static const LatLng LAJEDO_CENTER = LatLng(-8.7891, -36.2448);

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
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );
    } catch (e) {
      print('Erro ao obter localização: $e');
      // Tentar com precisão reduzida como fallback
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
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
      print('Erro ao obter endereço: $e');
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
      print('Erro ao obter coordenadas: $e');
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
      LAJEDO_CENTER.latitude, 
      LAJEDO_CENTER.longitude, 
      latitude, 
      longitude
    );
    
    // Raio de 20 km para considerar como região de Lajedo
    return distance <= 20.0;
  }

  // Calcula a rota entre dois pontos (simulação simples)
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
      
      // Resto do método permanece igual ao original
      final int steps = 10; // Número de pontos intermediários
      List<LatLng> points = [];
      
      for (int i = 0; i <= steps; i++) {
        double fraction = i / steps;
        double lat = startLat + (endLat - startLat) * fraction;
        double lng = startLng + (endLng - startLng) * fraction;
        
        // Adicionar um pequeno ruído para simular uma rota real
        if (i > 0 && i < steps) {
          lat += (Random().nextDouble() - 0.5) * 0.001;
          lng += (Random().nextDouble() - 0.5) * 0.001;
        }
        
        points.add(LatLng(lat, lng));
      }
      
      // Calcular distância aproximada em quilômetros usando a fórmula de Haversine
      double distance = _calculateDistance(startLat, startLng, endLat, endLng);
      
      // Estimar duração (assumindo velocidade média de 30 km/h)
      double durationMinutes = (distance / 30) * 60;
      
      // Estimar preço (taxa base + preço por km)
      double basePrice = 5.0; // R$ 5,00 de taxa base
      double pricePerKm = 2.0; // R$ 2,00 por km
      double estimatedPrice = basePrice + (distance * pricePerKm);
      
      return RouteInfo(
        polylinePoints: points,
        distance: distance,
        duration: durationMinutes,
        estimatedPrice: estimatedPrice,
      );
    } catch (e) {
      print('Erro ao calcular rota: $e');
      throw Exception('Não foi possível calcular a rota');
    }
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