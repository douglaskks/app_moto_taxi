// Arquivo: lib/controllers/bloc/ride/ride_bloc.dart

import 'dart:async';
import 'dart:math';
import 'package:app_moto_taxe/core/services/user_statistics_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/realtime_database_service.dart';
import 'ride_event.dart';
import 'ride_state.dart';

class RideBloc extends Bloc<RideEvent, RideState> {
  final RealtimeDatabaseService _databaseService;
  final UserStatisticsService _statisticsService = UserStatisticsService();
  
  StreamSubscription? _rideSubscription;
  StreamSubscription? _driverLocationSubscription;
  Timer? _searchTimer;
  Timer? _rideTimer;
  Timer? _waitingTimer;
  
  String? _currentRideId;
  String? _currentDriverId;
  int _searchTimeElapsed = 0;
  int _rideTimeElapsed = 0;
  int _waitingTimeElapsed = 0;
  
  RideBloc(this._databaseService) : super(RideInitial()) {
    on<RequestRide>(_onRequestRide);
    on<CancelRideRequest>(_onCancelRideRequest);
    on<AcceptRide>(_onAcceptRide);
    on<UpdateRideStatus>(_onUpdateRideStatus);
    on<TrackRide>(_onTrackRide);
    on<StopTrackingRide>(_onStopTrackingRide);
    on<RateRide>(_onRateRide);
    
    // Registrar os novos eventos
    on<StartDriverTracking>(_onStartDriverTracking);
    on<StopDriverTracking>(_onStopDriverTracking);
    on<UpdateDriverLocation>(_onUpdateDriverLocation);
    
    // Registrar o método usando a sintaxe correta para métodos assíncronos
    on<RideUpdated>((event, emit) async {
      await _onRideUpdated(event, emit);
    });
  }
  
  void _onRequestRide(RequestRide event, Emitter<RideState> emit) async {
    emit(RequestingRide());
    
    try {
      print("RideBloc: Solicitando corrida...");
      final rideId = await _databaseService.requestRide(
        pickupLat: event.pickup.latitude,
        pickupLng: event.pickup.longitude,
        pickupAddress: event.pickupAddress,
        destinationLat: event.destination.latitude,
        destinationLng: event.destination.longitude,
        destinationAddress: event.destinationAddress,
        paymentMethod: event.paymentMethod,
        estimatedPrice: event.estimatedPrice,
        estimatedDistance: event.estimatedDistance,
        estimatedDuration: event.estimatedDuration,
      );
      
      print("RideBloc: Corrida solicitada com sucesso. ID: $rideId");
      
      _currentRideId = rideId;
      
      // Emitir estado de busca de motorista
      if (!emit.isDone) {
        emit(SearchingDriver(
          rideId: rideId,
          pickup: event.pickup,
          destination: event.destination,
          pickupAddress: event.pickupAddress,
          destinationAddress: event.destinationAddress,
          estimatedPrice: event.estimatedPrice,
        ));
      }
      
      // Iniciar timer para atualizar o tempo de busca
      _searchTimeElapsed = 0;
      _searchTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        _searchTimeElapsed++;
        
        if (state is SearchingDriver) {
          if (!emit.isDone) {
            emit((state as SearchingDriver).copyWith(
              searchTimeElapsed: _searchTimeElapsed
            ));
          } else {
            timer.cancel();
          }
        } else {
          // Se não estiver mais procurando, cancelar o timer
          timer.cancel();
        }
      });
      
