// Arquivo: lib/views/passenger/map_screen.dart
// Melhorias na interface do mapa

import 'package:app_moto_taxe/views/chat/chat_screen.dart';
import 'package:app_moto_taxe/views/payment/payment_confirmation_screen.dart';
import 'package:app_moto_taxe/views/shared/chat_icon_badge.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../core/services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  final LocationService _locationService = LocationService();
  late AnimationController _animationController;
  
  // Estados do mapa
  CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(-8.0476, -34.8770), // Centro de Recife como padrão
    zoom: 14.0,
  );
  
  // Marcadores e polylines
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  
  // Estado da UI
  bool _isSearchingDestination = false;
  bool _hasDestination = false;
  bool _isRequestingRide = false;
  bool _rideAccepted = false;
  bool _isMapLoaded = false;
  bool _isMapMoving = false;
  
  String _pickupAddress = "Sua localização atual";
  String _destinationAddress = "";
  String _driverName = "João Silva";
  String _driverRating = "4.8";
  String _vehicleInfo = "Honda CG 160";
  String _licensePlate = "ABC-1234";
  String _estimatedTime = "5 min";
  String _estimatedPrice = "R\$ 15,00";
  String _rideId = "ride-test-123"; // Adicione esta linha nas suas variáveis de estado
  
  // Tema do mapa
  bool _isDarkMode = false;
  
  // Controladores de texto
  final TextEditingController _destinationController = TextEditingController();
  
  // Posição atual
  Position? _currentPosition;
  
  // Para pesquisa de endereços recentes
  final List<Map<String, String>> _recentAddresses = [
    {"name": "Shopping Recife", "address": "Av. República do Líbano, 251, Recife"},
    {"name": "UFPE", "address": "Av. Prof. Moraes Rego, 1235, Recife"},
    {"name": "Marco Zero", "address": "R. do Bom Jesus, Recife"},
    {"name": "Aeroporto do Recife", "address": "Praça Ministro Salgado Filho, Recife"},
  ];
  
  // Para locais favoritos
  final Map<String, String> _favoriteLocations = {
    "home": "Rua da sua casa, 123, Recife",
    "work": "Av. do seu trabalho, 456, Recife",
  };
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      bool hasPermission = await _locationService.checkLocationPermission();
      
      if (!hasPermission) {
        hasPermission = await _locationService.requestLocationPermission();
        if (!hasPermission) {
          _showPermissionDialog();
          return;
        }
      }
      
      Position position = await _locationService.getCurrentLocation();
      String address = await _locationService.getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      setState(() {
        _currentPosition = position;
        _pickupAddress = address;
        _initialPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16.0,
        );
        
        // Adicionar círculo pulsante na posição atual
        _updateLocationCircle(position);
        
        // Adicionar marcador na posição atual
        _updateLocationMarker(position);
      });
      
      // Mover câmera para a posição atual com animação
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(_initialPosition));
      
      // Iniciar monitoramento de localização
      _locationService.getLocationUpdates().listen((position) {
        _updateCurrentLocation(position);
      });
    } catch (e) {
      print('Erro ao obter localização: $e');
      _showErrorSnackBar('Não foi possível obter sua localização. Verifique as permissões do app.');
    }
  }
  
  void _updateCurrentLocation(Position position) async {
    if (mounted) {
      setState(() {
        _currentPosition = position;
        
        // Atualizar círculo e marcador de localização atual
        _updateLocationCircle(position);
        _updateLocationMarker(position);
      });
      
      // Se não estiver em uma corrida, manter a câmera seguindo o usuário
      if (!_isMapMoving && !_isRequestingRide && !_rideAccepted) {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude))
        );
      }
    }
  }
  
  void _updateLocationCircle(Position position) {
    _circles.removeWhere((circle) => circle.circleId.value == 'currentLocationCircle');
    _circles.add(
      Circle(
        circleId: const CircleId('currentLocationCircle'),
        center: LatLng(position.latitude, position.longitude),
        radius: 50, // 50 metros
        fillColor: Colors.blue.withOpacity(0.2),
        strokeColor: Colors.blue,
        strokeWidth: 1,
      ),
    );
  }
  
  void _updateLocationMarker(Position position) async {
    _markers.removeWhere((marker) => marker.markerId.value == 'currentLocation');
    
    // Aqui você poderia criar um marcador customizado para a localização atual
    // Por enquanto, vamos usar o marcador padrão
    _markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: const InfoWindow(title: 'Sua localização'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }
  
  void _setDestination(String address) async {
    try {
      setState(() {
        _isSearchingDestination = false;
        // Mostrar indicador de carregamento
        _destinationAddress = "Buscando endereço...";
      });
      
      LatLng coordinates = await _locationService.getCoordinatesFromAddress(address);
      
      if (_currentPosition != null) {
        RouteInfo routeInfo = await _locationService.calculateRoute(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          coordinates.latitude,
          coordinates.longitude,
        );
        
        setState(() {
          _destinationAddress = address;
          _hasDestination = true;
          
          // Atualizar estimativas
          _estimatedTime = "${routeInfo.duration.toInt()} min";
          _estimatedPrice = "R\$ ${routeInfo.estimatedPrice.toStringAsFixed(2)}";
          
          // Adicionar marcador de destino com animação
          _markers.removeWhere((marker) => marker.markerId.value == 'destination');
          _markers.add(
            Marker(
              markerId: const MarkerId('destination'),
              position: coordinates,
              infoWindow: InfoWindow(title: 'Destino', snippet: address),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
          
          // Adicionar polyline entre origem e destino
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: routeInfo.polylinePoints,
              color: Colors.blue,
              width: 5,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Linha tracejada
            ),
          );
        });
        
        // Ajustar câmera para mostrar rota completa com animação
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            _boundsFromLatLngList(routeInfo.polylinePoints),
            100, // padding
          ),
        );
      }
    } catch (e) {
      print('Erro ao definir destino: $e');
      _showErrorSnackBar('Não foi possível encontrar este endereço. Tente novamente.');
      setState(() {
        _destinationAddress = "";
        _hasDestination = false;
      });
    }
  }
  
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissão de Localização'),
          content: const Text(
            'Para usar este app, precisamos da sua permissão de localização. '
            'Por favor, vá às configurações do app e permita o acesso à localização.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Configurações'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Voltar para a tela anterior
              },
            ),
          ],
        );
      },
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  LatLngBounds _boundsFromLatLngList(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    
    for (final point in points) {

      // Código corrigido removendo os operadores de exclamação desnecessários:
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }
    
    // Adicionar um pequeno buffer para garantir que os marcadores fiquem dentro dos limites
    final latBuffer = (maxLat! - minLat!) * 0.1;
    final lngBuffer = (maxLng! - minLng!) * 0.1;
    
    return LatLngBounds(
      southwest: LatLng(minLat - latBuffer, minLng - lngBuffer),
      northeast: LatLng(maxLat + latBuffer, maxLng + lngBuffer),
    );
  }
  
  void _toggleMapStyle() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    
    final GoogleMapController controller = await _controller.future;
    
    if (_isDarkMode) {
      // Carregar estilo escuro
      controller.setMapStyle('''
        [
          {
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#242f3e"
              }
            ]
          },
          {
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#746855"
              }
            ]
          },
          {
            "elementType": "labels.text.stroke",
            "stylers": [
              {
                "color": "#242f3e"
              }
            ]
          },
          {
            "featureType": "administrative.locality",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#d59563"
              }
            ]
          },
          {
            "featureType": "poi",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#d59563"
              }
            ]
          },
          {
            "featureType": "poi.park",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#263c3f"
              }
            ]
          },
          {
            "featureType": "poi.park",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#6b9a76"
              }
            ]
          },
          {
            "featureType": "road",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#38414e"
              }
            ]
          },
          {
            "featureType": "road",
            "elementType": "geometry.stroke",
            "stylers": [
              {
                "color": "#212a37"
              }
            ]
          },
          {
            "featureType": "road",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#9ca5b3"
              }
            ]
          },
          {
            "featureType": "road.highway",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#746855"
              }
            ]
          },
          {
            "featureType": "road.highway",
            "elementType": "geometry.stroke",
            "stylers": [
              {
                "color": "#1f2835"
              }
            ]
          },
          {
            "featureType": "road.highway",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#f3d19c"
              }
            ]
          },
          {
            "featureType": "transit",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#2f3948"
              }
            ]
          },
          {
            "featureType": "transit.station",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#d59563"
              }
            ]
          },
          {
            "featureType": "water",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#17263c"
              }
            ]
          },
          {
            "featureType": "water",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#515c6d"
              }
            ]
          },
          {
            "featureType": "water",
            "elementType": "labels.text.stroke",
            "stylers": [
              {
                "color": "#17263c"
              }
            ]
          }
        ]
      ''');
    } else {
      // Resetar para estilo padrão
      controller.setMapStyle(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: false, // Desativamos porque criamos nosso próprio marcador
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
            circles: _circles,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              setState(() {
                _isMapLoaded = true;
              });
              if (_isDarkMode) {
                _toggleMapStyle();
              }
            },
            onCameraMoveStarted: () {
              setState(() {
                _isMapMoving = true;
              });
            },
            onCameraIdle: () {
              setState(() {
                _isMapMoving = false;
              });
            },
          ),
          
          // Indicador de carregamento enquanto o mapa não está carregado
          if (!_isMapLoaded)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // Botões de controle no topo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botão de voltar
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 24,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  // Botões de controle do mapa
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botão para centralizar no usuário
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 24,
                        child: IconButton(
                          icon: Icon(Icons.my_location, color: Colors.blue),
                          onPressed: () async {
                            if (_currentPosition != null) {
                              final GoogleMapController controller = await _controller.future;
                              controller.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  16.0,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 8),
                      // Botão para alternar modo claro/escuro
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 24,
                        child: IconButton(
                          icon: Icon(
                            _isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
                            color: _isDarkMode ? Colors.orange : Colors.indigo,
                          ),
                          onPressed: _toggleMapStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // UI inferior (busca, confirmação, etc.)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCard(),
          ),
        ],
      ),
    );
  }

  // Método para construir o card inferior baseado no estado atual
  Widget _buildBottomCard() {
    if (_rideAccepted) {
      return _buildRideInProgressCard();
    } else if (_isRequestingRide) {
      return _buildSearchingDriverCard();
    } else if (_hasDestination) {
      return _buildConfirmRideCard();
    } else {
      return _buildSearchDestinationCard();
    }
  }
  
  // Card para busca de destino com melhorias visuais
  Widget _buildSearchDestinationCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de arrastar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              "Para onde vamos?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            // Campo de busca aprimorado
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                hintText: "Buscar destino",
                prefixIcon: Icon(Icons.search),
                suffixIcon: _destinationController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _destinationController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onTap: () {
                setState(() {
                  _isSearchingDestination = true;
                });
              },
              onChanged: (value) {
                // Atualizar estado para mostrar o botão de limpar
                setState(() {});
                // Aqui você poderia implementar uma busca em tempo real
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _setDestination(value);
                }
              },
            ),
            SizedBox(height: 8),
            // Lista de endereços recentes aprimorada
            if (_isSearchingDestination) ...[
              SizedBox(height: 8),
              Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 18, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      "Recentes",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              ..._recentAddresses.map((item) => _buildRecentLocationItem(
                item["name"]!,
                item["address"]!,
              )),
            ],
            SizedBox(height: 16),
            // Locais favoritos aprimorados
            Row(
              children: [
                Expanded(
                  child: _buildFavoriteLocationButton(
                    "Casa",
                    Icons.home,
                    Colors.blue[700]!,
                    _favoriteLocations["home"]!,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildFavoriteLocationButton(
                    "Trabalho",
                    Icons.work,
                    Colors.amber[700]!,
                    _favoriteLocations["work"]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Botão de local favorito aprimorado
  Widget _buildFavoriteLocationButton(
    String title,
    IconData icon,
    Color color,
    String address,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setDestination(address),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Item de local recente aprimorado
  Widget _buildRecentLocationItem(String name, String address) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.location_on, color: Colors.blue),
      ),
      title: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        address,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        _destinationController.text = address;
        _setDestination(address);
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  // Card para confirmar corrida aprimorado
  Widget _buildConfirmRideCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de arrastar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              "Confirmar Corrida",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            // Card de rota aprimorado
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Origem
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.my_location, color: Colors.blue),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pickupAddress,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  // Linha vertical conectora
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Row(
                      children: [
                        Container(
                          height: 30,
                          width: 2,
                          child: LayoutBuilder(builder: (context, constraints) {
                            return Flex(
                              children: List.generate(
                                (constraints.maxHeight / 5).floor(),
                                (index) => Container(
                                  height: 2,
                                  width: 2,
                                  color: Colors.grey,
                                  margin: EdgeInsets.symmetric(vertical: 1),
                                ),
                              ),
                              direction: Axis.vertical,
                              mainAxisSize: MainAxisSize.max,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  // Destino
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.location_on, color: Colors.red),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _destinationAddress,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, size: 20),
                        onPressed: () {
                          setState(() {
                            _hasDestination = false;
                            _destinationController.text = _destinationAddress;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Informações da corrida aprimoradas
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[700]!, Colors.blue[900]!],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRideInfoItem(
                    Icons.access_time,
                    "Tempo",
                    _estimatedTime,
                    Colors.white,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),_buildRideInfoItem(
                    Icons.attach_money,
                    "Preço",
                    _estimatedPrice,
                    Colors.white,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Método de pagamento aprimorado
            InkWell(
              onTap: () {
                // Abrir tela de métodos de pagamento
              },
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.payment, color: Colors.green),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Método de Pagamento",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Dinheiro",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // Botão de solicitar aprimorado
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isRequestingRide = true;
                });
                // Simular encontrar motorista após 5 segundos
                Future.delayed(Duration(seconds: 5), () {
                  if (mounted) {
                    setState(() {
                      _rideAccepted = true;
                      _isRequestingRide = false;
                    });
                  }
                });
              },
              child: Text(
                "Solicitar MotoApp",
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Item de informação de corrida (tempo, preço)
  Widget _buildRideInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
  
  // Card para procura de motorista aprimorado
  Widget _buildSearchingDriverCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de arrastar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Animação de procura
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 60 * (0.5 + _animationController.value * 0.5),
                      height: 60 * (0.5 + _animationController.value * 0.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.3),
                      ),
                      child: Icon(
                        Icons.motorcycle,
                        color: Colors.blue[700],
                        size: 32,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Text(
              "Procurando motorista...",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Estamos buscando o motorista mais próximo de você",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            // Informações da rota
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Destino",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _destinationAddress,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Botão de cancelar aprimorado
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isRequestingRide = false;
                });
              },
              child: Text(
                "Cancelar",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red[700],
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red[300]!),
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Card para corrida em andamento aprimorado
  Widget _buildRideInProgressCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de arrastar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Informações do motorista
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _driverName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              _driverRating,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Botões de comunicação
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: IconButton(
                          icon: Icon(Icons.phone, color: Colors.green, size: 20),
                          onPressed: () {
                            // Ligar para o motorista
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: IconButton(
                          icon: Icon(Icons.message, color: Colors.blue, size: 20),
                          onPressed: () {
                            ChatIconBadge(
                              rideId: _rideId,
                              onPressed: () {
                                if (_rideId.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        rideId: _rideId,
                                        otherUserName: _driverName,
                                        otherUserImage: null,
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Informações do veículo
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildVehicleInfoItem(
                    Icons.motorcycle,
                    "Moto",
                    _vehicleInfo,
                  ),
                  _buildVehicleInfoItem(
                    Icons.confirmation_number,
                    "Placa",
                    _licensePlate,
                  ),
                  _buildVehicleInfoItem(
                    Icons.access_time,
                    "Chegada",
                    _estimatedTime,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Status da corrida
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Motorista a caminho",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${_estimatedTime} para chegar",
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Barra de progresso melhorada
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.3, // Progresso da corrida (0.0 a 1.0)
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Destino
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.location_on, color: Colors.red),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Destino",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _destinationAddress,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Botão de emergência melhorado
            OutlinedButton.icon(
              icon: Icon(Icons.emergency, color: Colors.red[700]),
              label: Text(
                "Emergência",
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                // Mostrar opções de emergência
                _showEmergencyDialog();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                side: BorderSide(color: Colors.red[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentConfirmationScreen(
                      rideId: _rideId,
                      amount: double.parse(_estimatedPrice), // Converter para double se necessário
                      driverName: _driverName,
                      originAddress: _pickupAddress,
                      destinationAddress: _destinationAddress,
                    ),
                  ),
                );
              },
  child: Text("Efetuar Pagamento"),
  style: ElevatedButton.styleFrom(
    minimumSize: Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),
          ],
        ),
      ),
      
    );
  }
  
  // Item de informação do veículo
  Widget _buildVehicleInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[700], size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  // Diálogo de emergência
  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.emergency, color: Colors.red),
              SizedBox(width: 8),
              Text('Opções de Emergência'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.phone_forwarded, color: Colors.red[700]),
                title: Text('Ligar para Emergência (190)'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar ligação para 190
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.share_location, color: Colors.orange[700]),
                title: Text('Compartilhar Localização'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar compartilhamento de localização
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.grey[700]),
                title: Text('Cancelar Corrida'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _rideAccepted = false;
                    _isRequestingRide = false;
                    _hasDestination = true;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}