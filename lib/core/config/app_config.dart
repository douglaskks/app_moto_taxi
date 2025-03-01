// Novo arquivo: lib/core/config/app_config.dart
class AppConfig {
  // Chave de API do Google Maps
  static const String googleMapsApiKey = "AIzaSyBgm2hoaSCfPQr_nW_JwDgVXnpR5AwOZEY";
  
  // Configurações de localização padrão
  static const double defaultLatitude = -8.0476;  // Centro de Recife
  static const double defaultLongitude = -34.8770;
  
  // Configurações de preço
  static const double basePrice = 2.0;           // Preço base (bandeirada)
  static const double pricePerKm = 2.5;          // Preço por km
  static const double averageSpeedKmh = 30.0;    // Velocidade média para cálculo de tempo
}