      // Iniciar monitoramento da corrida
      add(TrackRide(rideId: rideId));
      
    } catch (e) {
      print("RideBloc: Erro ao solicitar corrida: $e");
      if (!emit.isDone) {
        emit(RideError("Erro ao solicitar corrida: ${e.toString()}"));
      }
    }
  }
  
  void _onCancelRideRequest(CancelRideRequest event, Emitter<RideState> emit) async {
    try {
      print("RideBloc: Cancelando corrida ${event.rideId}...");
      await _databaseService.cancelRideRequest(event.rideId, event.reason);
      
      _cleanupRideResources();
      
      if (!emit.isDone) {
        emit(RideCancelled(
          rideId: event.rideId,
          reason: event.reason,
          cancelledBy: 'passenger',
        ));
      }
      
      print("RideBloc: Corrida cancelada com sucesso");
    } catch (e) {
      print("RideBloc: Erro ao cancelar corrida: $e");
      if (!emit.isDone) {
        emit(RideError("Erro ao cancelar corrida: ${e.toString()}"));
      }
    }
  }
  
  void _onAcceptRide(AcceptRide event, Emitter<RideState> emit) async {
    try {
      print("RideBloc: Aceitando corrida ${event.rideId}...");
      await _databaseService.acceptRide(
        event.rideId, 
        event.estimatedArrivalTime
      );
      
      // A atualização do estado será feita via TrackRide quando
      // o Firebase enviar a notificação de mudança de status
      print("RideBloc: Corrida aceita com sucesso");
    } catch (e) {
      print("RideBloc: Erro ao aceitar corrida: $e");
      if (!emit.isDone) {
        emit(RideError("Erro ao aceitar corrida: ${e.toString()}"));
      }
    }
  }
  
  void _onUpdateRideStatus(UpdateRideStatus event, Emitter<RideState> emit) async {
    try {
      print("RideBloc: Atualizando status da corrida ${event.rideId} para ${event.status}...");
      await _databaseService.updateRideStatus(event.rideId, event.status);
      
      // A atualização do estado será feita via TrackRide quando
      // o Firebase enviar a notificação de mudança de status
      print("RideBloc: Status atualizado com sucesso");
    } catch (e) {
      print("RideBloc: Erro ao atualizar status da corrida: $e");
      if (!emit.isDone) {
        emit(RideError("Erro ao atualizar status da corrida: ${e.toString()}"));
      }
    }
  }
  
  void _onStartDriverTracking(StartDriverTracking event, Emitter<RideState> emit) {
    // Use logger em vez de print no futuro
    print("RideBloc: Iniciando rastreamento do motorista ${event.driverId}");
    
    _currentDriverId = event.driverId;
    
    // Cancelar assinatura anterior se existir
    _driverLocationSubscription?.cancel();
    
    // Iniciar nova assinatura para atualizações de localização
    _driverLocationSubscription = _databaseService
    .getDriverLocationStream(event.driverId)
    .listen(
      (locationData) {
        if (locationData != null) {
          // Verificar se o mapa contém os dados necessários
          if (locationData.containsKey('latitude') && 
              locationData.containsKey('longitude')) {
            
            // Extrair latitude e longitude do mapa
            double lat = locationData['latitude'];
            double lng = locationData['longitude'];
            
            // Criar um novo objeto LatLng com esses valores
            add(UpdateDriverLocation(
              driverId: event.driverId,
              location: LatLng(lat, lng),
            ));
          }
        }
      },
      onError: (error) {
        print("RideBloc: Erro ao monitorar localização do motorista: $error");
      }
    );
  }
  
  void _onStopDriverTracking(StopDriverTracking event, Emitter<RideState> emit) {
    print("RideBloc: Parando rastreamento do motorista");
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = null;
    _currentDriverId = null;
  }
  
  void _onUpdateDriverLocation(UpdateDriverLocation event, Emitter<RideState> emit) {
    print("RideBloc: Atualizando localização do motorista ${event.driverId}");
    
    // Verificar o estado atual e atualizar com a nova localização
    if (state is DriverAccepted && !emit.isDone) {
      final currentState = state as DriverAccepted;
      
      emit(currentState.copyWith(
        driverLocation: event.location,
        lastLocationUpdate: DateTime.now(),
      ));
    } 
    else if (state is DriverArrived && !emit.isDone) {
      final currentState = state as DriverArrived;
      
      emit(currentState.copyWith(
        driverLocation: event.location,
        lastLocationUpdate: DateTime.now(),
      ));
    }
    else if (state is RideInProgress && !emit.isDone) {
      final currentState = state as RideInProgress;
      
      // Calcular distância restante até o destino
      double distanceRemaining = _calculateDistance(
        event.location.latitude, 
        event.location.longitude,
        currentState.destination.latitude,
        currentState.destination.longitude,
      );
      
      // Estimar tempo restante com velocidade média de 30 km/h
      double timeRemaining = (distanceRemaining / 30) * 60; // em minutos
      
      // Calcular progresso da viagem
      double totalDistance = _calculateDistance(
        currentState.startLocation?.latitude ?? event.location.latitude,
        currentState.startLocation?.longitude ?? event.location.longitude,
        currentState.destination.latitude,
        currentState.destination.longitude,
      );
      
      double progress = totalDistance > 0 ? 
        (totalDistance - distanceRemaining) / totalDistance : 0.0;
      progress = progress.clamp(0.0, 1.0); // garantir que fique entre 0 e 1
      
      emit(currentState.copyWith(
        driverLocation: event.location,
        distanceRemaining: distanceRemaining,
        timeRemaining: timeRemaining,
        rideProgress: progress,
        lastLocationUpdate: DateTime.now(),
      ));
    }
  }
  
  void _onTrackRide(TrackRide event, Emitter<RideState> emit) {
    print("RideBloc: Iniciando monitoramento da corrida ${event.rideId}...");
    
    // Cancelar assinatura existente
    _rideSubscription?.cancel();
    
    // Iniciar monitoramento da corrida
    _rideSubscription = _databaseService
      .getCurrentRideStream(event.rideId)
      .listen(
        (rideData) {
          if (rideData != null) {
            print("RideBloc: Dados da corrida atualizados: ${rideData['status']}");
            add(RideUpdated(rideData));
          } else {
            print("RideBloc: Não há dados para a corrida ${event.rideId}");
          }
        },
        onError: (error) {
          print("RideBloc: Erro ao monitorar corrida: $error");
          if (!emit.isDone) {
            emit(RideError("Erro ao monitorar corrida: $error"));
          }
        }
      );
  }
  
  void _onStopTrackingRide(StopTrackingRide event, Emitter<RideState> emit) {
    print("RideBloc: Parando monitoramento da corrida...");
    _cleanupRideResources();
    if (!emit.isDone) {
      emit(RideInitial());
    }
  }
  
  void _onRateRide(RateRide event, Emitter<RideState> emit) async {
    try {
      print("RideBloc: Avaliando corrida ${event.rideId}...");
      await _databaseService.rateRide(
        event.rideId, 
        event.rating, 
        event.comment
      );
      
      if (state is RideCompleted && !emit.isDone) {
        emit((state as RideCompleted).copyWith(
          isRated: true,
          rating: event.rating,
        ));
      }
      print("RideBloc: Corrida avaliada com sucesso");
    } catch (e) {
      print("RideBloc: Erro ao avaliar corrida: $e");
      if (!emit.isDone) {
        emit(RideError("Erro ao avaliar corrida: ${e.toString()}"));
      }
    }
  }
  
  // Modificado para usar async/await e verificar emit.isDone
  Future<void> _onRideUpdated(RideUpdated event, Emitter<RideState> emit) async {
    final rideData = event.rideData;
    final status = rideData['status'] as String;
    final rideId = rideData['id'] as String;
    
    print("RideBloc: Processando atualização de corrida $rideId com status $status");
    
    switch (status) {
      case 'searching':
        if (state is! SearchingDriver && !emit.isDone) {
          print("RideBloc: Emitindo estado SearchingDriver");
          emit(SearchingDriver(
            rideId: rideId,
            pickup: LatLng(
              rideData['pickup']['latitude'],
              rideData['pickup']['longitude'],
            ),
            destination: LatLng(
              rideData['destination']['latitude'],
              rideData['destination']['longitude'],
            ),
            pickupAddress: rideData['pickup']['address'],
            destinationAddress: rideData['destination']['address'],
            estimatedPrice: rideData['estimated_price'],
            searchTimeElapsed: _searchTimeElapsed,
          ));
        }
        break;
        
      case 'accepted':
        _searchTimer?.cancel();
        
        print("RideBloc: Buscando dados do motorista");
        final driverId = rideData['driver_id'];
        
        // Iniciar rastreamento da localização do motorista
        add(StartDriverTracking(driverId: driverId));
        
        try {
          // Buscar dados reais do motorista do banco de dados
          final driverData = await _databaseService.getDriverData(driverId);
          
          if (driverData != null && !emit.isDone) {
            print("RideBloc: Dados do motorista obtidos com sucesso: ${driverData['name']}");
            
            // Verificar se há dados de localização do motorista
            LatLng driverLocation;
            if (driverData.containsKey('current_location') && 
                driverData['current_location'] != null &&
                driverData['current_location'].containsKey('latitude') &&
                driverData['current_location'].containsKey('longitude')) {
              
              driverLocation = LatLng(
                driverData['current_location']['latitude'],
                driverData['current_location']['longitude'],
              );
            } else {
              // Fallback: usar a localização de pickup como aproximação inicial
              driverLocation = LatLng(
                rideData['pickup']['latitude'],
                rideData['pickup']['longitude'],
              );
            }
            
            // Emitir estado com os dados reais do motorista
            emit(DriverAccepted(
              rideId: rideId,
              driverId: driverId,
              driverName: driverData['name'] ?? "Motorista",
              driverPhone: driverData['phone'] ?? "",
              driverPhoto: driverData['photo'],
              driverRating: driverData['rating'] ?? 0.0,
              vehicleModel: driverData['vehicle']?['model'] ?? "Veículo",
              licensePlate: driverData['vehicle']?['plate'] ?? "",
              estimatedArrivalTime: rideData['estimated_arrival_time'] ?? 5.0,
              pickup: LatLng(
                rideData['pickup']['latitude'],
                rideData['pickup']['longitude'],
              ),
              destination: LatLng(
                rideData['destination']['latitude'],
                rideData['destination']['longitude'],
              ),
              pickupAddress: rideData['pickup']['address'],
              destinationAddress: rideData['destination']['address'],
              driverLocation: driverLocation,
              lastLocationUpdate: DateTime.now(),
            ));
          } else if (!emit.isDone) {
            print("RideBloc: Dados do motorista não encontrados, usando fallback");
            _emitFallbackDriverAccepted(emit, rideId, driverId, rideData);
          }
        } catch (e) {
          print("RideBloc: Erro ao obter dados do motorista: $e");
          if (!emit.isDone) {
            _emitFallbackDriverAccepted(emit, rideId, driverId, rideData);
          }
        }
        break;
        
      case 'arrived':
        _waitingTimeElapsed = 0;
        _waitingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          _waitingTimeElapsed++;
          
          if (state is DriverArrived && !emit.isDone) {
            emit((state as DriverArrived).copyWith(
              waitingTime: _waitingTimeElapsed
            ));
          } else {
            timer.cancel();
          }
        });
        
        print("RideBloc: Buscando dados atualizados do motorista");
        final driverId = rideData['driver_id'];
        
        try {
          // Buscar dados reais do motorista do banco de dados
          final driverData = await _databaseService.getDriverData(driverId);
          
          if (driverData != null && !emit.isDone) {
            print("RideBloc: Dados do motorista obtidos para chegada: ${driverData['name']}");
            
            // Obter localização atual do motorista (que deve ser no ponto de pickup)
            LatLng driverLocation;
            if (state is DriverAccepted) {
              driverLocation = (state as DriverAccepted).driverLocation;
            } else {
              driverLocation = LatLng(
                rideData['pickup']['latitude'],
                rideData['pickup']['longitude'],
              );
            }
            
            emit(DriverArrived(
              rideId: rideId,
              driverId: driverId,
              driverName: driverData['name'] ?? "Motorista",
              driverPhone: driverData['phone'] ?? "",
              driverPhoto: driverData['photo'],
              pickup: LatLng(
                rideData['pickup']['latitude'],
                rideData['pickup']['longitude'],
              ),
              destination: LatLng(
                rideData['destination']['latitude'],
                rideData['destination']['longitude'],
              ),
              driverLocation: driverLocation,
              lastLocationUpdate: DateTime.now(),
            ));
          } else if (!emit.isDone) {
            print("RideBloc: Dados do motorista não encontrados para chegada");
            emit(DriverArrived(
              rideId: rideId,
              driverId: driverId,
              driverName: "Motorista",
              driverPhone: "",
              pickup: LatLng(
                rideData['pickup']['latitude'],
                rideData['pickup']['longitude'],
              ),
              destination: LatLng(
                rideData['destination']['latitude'],
                rideData['destination']['longitude'],
              ),
              driverLocation: LatLng(
                rideData['pickup']['latitude'],
                rideData['pickup']['longitude'],
              ),
              lastLocationUpdate: DateTime.now(),
            ));
          }
        } catch (e) {
          print("RideBloc: Erro ao obter dados do motorista para chegada: $e");
          if (!emit.isDone) {
            emit(DriverArrived(
              rideId: rideId,
              driverId: driverId,
              driverName: "Motorista",
              driverPhone: "",
              pickup: LatLng(
                rideData['pickup']['latitude'],
                rideData['pickup']['longitude'],
              ),
              destination: LatLng(
                rideData['destination']['latitude'],
                rideData['destination']['longitude'],
              ),
              driverLocation: LatLng(
                rideData['pickup']['latitude'],
                rideData['pickup']['longitude'],
              ),
              lastLocationUpdate: DateTime.now(),
            ));
          }
        }
        break;
        
      case 'in_progress':
        _waitingTimer?.cancel();
        
        // Iniciar timer para a duração da corrida
        if (_rideTimer == null) {
          _rideTimeElapsed = 0;
          _rideTimer = Timer.periodic(Duration(seconds: 1), (timer) {
            _rideTimeElapsed++;
            
            if (state is RideInProgress && !emit.isDone) {
              emit((state as RideInProgress).copyWith(
                rideTimeElapsed: _rideTimeElapsed
              ));
            } else {
              timer.cancel();
            }
          });
        }
        
        print("RideBloc: Buscando dados do motorista para viagem em andamento");
        final driverId = rideData['driver_id'];
        
        try {
          // Buscar dados reais do motorista do banco de dados
          final driverData = await _databaseService.getDriverData(driverId);
          
          // Obter localização atual do motorista
          LatLng driverLocation;
          if (state is DriverArrived) {
            driverLocation = (state as DriverArrived).driverLocation;
          } else if (state is DriverAccepted) {
            driverLocation = (state as DriverAccepted).driverLocation;
          } else {
            driverLocation = LatLng(
              rideData['pickup']['latitude'],
              rideData['pickup']['longitude'],
            );
          }
          
          // Calcular distância restante e tempo estimado
          double distanceRemaining = _calculateDistance(
            driverLocation.latitude, 
            driverLocation.longitude,
            rideData['destination']['latitude'],
            rideData['destination']['longitude'],
          );
          
          // Estimar o tempo restante (assumindo 30 km/h velocidade média)
          double timeRemaining = (distanceRemaining / 30) * 60; // em minutos
          
          // Ponto de partida para calcular o progresso
          LatLng startLocation = LatLng(
            rideData['pickup']['latitude'],
            rideData['pickup']['longitude'],
          );
          
          // Calcular distância total da viagem
          double totalDistance = _calculateDistance(
            startLocation.latitude,
            startLocation.longitude,
            rideData['destination']['latitude'],
            rideData['destination']['longitude'],
          );
          
          // Calcular progresso aproximado da viagem
          double distanceTraveled = totalDistance - distanceRemaining;
          double progress = distanceTraveled / totalDistance;
          progress = progress.clamp(0.0, 1.0); // Garantir que fique entre 0 e 1
          
          if (driverData != null && !emit.isDone) {
            print("RideBloc: Dados do motorista obtidos para viagem: ${driverData['name']}");
            
            emit(RideInProgress(
              rideId: rideId,
              driverId: driverId,
              driverName: driverData['name'] ?? "Motorista",
              destination: LatLng(
                rideData['destination']['latitude'],
                rideData['destination']['longitude'],
              ),
              destinationAddress: rideData['destination']['address'],
              rideProgress: progress,
              distanceRemaining: distanceRemaining,
              timeRemaining: timeRemaining,
              rideTimeElapsed: _rideTimeElapsed,
              driverLocation: driverLocation,
              startLocation: startLocation,
              lastLocationUpdate: DateTime.now(),
            ));
          } else if (!emit.isDone) {
            print("RideBloc: Dados do motorista não encontrados para viagem");
            emit(RideInProgress(
              rideId: rideId,
              driverId: driverId,
              driverName: "Motorista",
              destination: LatLng(
                rideData['destination']['latitude'],
                rideData['destination']['longitude'],
              ),
              destinationAddress: rideData['destination']['address'],
              rideProgress: progress,
              distanceRemaining: distanceRemaining,
              timeRemaining: timeRemaining,
              rideTimeElapsed: _rideTimeElapsed,
              driverLocation: driverLocation,
              startLocation: startLocation,
              lastLocationUpdate: DateTime.now(),
            ));
          }
        } catch (e) {
          print("RideBloc: Erro ao obter dados do motorista para viagem: $e");
          if (!emit.isDone) {
            emit(RideInProgress(
              rideId: rideId,
              driverId: driverId,
              driverName: "Motorista",
              destination: LatLng(
                rideData['destination']['latitude'],
                rideData['destination']['longitude'],
              ),
              destinationAddress: rideData['destination']['address'],
              rideProgress: 0.3,
              distanceRemaining: 2.5,
              timeRemaining: 8.0,
              rideTimeElapsed: _rideTimeElapsed,
              driverLocation: LatLng(
                rideData['pickup']['latitude'],
                rideData['pickup']['longitude'],
              ),
              startLocation: LatLng(
                rideData['pickup']['latitude'],
                rideData['pickup']['longitude'],
              ),
              lastLocationUpdate: DateTime.now(),
            ));
          }
        }
        break;
        
      case 'completed':
        _rideTimer?.cancel();
        // Parar o rastreamento do motorista quando a corrida for concluída
        add(StopDriverTracking());
        
        print("RideBloc: Buscando dados do motorista para corrida finalizada");
        final driverId = rideData['driver_id'];
        double finalPrice = rideData['final_price'] ?? rideData['estimated_price'];
        double distance = rideData['estimated_distance'];
        
        // Atualizar estatísticas do usuário
        try {
          await _statisticsService.updateUserStatisticsAfterRide(
            rideDistance: distance,
            ridePrice: finalPrice,
            rideId: rideId,
          );
          print("RideBloc: Estatísticas do usuário atualizadas com sucesso");
        } catch (e) {
          print("RideBloc: Erro ao atualizar estatísticas do usuário: $e");
          // Não interromper o fluxo da corrida se as estatísticas falharem
        }
        
        try {
          // Buscar dados reais do motorista do banco de dados
          final driverData = await _databaseService.getDriverData(driverId);
          
          if (driverData != null && !emit.isDone) {
            print("RideBloc: Dados do motorista obtidos para finalização: ${driverData['name']}");
            
            emit(RideCompleted(
              rideId: rideId,
              driverId: driverId,
              driverName: driverData['name'] ?? "Motorista",
              driverPhoto: driverData['photo'],
              finalPrice: finalPrice,
              rideTime: _rideTimeElapsed,
              distance: distance,
              isRated: false,
            ));
          } else if (!emit.isDone) {
            print("RideBloc: Dados do motorista não encontrados para finalização");
            emit(RideCompleted(
              rideId: rideId,
              driverId: driverId,
              driverName: "Motorista",
              finalPrice: finalPrice,
              rideTime: _rideTimeElapsed,
              distance: distance,
              isRated: false,
            ));
          }
        } catch (e) {
          print("RideBloc: Erro ao obter dados do motorista para finalização: $e");
          if (!emit.isDone) {
            emit(RideCompleted(
              rideId: rideId,
              driverId: driverId,
              driverName: "Motorista",
              finalPrice: finalPrice,
              rideTime: _rideTimeElapsed,
              distance: distance,
              isRated: false,
            ));
          }
        }
        break;
        
      case 'cancelled':
        _cleanupRideResources();
        
        print("RideBloc: Emitindo estado RideCancelled");
        if (!emit.isDone) {
          emit(RideCancelled(
            rideId: rideId,
            reason: rideData['cancellation_reason'] ?? "Não especificado",
            cancelledBy: rideData['cancelled_by'] ?? "system",
          ));
        }
        break;
    }
  }
  
  // Método auxiliar para emitir um estado DriverAccepted com valores de fallback
  void _emitFallbackDriverAccepted(Emitter<RideState> emit, String rideId, String driverId, Map<String, dynamic> rideData) {
    if (emit.isDone) return;
    
    // Criar localização padrão do motorista (próximo ao ponto de embarque)
    LatLng driverLocation = LatLng(
      rideData['pickup']['latitude'],
      rideData['pickup']['longitude'],
    );
    
    emit(DriverAccepted(
      rideId: rideId,
      driverId: driverId,
      driverName: "Motorista",
      driverPhone: "",
      driverRating: 0.0,
      vehicleModel: "Veículo",
      licensePlate: "",
      estimatedArrivalTime: rideData['estimated_arrival_time'] ?? 5.0,
      pickup: LatLng(
        rideData['pickup']['latitude'],
        rideData['pickup']['longitude'],
      ),
      destination: LatLng(
        rideData['destination']['latitude'],
        rideData['destination']['longitude'],
      ),
      pickupAddress: rideData['pickup']['address'],
      destinationAddress: rideData['destination']['address'],
      driverLocation: driverLocation,
      lastLocationUpdate: DateTime.now(),
    ));
  }
  
  void _cleanupRideResources() {
  print("RideBloc: Limpando recursos da corrida $_currentRideId e motorista $_currentDriverId...");
  _searchTimer?.cancel();
  _rideTimer?.cancel();
  _waitingTimer?.cancel();
  _rideSubscription?.cancel();
  _driverLocationSubscription?.cancel();
  
  _searchTimer = null;
  _rideTimer = null;
  _waitingTimer = null;
  _rideSubscription = null;
  _driverLocationSubscription = null;
  
  _currentRideId = null;
  _currentDriverId = null;
}
  
  // Método auxiliar para calcular distância entre dois pontos
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Raio da Terra em km
    const double earthRadius = 6371;
    
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
  
  // Converter graus para radianos
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
  
  @override
  Future<void> close() {
    _cleanupRideResources();
    return super.close();
  }
}