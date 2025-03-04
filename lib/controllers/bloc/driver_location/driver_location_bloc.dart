// Arquivo: lib/controllers/bloc/driver_location/driver_location_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../../core/services/realtime_database_service.dart';
import 'driver_location_event.dart';
import 'driver_location_state.dart';

class DriverLocationBloc extends Bloc<DriverLocationEvent, DriverLocationState> {
  final RealtimeDatabaseService _databaseService;
  
  StreamSubscription? _nearbyDriversSubscription;
  StreamSubscription? _driverLocationSubscription;
  
  Map<String, StreamSubscription> _driverSubscriptions = {};
  Map<String, Marker> _driverMarkers = {};
  
  DriverLocationBloc(this._databaseService) : super(DriverLocationInitial()) {
    on<FetchNearbyDrivers>(_onFetchNearbyDrivers);
    on<StopFetchingDrivers>(_onStopFetchingDrivers);
    on<UpdateDriverLocation>(_onUpdateDriverLocation);
    on<BeginTrackingDriver>(_onBeginTrackingDriver);
    on<StopTrackingDriver>(_onStopTrackingDriver);
  }
  
  void _onFetchNearbyDrivers(FetchNearbyDrivers event, Emitter<DriverLocationState> emit) {
    emit(DriverLocationLoading());
    
    // Cancelar assinatura existente
    _nearbyDriversSubscription?.cancel();
    
    // Iniciar nova assinatura para motoristas próximos
    _nearbyDriversSubscription = _databaseService.getNearbyDrivers(
      event.latitude,
      event.longitude,
      event.radius,
    ).listen(
      (List<Map<String, dynamic>> drivers) {
        _updateDriverMarkers(drivers);
        
        emit(DriverLocationsLoaded(
          nearbyDrivers: drivers,
          driverMarkers: _driverMarkers,
        ));
      },
      onError: (error) {
        emit(DriverLocationError("Erro ao obter motoristas próximos: $error"));
      }
    );
  }
  
  void _onStopFetchingDrivers(StopFetchingDrivers event, Emitter<DriverLocationState> emit) {
    _nearbyDriversSubscription?.cancel();
    _driverSubscriptions.forEach((key, subscription) {
      subscription.cancel();
    });
    _driverSubscriptions.clear();
    _driverMarkers.clear();
    
    emit(DriverLocationInitial());
  }
  
  void _onUpdateDriverLocation(UpdateDriverLocation event, Emitter<DriverLocationState> emit) {
    // Atualizar marcador do motorista
    _updateDriverMarker(event.driverId, event.location);
    
    // Se estiver carregando uma lista de motoristas, atualizar o estado
    if (state is DriverLocationsLoaded) {
      final currentState = state as DriverLocationsLoaded;
      emit(currentState.copyWith(driverMarkers: _driverMarkers));
    }
    
    // Se estiver rastreando um motorista específico, atualizar o estado
    else if (state is TrackingDriverLocation) {
      final currentState = state as TrackingDriverLocation;
      if (currentState.driverId == event.driverId) {
        // Calcular distância do usuário ao motorista (poderia ser implementado)
        double? distanceToDriver;
        double? estimatedArrivalTime;
        
        emit(currentState.copyWith(
          driverLocation: event.location,
          distanceToDriver: distanceToDriver,
          estimatedArrivalTime: estimatedArrivalTime,
        ));
      }
    }
  }
  
  void _onBeginTrackingDriver(BeginTrackingDriver event, Emitter<DriverLocationState> emit) {
    // Cancelar outras assinaturas
    _nearbyDriversSubscription?.cancel();
    
    // Começar a rastrear o motorista
    emit(TrackingDriverLocation(driverId: event.driverId));
    
    // Iniciar assinatura para a localização deste motorista
    _driverLocationSubscription = _databaseService
      .getDriverLocationStream(event.driverId)
      .listen(
        (locationData) {
          if (locationData != null && 
              locationData.containsKey('latitude') && 
              locationData.containsKey('longitude')) {
            
            double lat = locationData['latitude'];
            double lng = locationData['longitude'];
            
            add(UpdateDriverLocation(
              driverId: event.driverId,
              location: LatLng(lat, lng),
            ));
          }
        },
        onError: (error) {
          emit(DriverLocationError("Erro ao rastrear motorista: $error"));
        }
      );
  }
  
  void _onStopTrackingDriver(StopTrackingDriver event, Emitter<DriverLocationState> emit) {
    _driverLocationSubscription?.cancel();
    emit(DriverLocationInitial());
  }
  
  void _updateDriverMarkers(List<Map<String, dynamic>> drivers) {
    // Limpar marcadores antigos não presentes na nova lista
    Set<String> newDriverIds = drivers.map((d) => d['id'] as String).toSet();
    List<String> driversToRemove = [];
    
    _driverMarkers.keys.forEach((driverId) {
      if (!newDriverIds.contains(driverId)) {
        driversToRemove.add(driverId);
      }
    });
    
    driversToRemove.forEach((driverId) {
      _driverMarkers.remove(driverId);
      _driverSubscriptions[driverId]?.cancel();
      _driverSubscriptions.remove(driverId);
    });
    
    // Adicionar ou atualizar marcadores para novos motoristas ou existentes
    for (var driver in drivers) {
      String driverId = driver['id'];
      double lat = driver['latitude'];
      double lng = driver['longitude'];
      
      _updateDriverMarker(driverId, LatLng(lat, lng));
      
      // Se ainda não estiver assinando atualizações para este motorista, iniciar
      if (!_driverSubscriptions.containsKey(driverId)) {
      _driverSubscriptions[driverId] = _databaseService
        .getDriverLocationStream(driverId)
        .listen(
          (locationData) {
            if (locationData != null && 
                locationData.containsKey('latitude') && 
                locationData.containsKey('longitude')) {
              
              double lat = locationData['latitude'];
              double lng = locationData['longitude'];
              
              add(UpdateDriverLocation(
                driverId: driverId,
                location: LatLng(lat, lng),
              ));
            }
          }
        );
    }
    }
  }
  
  void _updateDriverMarker(String driverId, LatLng location) {
    _driverMarkers[driverId] = Marker(
      markerId: MarkerId('driver_$driverId'),
      position: location,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: InfoWindow(
        title: 'Motorista disponível',
        snippet: 'Distância: ${_calculateDistance(location)} km',
      ),
    );
  }
  
  // Método auxiliar para calcular distância
  // Isso seria mais sofisticado em uma implementação real
  String _calculateDistance(LatLng driverLocation) {
    // Aqui você calcularia a distância entre a localização do usuário
    // e a localização do motorista
    return "1.2"; // Exemplo estático
  }
  
  @override
  Future<void> close() {
    _nearbyDriversSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    _driverSubscriptions.forEach((key, subscription) {
      subscription.cancel();
    });
    return super.close();
  }
}