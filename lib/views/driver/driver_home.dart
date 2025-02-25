// Arquivo: lib/views/driver/driver_home.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../controllers/bloc/auth/auth_bloc.dart';
import '../../controllers/bloc/auth/auth_event.dart';
import '../../core/services/realtime_database_service.dart';
import 'ride_request_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_profile_screen.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({Key? key}) : super(key: key);

  @override
  _DriverHomeState createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> with WidgetsBindingObserver {
  final Completer<GoogleMapController> _controller = Completer();
  final RealtimeDatabaseService _databaseService = RealtimeDatabaseService();
  
  // Estados
  bool _isOnline = false;
  bool _isLoading = false;
  bool _locationPermissionGranted = false;
  
  // Localização
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  
  // Informações do motorista
  final String _vehicleType = "Moto";
  double _totalEarningsToday = 0.0;
  int _ridesCompletedToday = 0;
  double _rating = 4.8;
  
  // Marcadores no mapa
  final Set<Marker> _markers = {};
  
  // Controlador de animação para o botão online
  late AnimationController _pulseAnimationController;
  
  CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(-8.0476, -34.8770), // Centro de Recife como padrão
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
    _loadDriverData();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStream?.cancel();
    if (_isOnline) {
      _goOffline();
    }
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quando o app vai para segundo plano e o motorista está online,
    // garantir que ele continue recebendo atualizações
    if (state == AppLifecycleState.paused && _isOnline) {
      // Potencialmente notificar o backend que o app está em segundo plano
    }
    
    // Quando o app volta para primeiro plano e o motorista está online,
    // verificar se ainda há localização e atualizar
    if (state == AppLifecycleState.resumed && _isOnline) {
      _checkLocationAndUpdatePosition();
    }
  }
  
  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLoading = true;
    });
    
    bool serviceEnabled;
    LocationPermission permission;
    
    // Verificar se os serviços de localização estão habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showDialog(
        'Localização Desativada',
        'Os serviços de localização estão desativados. Por favor, ative-os para continuar.',
        'Abrir Configurações',
        () => Geolocator.openLocationSettings(),
      );
      setState(() {
        _isLoading = false;
        _locationPermissionGranted = false;
      });
      return;
    }
    
    // Verificar permissão de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showDialog(
          'Permissão Negada',
          'Sem permissão de localização, não é possível receber corridas.',
          'Solicitar Novamente',
          _checkLocationPermission,
        );
        setState(() {
          _isLoading = false;
          _locationPermissionGranted = false;
        });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showDialog(
        'Permissão Negada Permanentemente',
        'As permissões de localização foram negadas permanentemente. Configure-as nas configurações do app.',
        'Abrir Configurações',
        () => Geolocator.openAppSettings(),
      );
      setState(() {
        _isLoading = false;
        _locationPermissionGranted = false;
      });
      return;
    }
    
    // Permissão concedida, obter localização atual
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _initialPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15.0,
        );
        _locationPermissionGranted = true;
        _updateDriverMarker(position);
      });
    } catch (e) {
      print('Erro ao obter localização: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _loadDriverData() async {
    // Normalmente você carregaria esses dados do Firestore ou outra fonte
    // Para simplificar, estamos usando dados simulados
    setState(() {
      _totalEarningsToday = 120.50;
      _ridesCompletedToday = 8;
      _rating = 4.8;
    });
  }
  
  void _toggleOnlineStatus() async {
    if (!_locationPermissionGranted) {
      _checkLocationPermission();
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_isOnline) {
        await _goOffline();
      } else {
        await _goOnline();
      }
    } catch (e) {
      _showSnackbar('Erro ao mudar status: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _goOnline() async {
    // Verificar se temos localização atual
    if (_currentPosition == null) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition();
      } catch (e) {
        _showSnackbar('Erro ao obter localização. Tente novamente.');
        return;
      }
    }
    
    // Atualizar status online no Firebase
    await _databaseService.setDriverAvailability(true, _vehicleType);
    
    // Iniciar monitoramento de localização
    _startLocationTracking();
    
    setState(() {
      _isOnline = true;
    });
    
    _showSnackbar('Você está online! Aguardando corridas...');
  }
  
  Future<void> _goOffline() async {
    // Atualizar status offline no Firebase
    await _databaseService.setDriverAvailability(false, _vehicleType);
    
    // Parar monitoramento de localização
    _stopLocationTracking();
    
    setState(() {
      _isOnline = false;
    });
    
    _showSnackbar('Você está offline.');
  }
  
  void _startLocationTracking() {
    // Cancelar stream existente se houver
    _positionStream?.cancel();
    
    // Iniciar monitoramento de localização
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // atualizar a cada 10 metros
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        _updateDriverMarker(position);
      });
      
      // Enviar localização atualizada para o Firebase
      _databaseService.updateDriverLocation(
        position.latitude, 
        position.longitude
      );
      
      // Atualizar câmera do mapa
      _updateCameraPosition(position);
    });
    
    // Iniciar também o serviço para monitoramento em background
    _databaseService.startDriverLocationTracking();
  }
  
  void _stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _databaseService.stopDriverLocationTracking();
  }
  
  void _updateDriverMarker(Position position) {
    _markers.removeWhere((marker) => marker.markerId.value == 'driver');
    _markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Sua localização'),
      ),
    );
  }
  
  Future<void> _updateCameraPosition(Position position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(
      LatLng(position.latitude, position.longitude)
    ));
  }
  
  void _checkLocationAndUpdatePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _updateDriverMarker(position);
      });
      
      // Atualizar no Firebase
      if (_isOnline) {
        _databaseService.updateDriverLocation(
          position.latitude, 
          position.longitude
        );
      }
      
      // Atualizar câmera
      _updateCameraPosition(position);
    } catch (e) {
      print('Erro ao atualizar localização: $e');
    }
  }
  
  void _navigateToEarnings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DriverEarningsScreen()),
    );
  }
  
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DriverProfileScreen()),
    );
  }
  
  void _showRideRequestDemo() {
    // Para demonstração, fingimos receber uma solicitação de corrida
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideRequestScreen(
          passengerId: 'user123',
          passengerName: 'Maria Silva',
          passengerRating: 4.7,
          pickupAddress: 'Av. Agamenon Magalhães, 123, Recife',
          destinationAddress: 'Shopping Recife, Av. República do Líbano, 251',
          estimatedDistance: 5.2,
          estimatedDuration: 15,
          estimatedFare: 18.50,
          onAccept: () {
            // Lógica para aceitar corrida
            Navigator.pop(context);
            _showSnackbar('Corrida aceita! Dirija até o passageiro.');
          },
          onReject: () {
            // Lógica para rejeitar corrida
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
  
  void _showDialog(String title, String message, String buttonText, Function() onPressed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(buttonText),
              onPressed: () {
                Navigator.of(context).pop();
                onPressed();
              },
            ),
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          _locationPermissionGranted ? 
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ) :
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Permissão de localização necessária',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Para receber corridas, precisamos da sua localização.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _checkLocationPermission,
                  child: Text('Permitir Localização'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Barra superior com estatísticas do dia
          SafeArea(
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Olá, Motorista!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          SizedBox(width: 4),
                          Text(
                            _rating.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        'Ganhos Hoje',
                        'R\$ ${_totalEarningsToday.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Corridas',
                        '$_ridesCompletedToday',
                        Icons.motorcycle,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Status',
                        _isOnline ? 'Online' : 'Offline',
                        _isOnline ? Icons.visibility : Icons.visibility_off,
                        _isOnline ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Botão de ficar online/offline
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: _isLoading ?
              CircularProgressIndicator() :
              GestureDetector(
                onTap: _toggleOnlineStatus,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline ? Colors.green : Colors.grey[300],
                    boxShadow: [
                      BoxShadow(
                        color: _isOnline ? 
                          Colors.green.withOpacity(0.3) : 
                          Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isOnline ? Icons.pause : Icons.play_arrow,
                          size: 50,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          _isOnline ? 'FICAR OFFLINE' : 'FICAR ONLINE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Menu lateral
          Positioned(
            top: 130,
            left: 16,
            child: Column(
              children: [
                _buildMenuButton(
                  Icons.account_circle,
                  'Perfil',
                  _navigateToProfile,
                ),
                SizedBox(height: 16),
                _buildMenuButton(
                  Icons.bar_chart,
                  'Ganhos',
                  _navigateToEarnings,
                ),
                SizedBox(height: 16),
                _buildMenuButton(
                  Icons.headset_mic,
                  'Suporte',
                  () => _showSnackbar('Suporte não implementado'),
                ),
                SizedBox(height: 16),
                // Botão demo para mostrar uma solicitação de corrida
                _isOnline ? _buildMenuButton(
                  Icons.notifications_active,
                  'Demo',
                  _showRideRequestDemo,
                  Colors.orange,
                ) : SizedBox.shrink(),
              ],
            ),
          ),
          
          // Botão de sair/logout
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(Icons.logout, color: Colors.red),
                  onPressed: () {
                    // Desconectar e limpar
                    if (_isOnline) {
                      _goOffline();
                    }
                    context.read<AuthBloc>().add(LoggedOut());
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
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
      ),
    );
  }
  
  Widget _buildMenuButton(IconData icon, String label, VoidCallback onTap, [Color? color]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color ?? Colors.blue[700]),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color ?? Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}