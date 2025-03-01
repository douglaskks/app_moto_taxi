// Arquivo: lib/views/ride_in_progress_screen.dart

import 'package:app_moto_taxe/views/chat/chat_screen.dart';
import 'package:app_moto_taxe/views/ride_rating_screen.dart';
import 'package:app_moto_taxe/views/shared/chat_icon_badge.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../models/ride_request.dart';

class RideInProgressScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideData;
  final RideRequest? request;
  
  // Construtor com request como parâmetro opcional
  const RideInProgressScreen({
    super.key,
    required this.rideId,
    required this.rideData,
    this.request,
  });

  @override
  State<RideInProgressScreen> createState() => _RideInProgressScreenState();
}

class _RideInProgressScreenState extends State<RideInProgressScreen> {
  // Controladores e estado
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

    // Adicionar esta variável aqui, junto com as outras variáveis de estado
  bool _isCancellationDialogShowing = false;

    @override
  void initState() {
    super.initState();
    _initializeRideData();
    _startLocationTracking();
    _setupRideStatusListener(); // Adicionar esta linha
  }
  
  // Localização e stream
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  
  // Coordenadas importantes
  late LatLng _pickupLocation;
  late LatLng _destinationLocation;
  
  // Estado da viagem
  bool _isRideStarted = false;
  double _remainingDistance = 0.0;
  String _currentStatus = 'Dirigindo até o passageiro';
  bool _isMapLoaded = false;
  bool _isLoading = true;
  
  // Informações do passageiro e corrida
  String _passengerName = 'Passageiro';
  String _pickupAddress = '';
  String _destinationAddress = '';
  
