// Arquivo: lib/core/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math';

class RouteInfo {
  final double distance; // em km
  final double duration; // em minutos
  final double estimatedPrice; // em reais
  final List<LatLng> polylinePoints;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.estimatedPrice,
    required this.polylinePoints,
  });
}

class LocationService {
  // Verificar permissão de localização
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar se os serviços de localização estão habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Verificar a permissão de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || 
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Solicitar permissão de localização
  Future<bool> requestLocationPermission() async {
    LocationPermission permission;

    // Verificar os serviços de localização
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Poderia mostrar um diálogo solicitando ao usuário para habilitar os serviços
      return false;
    }

    // Solicitar permissão
    permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Obter localização atual
  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
  }

  // Obter endereço a partir de coordenadas
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
      }
      return "Endereço não encontrado";
    } catch (e) {
      return "Erro ao buscar endereço";
    }
  }

  // Obter coordenadas a partir de endereço
  Future<LatLng> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        return LatLng(locations[0].latitude, locations[0].longitude);
      }
      
      // Coordenadas padrão se não encontrar o endereço
      return LatLng(-8.0476, -34.8770); // Centro de Recife
    } catch (e) {
      // Coordenadas padrão em caso de erro
      return LatLng(-8.0476, -34.8770); // Centro de Recife
    }
  }

  // Calcular rota, distância, tempo e preço estimado - Versão atualizada
  // Calcular rota, distância, tempo e preço estimado
// Calcular rota, distância, tempo e preço estimado
// Calcular rota, distância, tempo e preço estimado
// Calcular rota, distância, tempo e preço estimado
Future<RouteInfo> calculateRoute(
  double originLat,
  double originLng,
  double destLat,
  double destLng,
) async {
  try {
    // Usar PolylinePoints para obter a rota - formato correto conforme exemplo
    PolylinePoints polylinePoints = PolylinePoints();
    
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: "AIzaSyBgm2hoaSCfPQr_nW_JwDgVXnpR5AwOZEY", // Sua chave de API
      request: PolylineRequest(
        origin: PointLatLng(originLat, originLng),
        destination: PointLatLng(destLat, destLng),
        mode: TravelMode.driving,
      ),
    );

    // Converter pontos da polyline para LatLng
    List<LatLng> polylineCoordinates = [];
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      // Caso a API não retorne pontos, usar o método alternativo
      return _createSimpleRoute(originLat, originLng, destLat, destLng);
    }

    // Calcular distância (método simples, a API do Google seria mais precisa)
    double distance = _calculateDistance(
      originLat, originLng, destLat, destLng
    );
    
    // Estimar duração (assumindo velocidade média de 30 km/h)
    double durationInMinutes = (distance / 30) * 60;
    
    // Calcular preço (R$ 2,00 de bandeirada + R$ 2,50 por km)
    double estimatedPrice = 2.0 + (distance * 2.5);

    return RouteInfo(
      distance: distance,
      duration: durationInMinutes,
      estimatedPrice: estimatedPrice,
      polylinePoints: polylineCoordinates,
    );
  } catch (e) {
    print('Erro ao calcular rota: $e');
    // Em caso de erro, usar o método alternativo
    return _createSimpleRoute(originLat, originLng, destLat, destLng);
  }
}

// Método alternativo que cria uma rota simples sem chamar a API
Future<RouteInfo> _createSimpleRoute(
  double originLat, 
  double originLng,
  double destLat,
  double destLng,
) async {
  // Cálculo simples sem depender do polyline_points
  double distance = _calculateDistance(
    originLat, originLng, destLat, destLng
  );
  
  double durationInMinutes = (distance / 30) * 60;
  double estimatedPrice = 2.0 + (distance * 2.5);
  
  // Criar uma linha reta simples entre os pontos
  List<LatLng> polylineCoordinates = [
    LatLng(originLat, originLng),
    LatLng(destLat, destLng),
  ];
  
  // Adicionar pontos intermediários para suavizar a linha
  double latDiff = (destLat - originLat) / 4;
  double lngDiff = (destLng - originLng) / 4;
  
  for (int i = 1; i < 4; i++) {
    polylineCoordinates.insert(i, LatLng(
      originLat + (latDiff * i),
      originLng + (lngDiff * i),
    ));
  }
  
  return RouteInfo(
    distance: distance,
    duration: durationInMinutes,
    estimatedPrice: estimatedPrice,
    polylinePoints: polylineCoordinates,
  );
}

// Método alternativo que cria uma rota simples sem chamar a API
/*Future<RouteInfo> _createSimpleRoute(
  double originLat, 
  double originLng,
  double destLat,
  double destLng,
) async {
  // Cálculo simples sem depender do polyline_points
  double distance = _calculateDistance(
    originLat, originLng, destLat, destLng
  );
  
  double durationInMinutes = (distance / 30) * 60;
  double estimatedPrice = 2.0 + (distance * 2.5);
  
  // Criar uma linha reta simples entre os pontos
  List<LatLng> polylineCoordinates = [
    LatLng(originLat, originLng),
    LatLng(destLat, destLng),
  ];
  
  // Adicionar pontos intermediários para suavizar a linha
  double latDiff = (destLat - originLat) / 4;
  double lngDiff = (destLng - originLng) / 4;
  
  for (int i = 1; i < 4; i++) {
    polylineCoordinates.insert(i, LatLng(
      originLat + (latDiff * i),
      originLng + (lngDiff * i),
    ));
  }
  
  return RouteInfo(
    distance: distance,
    duration: durationInMinutes,
    estimatedPrice: estimatedPrice,
    polylinePoints: polylineCoordinates,
  );
}*/

