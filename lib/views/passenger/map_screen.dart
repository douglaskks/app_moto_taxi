// Arquivo: lib/views/passenger/map_screen.dart

import 'dart:convert';
import 'dart:math';

import 'package:app_moto_taxe/core/utils/ride_test_helper.dart';
import 'package:app_moto_taxe/views/chat/chat_screen.dart';
import 'package:app_moto_taxe/views/passenger/rate_driver_screen.dart';
import 'package:app_moto_taxe/views/payment/payment_confirmation_screen.dart';
import 'package:app_moto_taxe/views/shared/chat_icon_badge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../core/services/location_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/bloc/ride/ride_bloc.dart';
import '../../controllers/bloc/ride/ride_event.dart';
import '../../controllers/bloc/ride/ride_state.dart';
import '../../core/services/realtime_database_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  // Modificar o uso do controlador do mapa - não usar Completer
  GoogleMapController? mapController;
  final LocationService _locationService = LocationService();
  late AnimationController _animationController;
  
  // Adicionar RideBloc
  late RideBloc _rideBloc;

  String _selectedPaymentMethod = 'Dinheiro'; // Valor padrão

  
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
  bool _isLoading = true;
  
  String _pickupAddress = "Sua localização atual";
  String _destinationAddress = "";
  String _driverName = "João Silva";
  String _driverRating = "4.8";
  String _vehicleInfo = "Honda CG 160";
  String _licensePlate = "ABC-1234";
  String _estimatedTime = "5 min";
  String _estimatedPrice = "R\$ 15,00";
  String _rideId = "ride-test-123";

  Timer? _debounce;

  Marker? _driverMarker;
  LatLng? _previousDriverPosition;
  BitmapDescriptor? _driverIcon;
  StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;
  
  // Informações de rota
  double _estimatedDistance = 0.0;
  double _estimatedDuration = 0.0;
  
  // Tema do mapa
  bool _isDarkMode = false;
  
  // Controladores de texto
  final TextEditingController _destinationController = TextEditingController();
  
  // Posição atual
  Position? _currentPosition;
  
  // Para pesquisa de endereços recentes
  List<Map<String, String>> _recentAddresses = [
    {"name": "Shopping Recife", "address": "Av. República do Líbano, 251, Recife"},
  ];

  List<Map<String, String?>> _placePredictions = [];
  final _placesService = GoogleMapsPlaces(apiKey: 'AIzaSyBgm2hoaSCfPQr_nW_JwDgVXnpR5AwOZEY');
  
  // Para locais favoritos
  final Map<String, String> _favoriteLocations = {
    "home": "Rua da sua casa, 123, Recife",
    "work": "Av. do seu trabalho, 456, Recife",
  };
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar o RideBloc
    _rideBloc = BlocProvider.of<RideBloc>(context);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Inicializar o mapa com a localização atual usando o método do código menor
    _determinePosition();
    _loadCustomMarkerIcons();
  }
  
 @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _debounce?.cancel();
    _animationController.dispose();
    _destinationController.dispose();
    if (mapController != null) {
      mapController!.dispose();
    }
    super.dispose();
  }
  
  // Método para determinar a posição atual, usando o padrão do código que funciona
  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Verificar se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Serviços de localização desativados. Por favor, ative o GPS do seu dispositivo.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Verificar permissões de localização
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permissão de localização negada Não conseguimos acessar sua localização.');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obter a posição atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      // Obter endereço a partir das coordenadas
      String address = await _locationService.getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _pickupAddress = address;
          _initialPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          );
          _isLoading = false;
        });
        
        // Adicionar um marcador na localização atual
        _updateLocationMarker(position);
        _updateLocationCircle(position);
        
        // Mover a câmera para a posição atual
        if (mapController != null) {
          _moveToCurrentLocation();
        }
        
        // Iniciar monitoramento contínuo de localização
        _startLocationUpdates();
      }
      
    } catch (e) {
      print("Erro ao obter localização: $e");
      _showError('Erro de localização Não foi possível determinar sua localização: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCustomMarkerIcons() async {
    _driverIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2.5),
      'lib/assets/images/motorcycle_marker.png',
    );
  }

  // Iniciar rastreamento do motorista quando a corrida for aceita
