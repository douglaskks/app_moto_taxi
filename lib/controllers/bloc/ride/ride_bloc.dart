// Arquivo: lib/controllers/bloc/ride/ride_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/realtime_database_service.dart';
import 'ride_event.dart';
import 'ride_state.dart';

class RideBloc extends Bloc<RideEvent, RideState> {
  final RealtimeDatabaseService _databaseService;
  
  StreamSubscription? _rideSubscription;
  Timer? _searchTimer;
  Timer? _rideTimer;
  Timer? _waitingTimer;
  
  String? _currentRideId;
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
    on<RideUpdated>(_onRideUpdated);
  }
  
  void _onRequestRide(RequestRide event, Emitter<RideState> emit) async {
    emit(RequestingRide());
    
    try {
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
      
      _currentRideId = rideId;
      
      // Emitir estado de busca de motorista
      emit(SearchingDriver(
        rideId: rideId,
        pickup: event.pickup,
        destination: event.destination,
        pickupAddress: event.pickupAddress,
        destinationAddress: event.destinationAddress,
        estimatedPrice: event.estimatedPrice,
      ));
      
      // Iniciar timer para atualizar o tempo de busca
      _searchTimeElapsed = 0;
      _searchTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        _searchTimeElapsed++;
        
        if (state is SearchingDriver) {
          emit((state as SearchingDriver).copyWith(
            searchTimeElapsed: _searchTimeElapsed
          ));
        } else {
          // Se não estiver mais procurando, cancelar o timer
          timer.cancel();
        }
      });
      
      // Iniciar monitoramento da corrida
      add(TrackRide(rideId: rideId));
      
    } catch (e) {
      emit(RideError("Erro ao solicitar corrida: ${e.toString()}"));
    }
  }
  
  void _onCancelRideRequest(CancelRideRequest event, Emitter<RideState> emit) async {
    try {
      await _databaseService.cancelRideRequest(event.rideId, event.reason);
      
      _cleanupRideResources();
      
      emit(RideCancelled(
        rideId: event.rideId,
        reason: event.reason,
        cancelledBy: 'passenger',
      ));
    } catch (e) {
      emit(RideError("Erro ao cancelar corrida: ${e.toString()}"));
    }
  }
  
  void _onAcceptRide(AcceptRide event, Emitter<RideState> emit) async {
    try {
      await _databaseService.acceptRide(
        event.rideId, 
        event.estimatedArrivalTime
      );
      
      // A atualização do estado será feita via TrackRide quando
      // o Firebase enviar a notificação de mudança de status
    } catch (e) {
      emit(RideError("Erro ao aceitar corrida: ${e.toString()}"));
    }
  }
  
  void _onUpdateRideStatus(UpdateRideStatus event, Emitter<RideState> emit) async {
    try {
      await _databaseService.updateRideStatus(event.rideId, event.status);
      
      // A atualização do estado será feita via TrackRide quando
      // o Firebase enviar a notificação de mudança de status
    } catch (e) {
      emit(RideError("Erro ao atualizar status da corrida: ${e.toString()}"));
    }
  }
  
  void _onTrackRide(TrackRide event, Emitter<RideState> emit) {
    // Cancelar assinatura existente
    _rideSubscription?.cancel();
    
    // Iniciar monitoramento da corrida
    _rideSubscription = _databaseService
      .getCurrentRideStream(event.rideId)
      .listen(
        (rideData) {
          if (rideData != null) {
            add(RideUpdated(rideData));
          }
        },
        onError: (error) {
          emit(RideError("Erro ao monitorar corrida: $error"));
        }
      );
  }
  
  void _onStopTrackingRide(StopTrackingRide event, Emitter<RideState> emit) {
    _cleanupRideResources();
    emit(RideInitial());
  }
  
  void _onRateRide(RateRide event, Emitter<RideState> emit) async {
    try {
      await _databaseService.rateRide(
        event.rideId, 
        event.rating, 
        event.comment
      );
      
      if (state is RideCompleted) {
        emit((state as RideCompleted).copyWith(
          isRated: true,
          rating: event.rating,
        ));
      }
    } catch (e) {
      emit(RideError("Erro ao avaliar corrida: ${e.toString()}"));
    }
  }
  
  void _onRideUpdated(RideUpdated event, Emitter<RideState> emit) {
    final rideData = event.rideData;
    final status = rideData['status'] as String;
    final rideId = rideData['id'] as String;
    
    switch (status) {
      case 'searching':
        if (state is! SearchingDriver) {
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
        
        // Aqui você buscaria os dados do motorista no Firestore
        // Para simplificar, estamos usando dados simulados
        emit(DriverAccepted(
          rideId: rideId,
          driverId: rideData['driver_id'],
          driverName: "João Silva", // Simulado
          driverPhone: "(81) 99999-9999", // Simulado
          driverRating: 4.8, // Simulado
          vehicleModel: "Honda CG 160", // Simulado
          licensePlate: "ABC-1234", // Simulado
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
        ));
        break;
        
      case 'arrived':
        _waitingTimeElapsed = 0;
        _waitingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          _waitingTimeElapsed++;
          
          if (state is DriverArrived) {
            emit((state as DriverArrived).copyWith(
              waitingTime: _waitingTimeElapsed
            ));
          } else {
            timer.cancel();
          }
        });
        
        emit(DriverArrived(
          rideId: rideId,
          driverId: rideData['driver_id'],
          driverName: "João Silva", // Simulado
          driverPhone: "(81) 99999-9999", // Simulado
          pickup: LatLng(
            rideData['pickup']['latitude'],
            rideData['pickup']['longitude'],
          ),
          destination: LatLng(
            rideData['destination']['latitude'],
            rideData['destination']['longitude'],
          ),
        ));
        break;
        
      case 'in_progress':
        _waitingTimer?.cancel();
        
        // Iniciar timer para a duração da corrida
        if (_rideTimer == null) {
          _rideTimeElapsed = 0;
          _rideTimer = Timer.periodic(Duration(seconds: 1), (timer) {
            _rideTimeElapsed++;
            
            if (state is RideInProgress) {
              emit((state as RideInProgress).copyWith(
                rideTimeElapsed: _rideTimeElapsed
              ));
            } else {
              timer.cancel();
            }
          });
        }
        
        // Neste ponto precisaríamos da localização atual do motorista
        // e cálculos de distância/tempo para chegada
        // Para simplificar, usamos valores simulados
        emit(RideInProgress(
          rideId: rideId,
          driverId: rideData['driver_id'],
          driverName: "João Silva", // Simulado
          destination: LatLng(
            rideData['destination']['latitude'],
            rideData['destination']['longitude'],
          ),
          destinationAddress: rideData['destination']['address'],
          rideProgress: 0.3, // Simulado
          distanceRemaining: 2.5, // Simulado
          timeRemaining: 8.0, // Simulado
          rideTimeElapsed: _rideTimeElapsed,
        ));
        break;
        
      case 'completed':
        _rideTimer?.cancel();
        
        // Calcular preço final (normalmente seria fornecido pelo backend)
        // Para simplificar, usamos o preço estimado
        double finalPrice = rideData['estimated_price'];
        
        emit(RideCompleted(
          rideId: rideId,
          driverId: rideData['driver_id'],
          driverName: "João Silva", // Simulado
          finalPrice: finalPrice,
          rideTime: _rideTimeElapsed,
          distance: rideData['estimated_distance'],
          isRated: false,
        ));
        break;
        
      case 'cancelled':
        _cleanupRideResources();
        
        emit(RideCancelled(
          rideId: rideId,
          reason: rideData['cancellation_reason'] ?? "Não especificado",
          cancelledBy: rideData['cancelled_by'] ?? "system",
        ));
        break;
    }
  }
  
  void _cleanupRideResources() {
    _searchTimer?.cancel();
    _rideTimer?.cancel();
    _waitingTimer?.cancel();
    _rideSubscription?.cancel();
    
    _searchTimer = null;
    _rideTimer = null;
    _waitingTimer = null;
    _rideSubscription = null;
    
    _currentRideId = null;
  }
  
  @override
  Future<void> close() {
    _cleanupRideResources();
    return super.close();
  }
}