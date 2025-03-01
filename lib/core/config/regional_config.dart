// lib/core/config/regional_config.dart

class RegionalConfig {
  // Coordenadas centrais de Lajedo, PE
  static const double initialLatitude = -8.7891;
  static const double initialLongitude = -36.2448;
  
  // Configurações de raio de busca
  static const double maxDriverSearchRadius = 15.0; // km
  static const double defaultSearchRadius = 10.0; // km
  
  // Configurações de zoom do mapa
  static const double initialMapZoom = 14.0;
  static const double focusedMapZoom = 16.0;
  
  // Limites geográficos de Lajedo e região próxima
  static const double minLatitude = -8.8500;
  static const double maxLatitude = -8.7200;
  static const double minLongitude = -36.3200;
  static const double maxLongitude = -36.1700;
  
  // Configurações de preço (ajustado para cidade menor)
  static const double basefare = 4.00;
  static const double pricePerKm = 2.00;
  
  // Configurações de tempo
  static const int maxRideSearchTime = 240; // segundos (reduzido para cidade menor)
  static const int driverResponseTimeout = 90; // segundos
  
  // Método para validar se as coordenadas estão dentro da área de cobertura
  static bool isWithinCoverageArea(double latitude, double longitude) {
    return latitude >= minLatitude && 
           latitude <= maxLatitude && 
           longitude >= minLongitude && 
           longitude <= maxLongitude;
  }
  
  // Calcular distância máxima permitida entre passageiro e motorista
  static double calculateMaxAllowedDistance(double passengerLat, double passengerLng) {
    // Para cidades menores, pode ser interessante um raio menor
    return maxDriverSearchRadius;
  }
  
  // Descrição textual da região de cobertura
  static const String regionDescription = 'Lajedo e região metropolitana';
}