void _startDriverTracking(String driverId) {
  _driverLocationSubscription?.cancel();
  
  _driverLocationSubscription = FirebaseFirestore.instance
      .collection('drivers')
      .doc(driverId)
      .snapshots()
      .listen((snapshot) {
    if (snapshot.exists && mounted) {
      final data = snapshot.data() as Map<String, dynamic>;
      if (data.containsKey('latitude') && data.containsKey('longitude')) {
        final lat = data['latitude'] as double;
        final lng = data['longitude'] as double;
        final newPosition = LatLng(lat, lng);
        
        _animateDriverMovement(newPosition);
      }
    }
  });
}

// Animar movimento do motorista
void _animateDriverMovement(LatLng newPosition) {
  if (!mounted) return;
  
  // Calcular rotação (direção) se tiver posição anterior
  double rotation = 0.0;
  if (_previousDriverPosition != null) {
    rotation = _calculateBearing(
      _previousDriverPosition!.latitude,
      _previousDriverPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude
    );
  }
  
  setState(() {
    _markers.removeWhere((marker) => marker.markerId.value == 'driver');
    _markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: newPosition,
        rotation: rotation,
        icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: const InfoWindow(title: 'Seu motorista'),
      ),
    );
  });
  
  // Se estiver em uma corrida ativa, focar o mapa no motorista
  if (_rideAccepted && mapController != null) {
    mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(newPosition, 16),
    );
  }
  
  _previousDriverPosition = newPosition;
}