  // Método para monitorar atualizações da corrida - mover para fora de _initializeRideData
  void _setupRideStatusListener() {
    FirebaseDatabase.instance.ref().child('rides/${widget.rideId}')
      .onValue.listen((event) {
        if (!mounted) return;
        
        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          final status = data['status'] as String?;
          
          if (status == 'cancelled') {
            // Corrida foi cancelada
            final cancelledBy = data['cancelled_by'] as String? ?? 'system';
            final reason = data['cancellation_reason'] as String? ?? 'Não especificado';
            
            // Mostrar diálogo apenas se foi cancelado pelo passageiro
            if (cancelledBy == 'passenger' && mounted) {
              _showCancellationDialog(reason);
            }
          }
        }
      }, onError: (error) {
        debugPrint("Erro ao monitorar status da corrida: $error");
      });
  }
  
  // Método para mostrar o diálogo de cancelamento - mover para fora de _initializeRideData
  void _showCancellationDialog(String reason) {
    // Verificar se já existe um diálogo aberto para evitar duplicação
    if (_isCancellationDialogShowing) return;
    
    setState(() {
      _isCancellationDialogShowing = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 10),
            Text('Corrida Cancelada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('O passageiro cancelou a corrida.'),
            SizedBox(height: 12),
            Text('Motivo:'),
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                reason,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fechar o diálogo
              Navigator.of(context).pop(); // Voltar para a tela anterior
            },
            child: Text('ENTENDI'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isCancellationDialogShowing = false;
        });
      }
    });
  }

  // Inicializar dados da corrida
  void _initializeRideData() {
    try {
      // Extrair coordenadas de pickup e destino
      _pickupLocation = LatLng(
        widget.rideData['pickup']['latitude'],
        widget.rideData['pickup']['longitude']
      );
      
      _destinationLocation = LatLng(
        widget.rideData['destination']['latitude'],
        widget.rideData['destination']['longitude']
      );
      
      // Extrair informações do passageiro
      _passengerName = widget.rideData['passenger_name'] ?? 'Passageiro';
      _pickupAddress = widget.rideData['pickup']['address'] ?? '';
      _destinationAddress = widget.rideData['destination']['address'] ?? '';
      
      // Adicionar marcadores ao mapa
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Local de Embarque', 
            snippet: _pickupAddress,
          ),
        )
      );
      
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destino', 
            snippet: _destinationAddress,
          ),
        )
      );

      // Concluir inicialização
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Usar logger em vez de print em produção
      debugPrint("RideInProgressScreen: Erro ao inicializar dados - $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Gerar rota no mapa
  // Gerar rota no mapa
// Gerar rota no mapa
Future<void> _generateRoute() async {
  try {
    // Se não temos nossa posição atual, não podemos gerar a rota
    if (_currentPosition == null) {
      debugPrint("RideInProgressScreen: Posição atual não disponível. Não é possível gerar rota.");
      return;
    }
    
    // Definir origem e destino com base no estado da viagem
    LatLng source = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    LatLng destination = _isRideStarted ? _destinationLocation : _pickupLocation;
    
    // Obter pontos da rota usando PolylinePoints
    PolylinePoints polylinePoints = PolylinePoints();
    
    try {
      // Formato correto da chamada com parâmetros nomeados
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: 'AIzaSyBgm2hoaSCfPQr_nW_JwDgVXnpR5AwOZEY',
        request: PolylineRequest(
          origin: PointLatLng(source.latitude, source.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );
      
      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              color: _isRideStarted ? Colors.blue : Colors.green,
              points: polylineCoordinates,
              width: 5,
            )
          );
        });
        
        // Ajustar o mapa para mostrar toda a rota
        if (_isMapLoaded) {
          _adjustMapToShowRoute(polylineCoordinates);
        }
      } else {
        debugPrint("RideInProgressScreen: API não retornou pontos - ${result.errorMessage}");
        
        // Criar linha reta simples como fallback
        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('direct_route'),
              color: _isRideStarted ? Colors.blue : Colors.green,
              points: [source, destination],
              width: 5,
            )
          );
        });
      }
    } catch (routeError) {
      debugPrint("RideInProgressScreen: Erro na API de rotas - $routeError");
      
      // Criar linha reta simples como fallback
      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('direct_route'),
            color: _isRideStarted ? Colors.blue : Colors.green,
            points: [source, destination],
            width: 5,
          )
        );
      });
    }
  } catch (e) {
    debugPrint("RideInProgressScreen: Erro geral ao gerar rota - $e");
  }
}
  
  // Ajustar mapa para mostrar toda a rota
  void _adjustMapToShowRoute(List<LatLng> points) async {
    if (points.isEmpty || !_isMapLoaded || !mounted) return;
    
    try {
      // Encontrar limites da rota
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;
      
      for (var point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
      
      // Adicionar padding
      double latPadding = (maxLat - minLat) * 0.2;
      double lngPadding = (maxLng - minLng) * 0.2;
      
      // Animar câmera
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - latPadding, minLng - lngPadding),
            northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
          ),
          50,
        ),
      );
    } catch (e) {
      debugPrint("RideInProgressScreen: Erro ao ajustar mapa - $e");
    }
  }

  // Iniciar monitoramento de localização
  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_updateLocation);
  }

  // Atualizar localização do motorista
  void _updateLocation(Position position) {
    if (!mounted) return;
    
    setState(() {
      _currentPosition = position;
      
      // Atualizar marcador do motorista
      _markers.removeWhere((marker) => marker.markerId.value == 'driver');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'Sua localização'),
          zIndex: 2,
        )
      );

      // Calcular distância restante
      _calculateRemainingDistance(position);
    });

    // Atualizar localização no Firebase
    _updateDriverLocationInFirebase(position);
    
    // Regenerar rota
    _generateRoute();
  }
  
  // Atualizar localização no Firebase
  void _updateDriverLocationInFirebase(Position position) {
    try {
      FirebaseDatabase.instance.ref()
        .child('rides/${widget.rideId}/driver_location')
        .update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'last_updated': ServerValue.timestamp,
        });
    } catch (e) {
      debugPrint("RideInProgressScreen: Erro ao atualizar localização no Firebase - $e");
    }
  }

  // Calcular distância até o destino atual
  void _calculateRemainingDistance(Position position) {
    try {
      if (!_isRideStarted) {
        // Distância até o local de embarque
        double distanceToPickup = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _pickupLocation.latitude,
          _pickupLocation.longitude,
        ) / 1000; // Converter para km
        
        _remainingDistance = distanceToPickup;

        // Atualizar status com base na distância
        if (distanceToPickup <= 0.1) {
          setState(() {
            _currentStatus = 'Você chegou! Aguarde o passageiro';
          });
        } else {
          setState(() {
            _currentStatus = 'Dirigindo até o passageiro (${distanceToPickup.toStringAsFixed(2)} km)';
          });
        }
      } else {
        // Distância até o destino final
        double distanceToDestination = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _destinationLocation.latitude,
          _destinationLocation.longitude,
        ) / 1000;
        
        _remainingDistance = distanceToDestination;
        
        // Atualizar status com base na distância
        if (distanceToDestination <= 0.1) {
          setState(() {
            _currentStatus = 'Você chegou ao destino!';
          });
        } else {
          setState(() {
            _currentStatus = 'Em viagem (${distanceToDestination.toStringAsFixed(2)} km restantes)';
          });
        }
      }
    } catch (e) {
      debugPrint("RideInProgressScreen: Erro ao calcular distância - $e");
    }
  }

  // Iniciar a corrida
  void _startRide() {
    try {
      // Atualizar status no Firebase
      FirebaseDatabase.instance.ref().child('rides/${widget.rideId}').update({
        'status': 'in_progress',
        'started_at': ServerValue.timestamp,
      });

      // Atualizar estado local
      setState(() {
        _isRideStarted = true;
        _currentStatus = 'Viagem iniciada';
      });
      
      // Atualizar rota para o destino final
      _generateRoute();
      
      // Notificar o usuário
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corrida iniciada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao iniciar corrida: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Finalizar a corrida
  // Substitua o método _endRide() atual por este:

void _endRide() async {
  try {
    setState(() {
      _isLoading = true;
    });
    
    // 1. Obter referência da corrida
    final rideRef = FirebaseDatabase.instance.ref().child('rides/${widget.rideId}');
    
    // 2. Obter dados completos da corrida para calcular valores finais
    final DataSnapshot rideSnapshot = await rideRef.get();
    if (!rideSnapshot.exists) {
      throw Exception('Corrida não encontrada');
    }
    
    final Map<String, dynamic> rideData = Map<String, dynamic>.from(rideSnapshot.value as Map);
    
    // 3. Calcular preço final (pode ser ajustado com base em diversos fatores)
    // Aqui estamos considerando o preço estimado + ajuste pelo tempo real
    double finalPrice = rideData['estimated_price'] ?? 0.0;
    
    // Calcular duração real da corrida
    final startedAt = rideData['started_at'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(rideData['started_at'] as int) 
        : DateTime.now().subtract(const Duration(minutes: 10)); // Fallback
    
    final durationInMinutes = DateTime.now().difference(startedAt).inMinutes;
    
    // Aplicar ajuste de preço baseado no tempo real vs. estimado
    if (rideData['estimated_duration'] != null) {
      final estimatedDuration = (rideData['estimated_duration'] as num).toDouble();
      if (durationInMinutes > estimatedDuration * 1.2) { // Se demorou 20% mais
        // Adicionar taxa extra por tempo excedente
        final extraMinutes = durationInMinutes - estimatedDuration;
        final extraCharge = extraMinutes * 0.5; // R$0.50 por minuto extra
        finalPrice += extraCharge;
      }
    }
    
    // 4. Atualizar corrida no Firebase
    await rideRef.update({
      'status': 'completed',
      'completed_at': ServerValue.timestamp,
      'final_price': finalPrice,
      'actual_duration_minutes': durationInMinutes,
    });
    
    setState(() {
      _isLoading = false;
    });
    
    // 5. Mostrar diálogo de confirmação
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Corrida Finalizada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Corrida finalizada com sucesso!'),
              const SizedBox(height: 12),
              Text(
                'Valor final: R\$ ${finalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green[700],
                ),
              ),
              if (rideData['estimated_price'] != null && rideData['estimated_price'] != finalPrice) ...[
                const SizedBox(height: 8),
                Text(
                  'Ajuste aplicado por tempo adicional',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                // Navegar para a tela de avaliação do passageiro (pelo motorista)
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RideRatingScreen(
                        rideId: widget.rideId,
                        userId: rideData['passenger_id'] ?? '',
                        evaluatorId: rideData['driver_id'] ?? '',
                        userName: rideData['passenger_name'] ?? 'Passageiro',
                        userPhoto: null, // Adicionar depois se disponível
                        isDriverRating: true, // Motorista avaliando passageiro
                      ),
                    ),
                  ).then((rated) {
                    // Se a avaliação foi concluída, voltar para a tela anterior
                    if (rated == true && mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                }
              },
              child: const Text('AVALIAR PASSAGEIRO'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Voltar para a tela anterior
              },
              child: const Text('PULAR'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao finalizar corrida: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRideStarted ? 'Viagem em Andamento' : 'Indo Buscar Passageiro'),
        backgroundColor: _isRideStarted ? Colors.blue : Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _pickupLocation,
                    zoom: 15.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    if (!_controller.isCompleted) {
                      _controller.complete(controller);
                    }
                    setState(() {
                      _isMapLoaded = true;
                    });
                    
                    // Gerar rota inicial quando o mapa for criado
                    if (_currentPosition != null) {
                      _generateRoute();
                    }
                  },
                ),
                
                // Botão de centralizar no mapa
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.blue),
                    onPressed: () async {
                      if (_currentPosition != null && _controller.isCompleted) {
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
                
                // Barra de informações inferior
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status da corrida e passageiro
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isRideStarted ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _isRideStarted ? Icons.directions_car : Icons.person_pin_circle,
                                color: _isRideStarted ? Colors.blue : Colors.green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentStatus,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Passageiro: $_passengerName',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Informações de endereço
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildAddressInfo(
                                'Local de embarque',
                                _pickupAddress,
                                Icons.my_location,
                                Colors.green,
                              ),
                              const Divider(height: 20),
                              _buildAddressInfo(
                                'Destino',
                                _destinationAddress,
                                Icons.location_on,
                                Colors.red,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Botões de ação
                        Row(
                          children: [
                            // Botão de iniciar/finalizar
                            Expanded(
                              child: !_isRideStarted
                                  ? ElevatedButton.icon(
                                      onPressed: _remainingDistance <= 0.1 ? _startRide : null,
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Iniciar Corrida'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        backgroundColor: Colors.green,
                                        disabledBackgroundColor: Colors.grey[300],
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: _remainingDistance <= 0.1 ? _endRide : null,
                                      icon: const Icon(Icons.stop),
                                      label: const Text('Finalizar Corrida'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        backgroundColor: Colors.red,
                                        disabledBackgroundColor: Colors.grey[300],
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Botões de comunicação
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.phone, color: Colors.white),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Ligando para o passageiro...")),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.message, color: Colors.white),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            rideId: widget.rideId,
                                            otherUserName: widget.rideData['passenger_name'] ?? 'Passageiro',
                                            otherUserImage: widget.rideData['passenger_photo'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Adicionando o parâmetro obrigatório onPressed
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: ChatIconBadge(
                                      rideId: widget.rideId,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatScreen(
                                              rideId: widget.rideId,
                                              otherUserName: widget.rideData['passenger_name'] ?? 'Passageiro',
                                              otherUserImage: widget.rideData['passenger_photo'],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),


                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  // Widget para exibir informações de endereço
  Widget _buildAddressInfo(String label, String address, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