// Método alternativo mais simples que não depende da API (privado para evitar duplicação)
/*Future<RouteInfo> _calculateRouteFallback(
  double originLat, 
  double originLng,
  double destLat,
  double destLng,
) async {
  try {
    // Cálculo mais simples sem depender do polyline_points
    double distance = _calculateDistance(
      originLat, originLng, destLat, destLng
    );
    
    double durationInMinutes = (distance / 30) * 60;
    double estimatedPrice = 2.0 + (distance * 2.5);
    
    // Criar uma linha reta simples entre os pontos
    List<LatLng> polylineCoordinates = [
      LatLng(originLat, originLng),
      LatLng(destLat, destLng),
    ];
    
    // Adicionar pontos intermediários para suavizar a linha
    double latDiff = (destLat - originLat) / 4;
    double lngDiff = (destLng - originLng) / 4;
    
    for (int i = 1; i < 4; i++) {
      polylineCoordinates.insert(i, LatLng(
        originLat + (latDiff * i),
        originLng + (lngDiff * i),
      ));
    }
    
    return RouteInfo(
      distance: distance,
      duration: durationInMinutes,
      estimatedPrice: estimatedPrice,
      polylinePoints: polylineCoordinates,
    );
  } catch (e) {
    print('Erro no fallback de rota: $e');
    // Retornar algo muito simples em caso de erro
    return RouteInfo(
      distance: 5.0, // 5 km como fallback
      duration: 15.0, // 15 minutos como fallback
      estimatedPrice: 15.0, // R$ 15,00 como fallback
      polylinePoints: [
        LatLng(originLat, originLng),
        LatLng(destLat, destLng),
      ],
    );
  }
}*/

// Método alternativo mais simples que não depende da API
/*Future<RouteInfo> calculateRouteFallback(
  double originLat, 
  double originLng,
  double destLat,
  double destLng,
) async {
  try {
    // Cálculo mais simples sem depender do polyline_points
    double distance = _calculateDistance(
      originLat, originLng, destLat, destLng
    );
    
    double durationInMinutes = (distance / 30) * 60;
    double estimatedPrice = 2.0 + (distance * 2.5);
    
    // Criar uma linha reta simples entre os pontos
    List<LatLng> polylineCoordinates = [
      LatLng(originLat, originLng),
      LatLng(destLat, destLng),
    ];
    
    // Adicionar pontos intermediários para suavizar a linha
    double latDiff = (destLat - originLat) / 4;
    double lngDiff = (destLng - originLng) / 4;
    
    for (int i = 1; i < 4; i++) {
      polylineCoordinates.insert(i, LatLng(
        originLat + (latDiff * i),
        originLng + (lngDiff * i),
      ));
    }
    
    return RouteInfo(
      distance: distance,
      duration: durationInMinutes,
      estimatedPrice: estimatedPrice,
      polylinePoints: polylineCoordinates,
    );
  } catch (e) {
    print('Erro no fallback de rota: $e');
    // Retornar algo muito simples em caso de erro
    return RouteInfo(
      distance: 5.0, // 5 km como fallback
      duration: 15.0, // 15 minutos como fallback
      estimatedPrice: 15.0, // R$ 15,00 como fallback
      polylinePoints: [
        LatLng(originLat, originLng),
        LatLng(destLat, destLng),
      ],
    );
  }
}

  // Método alternativo mais simples caso você continue tendo problemas
  Future<RouteInfo> calculateRouteFallback(
    double originLat, 
    double originLng,
    double destLat,
    double destLng,
  ) async {
    try {
      // Cálculo mais simples sem depender do polyline_points
      double distance = _calculateDistance(
        originLat, originLng, destLat, destLng
      );
      
      double durationInMinutes = (distance / 30) * 60;
      double estimatedPrice = 2.0 + (distance * 2.5);
      
      // Criar uma linha reta simples entre os pontos
      List<LatLng> polylineCoordinates = [
        LatLng(originLat, originLng),
        LatLng(destLat, destLng),
      ];
      
      // Opcionalmente, você pode adicionar pontos intermediários para suavizar a linha
      // Isso é um método simples que não usa a API do Google
      double latDiff = (destLat - originLat) / 4;
      double lngDiff = (destLng - originLng) / 4;
      
      for (int i = 1; i < 4; i++) {
        polylineCoordinates.insert(i, LatLng(
          originLat + (latDiff * i),
          originLng + (lngDiff * i),
        ));
      }
      
      return RouteInfo(
        distance: distance,
        duration: durationInMinutes,
        estimatedPrice: estimatedPrice,
        polylinePoints: polylineCoordinates,
      );
    } catch (e) {
      print('Erro no fallback de rota: $e');
      // Retornar algo muito simples em caso de erro
      return RouteInfo(
        distance: 5.0, // 5 km como fallback
        duration: 15.0, // 15 minutos como fallback
        estimatedPrice: 15.0, // R$ 15,00 como fallback
        polylinePoints: [
          LatLng(originLat, originLng),
          LatLng(destLat, destLng),
        ],
      );
    }
  }*/

  // Cálculo simplificado de distância usando a fórmula de Haversine
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
        
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;
    
    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
  
  // Monitorar mudanças de localização em tempo real
  Stream<Position> getLocationUpdates() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // atualizar a cada 10 metros
      ),
    );
  }
}