// Calcular o ângulo (bearing) entre duas coordenadas
double _calculateBearing(double startLat, double startLng, double endLat, double endLng) {
  double toRadians(double degree) {
    return degree * (pi / 180.0);
  }
  
  double toDegrees(double radian) {
    return radian * (180.0 / pi);
  }
  
  final startLatRad = toRadians(startLat);
  final startLngRad = toRadians(startLng);
  final endLatRad = toRadians(endLat);
  final endLngRad = toRadians(endLng);
  
  double y = sin(endLngRad - startLngRad) * cos(endLatRad);
  double x = cos(startLatRad) * sin(endLatRad) -
      sin(startLatRad) * cos(endLatRad) * cos(endLngRad - startLngRad);
  double bearing = toDegrees(atan2(y, x));
  
  return (bearing + 360) % 360;
}

  void _showPaymentMethodDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Método de Pagamento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            title: const Row(
              children: [
                Icon(Icons.money, color: Colors.green),
                SizedBox(width: 10),
                Text('Dinheiro'),
              ],
            ),
            value: 'Dinheiro',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            title: const Row(
              children: [
                Icon(Icons.credit_card, color: Colors.blue),
                SizedBox(width: 10),
                Text('Cartão de Crédito'),
              ],
            ),
            value: 'Cartão de Crédito',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            title: const Row(
              children: [
                Icon(Icons.pix, color: Colors.purple),
                SizedBox(width: 10),
                Text('PIX'),
              ],
            ),
            value: 'PIX',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}
  
  void _startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen(_updateCurrentLocation);
  }
  
  void _updateCurrentLocation(Position position) {
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _updateLocationCircle(position);
        _updateLocationMarker(position);
      });
      
      // Mover a câmera apenas se não estiver em uma corrida e não estiver movendo o mapa manualmente
      if (!_isMapMoving && !_isRequestingRide && !_rideAccepted && mapController != null) {
        _moveToCurrentLocation();
      }
    }
  }
  
  void _moveToCurrentLocation() {
    if (mapController != null && _currentPosition != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        ),
      );
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

  void _showCancellationDialog() {
  final TextEditingController reasonController = TextEditingController();
  String selectedReason = "Mudei de ideia";
  
  final List<String> commonReasons = [
    "Mudei de ideia",
    "Espera muito longa",
    "Escolhi outro meio de transporte",
    "Motorista muito distante",
    "Preço muito alto",
    "Erro ao solicitar corrida"
  ];
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Cancelar Corrida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por que você está cancelando?'),
            SizedBox(height: 16),
            
            // Lista de motivos comuns
            Container(
              height: 200,
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: commonReasons.length,
                itemBuilder: (context, index) {
                  final reason = commonReasons[index];
                  return RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value!;
                        reasonController.text = "";
                      });
                    },
                  );
                },
              ),
            ),
            
            // Opção para motivo personalizado
            RadioListTile<String>(
              title: Text("Outro motivo"),
              value: "Outro",
              groupValue: selectedReason == "Outro" || reasonController.text.isNotEmpty ? "Outro" : selectedReason,
              onChanged: (value) {
                setState(() {
                  selectedReason = value!;
                });
              },
            ),
            
            // Campo de texto para motivo personalizado
            if (selectedReason == "Outro")
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: "Digite seu motivo",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('VOLTAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              String finalReason = selectedReason;
              if (selectedReason == "Outro" && reasonController.text.isNotEmpty) {
                finalReason = reasonController.text;
              }
              
              Navigator.of(context).pop();
              _cancelRide(finalReason);
            },
            child: Text('CANCELAR CORRIDA'),
          ),
        ],
      ),
    ),
  ).then((_) {
    // Liberar o controlador após o diálogo ser fechado
    reasonController.dispose();
  });
}
  
  void _updateLocationMarker(Position position) {
    _markers.removeWhere((marker) => marker.markerId.value == 'currentLocation');
    _markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: const InfoWindow(title: 'Sua localização'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }
  
  void _setDestination(String address, [LatLng? coordinates]) async {
  try {
    setState(() {
      _isSearchingDestination = false;
      _destinationAddress = "Buscando endereço...";
    });
    
    // Use as coordenadas fornecidas ou busque através do endereço
    LatLng locationCoordinates;
    if (coordinates != null) {
      // Use as coordenadas fornecidas diretamente
      locationCoordinates = coordinates;
    } else {
      // Obter coordenadas do endereço
      locationCoordinates = await _locationService.getCoordinatesFromAddress(address);
    }
    
    // Resto do método permanece o mesmo
    if (_currentPosition != null) {
      RouteInfo routeInfo = await _locationService.calculateRoute(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        locationCoordinates.latitude,
        locationCoordinates.longitude,
      );
      
      setState(() {
        _destinationAddress = address;
        _hasDestination = true;
        
        _estimatedTime = "${routeInfo.duration.toInt()} min";
        _estimatedPrice = "R\$ ${routeInfo.estimatedPrice.toStringAsFixed(2)}";
        _estimatedDistance = routeInfo.distance;
        _estimatedDuration = routeInfo.duration;
        
        _markers.removeWhere((marker) => marker.markerId.value == 'destination');
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: locationCoordinates,
            infoWindow: InfoWindow(title: 'Destino', snippet: address),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
        
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: routeInfo.polylinePoints,
            color: Colors.blue,
            width: 5,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      });
      
      // Ajustar câmera para mostrar rota completa
      if (mapController != null) {
        try {
          mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(
              _boundsFromLatLngList(routeInfo.polylinePoints),
              100, // padding
            ),
          );
        } catch (e) {
          print('Erro ao ajustar câmera: $e');
        }
      }
    }
  } catch (e) {
    print('Erro ao definir destino: $e');
    _showError('Não foi possível encontrar este endereço. Tente novamente.');
    setState(() {
      _destinationAddress = "";
      _hasDestination = false;
    });
  }
}
  
  // Método para solicitar corrida usando o BLoC
  void _requestRide() {
  if (_currentPosition == null) {
    _showError('Não foi possível obter sua localização atual.');
    return;
  }
  
  if (!_hasDestination || _destinationAddress.isEmpty) {
    _showError('Por favor, informe o destino antes de solicitar a corrida.');
    return;
  }
  
  // Extrair valor numérico do preço estimado
  double priceValue = double.parse(
    _estimatedPrice.replaceAll('R\$ ', '').replaceAll(',', '.')
  );
  
  // Disparar evento para solicitar corrida com o método de pagamento selecionado
  _rideBloc.add(
    RequestRide(
      pickup: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      pickupAddress: _pickupAddress,
      destination: _markers.firstWhere((m) => m.markerId.value == 'destination').position,
      destinationAddress: _destinationAddress,
      paymentMethod: _selectedPaymentMethod, // Usando o método selecionado
      estimatedPrice: priceValue,
      estimatedDistance: _estimatedDistance,
      estimatedDuration: _estimatedDuration,
    ),
  );
  
  // Atualizar UI
  setState(() {
    _isRequestingRide = true;
  });
}

  
  // Método para cancelar corrida
  void _cancelRide(String reason) {
    if (_rideId.isNotEmpty) {
      _rideBloc.add(
        CancelRideRequest(
          rideId: _rideId,
          reason: reason,
        ),
      );
    }
    
    setState(() {
      _isRequestingRide = false;
      _rideAccepted = false;
    });
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
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
  
  LatLngBounds _boundsFromLatLngList(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    
    for (final point in points) {
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
    
    if (mapController != null) {
      try {
        if (_isDarkMode) {
          // Carregar estilo escuro
          mapController!.setMapStyle('''
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
              }
            ]
          ''');
        } else {
          // Resetar para estilo padrão
          mapController!.setMapStyle(null);
        }
      } catch (e) {
        print('Erro ao aplicar estilo do mapa: $e');
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return BlocListener<RideBloc, RideState>(
    listener: (context, state) {
      if (state is RequestingRide) {
        // Já lidamos com isso no botão
      } else if (state is SearchingDriver) {
        setState(() {
          _isRequestingRide = true;
          _rideAccepted = false;
          _rideId = state.rideId;
        });
      } else if (state is DriverAccepted) {
        setState(() {
          _isRequestingRide = false;
          _rideAccepted = true;
          _rideId = state.rideId;
          _driverName = state.driverName;
          _driverRating = state.driverRating.toString();
          _vehicleInfo = state.vehicleModel;
          _licensePlate = state.licensePlate;
          _estimatedTime = "${state.estimatedArrivalTime.toInt()} min";
        });
      } else if (state is RideInProgress) {
        setState(() {
          _rideAccepted = true;
          _isRequestingRide = false;
          _rideId = state.rideId;
          _driverName = state.driverName;
        });
      } else if (state is RideCompleted) {
        // Navegar para tela de pagamento
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentConfirmationScreen(
              rideId: state.rideId,
              amount: state.finalPrice,
              driverName: state.driverName,
              originAddress: _pickupAddress,
              destinationAddress: _destinationAddress,
            ),
          ),
        ).then((_) {
          // Depois que o pagamento for concluído, mostrar a tela de avaliação
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RateDriverScreen(
                rideId: state.rideId,
                driverName: state.driverName,
                driverId: state.driverId,
              ),
            ),
          );
        });
      } else if (state is RideCancelled) {
        setState(() {
          _isRequestingRide = false;
          _rideAccepted = false;
        });
        
        _showError('Corrida cancelada: ${state.reason}');
      } else if (state is RideError) {
        _showError(state.message);
        setState(() {
          _isRequestingRide = false;
        });
      }
    },
    child: Scaffold(
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
          children: [
            // Restante do código permanece o mesmo...
              // Google Map
              GoogleMap(
                initialCameraPosition: _initialPosition,
                myLocationEnabled: true,
                myLocationButtonEnabled: false, // Desativar o botão padrão para usar o nosso próprio
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                compassEnabled: true,
                markers: _markers,
                polylines: _polylines,
                circles: _circles,
                onMapCreated: (GoogleMapController controller) {
                  print('Mapa criado com sucesso!');
                  setState(() {
                    mapController = controller;
                    _isMapLoaded = true;
                  });
                  if (_isDarkMode) {
                    _toggleMapStyle();
                  }
                  
                  // Mover para a localização atual se já estiver disponível
                  if (_currentPosition != null) {
                    _moveToCurrentLocation();
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
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
                              icon: const Icon(Icons.my_location, color: Colors.blue),
                              onPressed: () {
                                if (_currentPosition != null) {
                                  _moveToCurrentLocation();
                                } else {
                                  _determinePosition();
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
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

  // Método para adicionar um endereço aos recentes
void _addToRecentAddresses(String name, String address) {
  // Verificar se já existe
  bool exists = _recentAddresses.any((item) => 
    item['address'] == address || item['name'] == name);
  
  // Se não existir, adicionar ao início da lista
  if (!exists) {
    // Criar uma nova lista com o novo item no início
    final newList = [{'name': name, 'address': address}, ..._recentAddresses];
    
    // Limitar o tamanho da lista (opcional)
    if (newList.length > 5) {
      newList.removeRange(5, newList.length);
    }
    
    setState(() {
      // Substitui a lista inteira em vez de tentar modificar a lista final
      _recentAddresses.clear();
      _recentAddresses.addAll(newList);
    });
    
    // Salvar para persistência
    _saveRecentAddresses();
  }
}
  
  // Card para busca de destino com melhorias visuais
  Widget _buildSearchDestinationCard() {
  return Card(
    margin: EdgeInsets.zero,
    elevation: 8,
    shape: const RoundedRectangleBorder(
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
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            "Para onde vamos?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Campo de busca aprimorado
          TextField(
            controller: _destinationController,
            decoration: InputDecoration(
              hintText: "Buscar destino",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _destinationController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _destinationController.clear();
                        _clearPlacePredictions();
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onTap: () {
              setState(() {
                _isSearchingDestination = true;
              });
            },
            onChanged: (value) {
              // Cancela o timer atual se ele ainda estiver ativo
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              
              // Inicia um novo timer de 500ms
              _debounce = Timer(const Duration(milliseconds: 500), () {
                if (value.length > 2) {
                  // Buscar previsões a partir de 3 caracteres
                  _getPlacePredictions(value);
                } else {
                  _clearPlacePredictions();
                }
              });
              setState(() {});
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _setDestination(value);
              }
            },
          ),
          const SizedBox(height: 8),
          
          // Lista de previsões de lugares
          if (_placePredictions.isNotEmpty) ...[
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _placePredictions.length,
                  itemBuilder: (context, index) {
                    final prediction = _placePredictions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.blue),
                      title: Text(
                        prediction['main_text'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(prediction['secondary_text'] ?? ''),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      onTap: () async {
                        final placeId = prediction['place_id'];
                        if (placeId != null) {
                          // Opção 1: Obter detalhes do local para ter coordenadas precisas
                          try {
                            final details = await _placesService.getDetailsByPlaceId(placeId);
                            if (details.status == 'OK') {
                              final location = details.result.geometry?.location;
                              if (location != null) {
                                // Use as coordenadas para configurar o destino
                                final address = prediction['full_text'] ?? "${prediction['main_text']} ${prediction['secondary_text']}";
                                _destinationController.text = address;
                                _setDestination(address, LatLng(location.lat, location.lng));
                                _addToRecentAddresses(
                                  prediction['main_text'] ?? '',
                                  address,
                                );
                              }
                            }
                          } catch (e) {
                            print('Erro ao obter detalhes do local: $e');
                            // Falha silenciosa, use o método atual como fallback
                            _destinationController.text = "${prediction['main_text']} ${prediction['secondary_text']}";
                            _setDestination(_destinationController.text);
                          }
                        } else {
                          // Fallback para o método atual
                          _destinationController.text = "${prediction['main_text']} ${prediction['secondary_text']}";
                          _setDestination(_destinationController.text);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ]
          // Lista de endereços recentes aprimorada
          else if (_isSearchingDestination && _destinationController.text.isEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Row(
                children: [
                  Icon(Icons.history, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
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
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _recentAddresses.length,
                  itemBuilder: (context, index) {
                    final item = _recentAddresses[index];
                    return _buildRecentLocationItem(
                      item["name"]!,
                      item["address"]!,
                    );
                  },
                ),
              ),
            ),
          ],
          
          // Locais favoritos aprimorados (somente mostrar se não estiver pesquisando)
          if (!_isSearchingDestination || 
              (_isSearchingDestination && _destinationController.text.isEmpty && _recentAddresses.isEmpty)) ...[
            const SizedBox(height: 16),
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
                const SizedBox(width: 16),
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
        ],
      ),
    ),
  );
}

// Método para limpar as previsões
void _clearPlacePredictions() {
  setState(() {
    _placePredictions = [];
  });
}

// Método para buscar previsões do Google Places API
Future<void> _getPlacePredictions(String input) async {
  if (input.isEmpty) {
    _clearPlacePredictions();
    return;
  }
  
  print("Buscando previsões para: $input");
  
  try {
    PlacesAutocompleteResponse response = await _placesService.autocomplete(
      input,
      language: 'pt-BR',
      components: [Component(Component.country, 'br')],
      location: _currentPosition != null 
          ? Location(lat: _currentPosition!.latitude, lng: _currentPosition!.longitude)
          : null,
      radius: _currentPosition != null ? 10000 : null,
    );

    print("Status da API: ${response.status}");
    print("Número de previsões: ${response.predictions.length}");
    
    if (response.status == 'OK' && response.predictions.isNotEmpty) {
      response.predictions.forEach((prediction) {
        print("Previsão: ${prediction.description}");
      });
      
      setState(() {
        _placePredictions = response.predictions.map((prediction) {
          final String description = prediction.description ?? '';
          
          final mainText = prediction.structuredFormatting?.mainText ?? 
                         description.split(',').first.trim();
          final secondaryText = prediction.structuredFormatting?.secondaryText ?? 
                             (description.contains(',') ? 
                             description.substring(description.indexOf(',') + 1).trim() : '');
          
          return {
            'place_id': prediction.placeId,
            'main_text': mainText,
            'secondary_text': secondaryText,
            'full_text': description,
          };
        }).toList();
        
        print("_placePredictions atualizado: ${_placePredictions.length} itens");
      });
    } else if (response.status != 'OK') {
      print('Erro na API Places: ${response.status}, ${response.errorMessage}');
      _clearPlacePredictions();
    } else {
      print('API retornou status OK mas sem previsões');
      _clearPlacePredictions();
    }
  } catch (e) {
    print('Erro ao buscar previsões de lugares: $e');
    _clearPlacePredictions();
  }
}

void _saveRecentAddresses() async {
  try {
    // Implementação usando SharedPreferences
    // Adicione a dependência: shared_preferences: ^2.0.0
    final prefs = await SharedPreferences.getInstance();
    // Converter a lista para formato JSON
    final List<String> encodedList = _recentAddresses
        .map((item) => jsonEncode(item))
        .toList();
    // Salvar no SharedPreferences
    await prefs.setStringList('recent_addresses', encodedList);
  } catch (e) {
    print('Erro ao salvar endereços recentes: $e');
  }
}

// E adicione um método para carregar no initState
void _loadRecentAddresses() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? encodedList = prefs.getStringList('recent_addresses');
    if (encodedList != null) {
      setState(() {
        _recentAddresses = encodedList
            .map((item) => Map<String, String>.from(jsonDecode(item)))
            .toList();
      });
    }
  } catch (e) {
    print('Erro ao carregar endereços recentes: $e');
  }
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
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
        child: const Icon(Icons.location_on, color: Colors.blue),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w500),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
      // Card para confirmar corrida aprimorado (continuação)
  Widget _buildConfirmRideCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      shape: const RoundedRectangleBorder(
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
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              "Confirmar Corrida",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Card de rota aprimorado
            Container(
              padding: const EdgeInsets.all(16),
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
                        child: const Icon(Icons.my_location, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pickupAddress,
                          style: const TextStyle(fontSize: 16),
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
                              // ignore: sort_child_properties_last
                              children: List.generate(
                                (constraints.maxHeight / 5).floor(),
                                (index) => Container(
                                  height: 2,
                                  width: 2,
                                  color: Colors.grey,
                                  margin: const EdgeInsets.symmetric(vertical: 1),
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
                        child: const Icon(Icons.location_on, color: Colors.red),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _destinationAddress,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
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
            const SizedBox(height: 16),
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
                  ),
                  _buildRideInfoItem(
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
              onTap: _showPaymentMethodDialog,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.all(16),
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
                        color: _selectedPaymentMethod == 'Dinheiro' 
                            ? Colors.green.shade100
                            : _selectedPaymentMethod == 'Cartão de Crédito'
                                ? Colors.blue.shade100
                                : Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _selectedPaymentMethod == 'Dinheiro'
                            ? Icons.money
                            : _selectedPaymentMethod == 'Cartão de Crédito'
                                ? Icons.credit_card
                                : Icons.pix,
                        color: _selectedPaymentMethod == 'Dinheiro'
                            ? Colors.green
                            : _selectedPaymentMethod == 'Cartão de Crédito'
                                ? Colors.blue
                                : Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                            _selectedPaymentMethod,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Botão de solicitar aprimorado - MODIFICADO para usar o BLoC
            ElevatedButton(
              onPressed: () {
                // Chamar o método que dispara o evento do BLoC
                _requestRide();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              child: const Text(
                "Solicitar MotoApp",
                style: TextStyle(fontSize: 18, color: Colors.white),
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
  // Modificação para o método _buildSearchingDriverCard() 
// Adicione esse código no arquivo map_screen.dart

Widget _buildSearchingDriverCard() {
  return Card(
    margin: EdgeInsets.zero,
    elevation: 8,
    shape: const RoundedRectangleBorder(
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
            margin: const EdgeInsets.only(bottom: 16),
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
          const SizedBox(height: 20),
          const Text(
            "Procurando motorista...",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Estamos buscando o motorista mais próximo de você",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          // Informações da rota
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 12),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Botão de cancelar aprimorado - MODIFICADO para usar o BLoC
          OutlinedButton(
            onPressed: () {
              _showCancellationDialog();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red[300]!),
              minimumSize: Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              "Cancelar",
              style: TextStyle(
                fontSize: 18,
                color: Colors.red[700],
              ),
            ),
          ),
          
          // Adicionar isso para incluir o modo de teste (apenas em ambiente de desenvolvimento)
          const SizedBox(height: 16),
          // Adicionar botão de teste (remover para produção)
          FutureBuilder(
            future: Future.delayed(Duration.zero), // Para acessar o context com segurança
            builder: (context, snapshot) {
              return Visibility(
                // Use true para modo de desenvolvimento, false para produção
                visible: true,
                child: RideTestHelper.buildTestModeButton(context, _rideId),
              );
            },
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
      shape: const RoundedRectangleBorder(
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
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Informações do motorista
            Container(
              padding: const EdgeInsets.all(16),
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
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _driverName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
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
                          icon: const Icon(Icons.phone, color: Colors.green, size: 20),
                          onPressed: () {
                            // Ligar para o motorista
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: IconButton(
                          icon: const Icon(Icons.message, color: Colors.blue, size: 20),
                          onPressed: () {
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
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Informações do veículo
            Container(
              padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            // Status da corrida
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
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
                  const SizedBox(height: 8),
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
            const SizedBox(height: 16),
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
                    child: const Icon(Icons.location_on, color: Colors.red),
                  ),
                  const SizedBox(width: 16),
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
                          style: const TextStyle(
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
            const SizedBox(height: 16),
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
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: Colors.red[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentConfirmationScreen(
                      rideId: _rideId,
                      amount: double.parse(_estimatedPrice.replaceAll("R\$ ", "").replaceAll(",", ".")),
                      driverName: _driverName,
                      originAddress: _pickupAddress,
                      destinationAddress: _destinationAddress,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Efetuar Pagamento"),
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
          style: const TextStyle(
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
          title: const Row(
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
                title: const Text('Ligar para Emergência (190)'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar ligação para 190
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.share_location, color: Colors.orange[700]),
                title: const Text('Compartilhar Localização'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar compartilhamento de localização
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.grey[700]),
                title: const Text('Cancelar Corrida'),
                onTap: () {
                  Navigator.pop(context);
                  _cancelRide("Emergência - Corrida cancelada pelo passageiro");
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Fechar'),
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