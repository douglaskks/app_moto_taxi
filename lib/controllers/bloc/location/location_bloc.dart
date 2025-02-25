// Arquivo: lib/controllers/bloc/location/location_bloc.dart
import 'package:app_moto_taxe/core/services/location_service.dart';
import 'package:bloc/bloc.dart';
// Estes imports serão necessários quando você implementar o serviço real
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationService _locationService;
  
  LocationBloc(this._locationService) : super(LocationInitial()) {
    on<LoadCurrentLocation>(_onLoadCurrentLocation);
    on<LocationPermissionRequested>(_onLocationPermissionRequested);
    on<LocationUpdated>(_onLocationUpdated);
    on<SetDestination>(_onSetDestination);
    on<ClearDestination>(_onClearDestination);
  }

  void _onLoadCurrentLocation(LoadCurrentLocation event, Emitter<LocationState> emit) async {
    try {
      emit(LocationLoading());
      
      final hasPermission = await _locationService.checkLocationPermission();
      
      if (!hasPermission) {
        emit(LocationPermissionDenied('Permissão de localização negada. Por favor, habilite nas configurações.'));
        return;
      }
      
      final position = await _locationService.getCurrentLocation();
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      emit(LocationLoaded(
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
        currentAddress: address,
      ));
    } catch (error) {
      emit(LocationError('Erro ao carregar localização: ${error.toString()}'));
    }
  }

  void _onLocationPermissionRequested(LocationPermissionRequested event, Emitter<LocationState> emit) async {
    try {
      emit(LocationLoading());
      
      final permissionGranted = await _locationService.requestLocationPermission();
      
      if (permissionGranted) {
        add(LoadCurrentLocation());
      } else {
        emit(LocationPermissionDenied('Permissão de localização negada. Por favor, habilite nas configurações.'));
      }
    } catch (error) {
      emit(LocationError('Erro ao solicitar permissão: ${error.toString()}'));
    }
  }

  void _onLocationUpdated(LocationUpdated event, Emitter<LocationState> emit) async {
    if (state is LocationLoaded) {
      final currentState = state as LocationLoaded;
      
      try {
        final address = await _locationService.getAddressFromCoordinates(
          event.latitude, 
          event.longitude
        );
        
        // Recalcular distância, duração e preço se tiver destino
        double? distance;
        double? duration;
        double? estimatedPrice;
        
        if (currentState.destinationLatitude != null && currentState.destinationLongitude != null) {
          final routeInfo = await _locationService.calculateRoute(
            event.latitude,
            event.longitude,
            currentState.destinationLatitude!,
            currentState.destinationLongitude!,
          );
          
          distance = routeInfo.distance;
          duration = routeInfo.duration;
          estimatedPrice = routeInfo.estimatedPrice;
        }
        
        emit(currentState.copyWith(
          currentLatitude: event.latitude,
          currentLongitude: event.longitude,
          currentAddress: address,
          distance: distance,
          duration: duration,
          estimatedPrice: estimatedPrice,
        ));
      } catch (error) {
        emit(LocationError('Erro ao atualizar localização: ${error.toString()}'));
      }
    }
  }

  void _onSetDestination(SetDestination event, Emitter<LocationState> emit) async {
    if (state is LocationLoaded) {
      final currentState = state as LocationLoaded;
      
      try {
        emit(LocationLoading());
        
        double destinationLat;
        double destinationLng;
        
        // Se as coordenadas foram fornecidas, use-as
        if (event.latitude != null && event.longitude != null) {
          destinationLat = event.latitude!;
          destinationLng = event.longitude!;
        } else {
          // Caso contrário, tente geocodificar o endereço
          final coordinates = await _locationService.getCoordinatesFromAddress(event.destinationAddress);
          destinationLat = coordinates.latitude;
          destinationLng = coordinates.longitude;
        }
        
        // Calcular rota, distância, tempo e preço
        final routeInfo = await _locationService.calculateRoute(
          currentState.currentLatitude,
          currentState.currentLongitude,
          destinationLat,
          destinationLng,
        );
        
        emit(currentState.copyWith(
          destinationAddress: event.destinationAddress,
          destinationLatitude: destinationLat,
          destinationLongitude: destinationLng,
          distance: routeInfo.distance,
          duration: routeInfo.duration,
          estimatedPrice: routeInfo.estimatedPrice,
        ));
      } catch (error) {
        emit(LocationError('Erro ao definir destino: ${error.toString()}'));
        // Voltar ao estado anterior
        emit(currentState);
      }
    }
  }

  void _onClearDestination(ClearDestination event, Emitter<LocationState> emit) {
    if (state is LocationLoaded) {
      final currentState = state as LocationLoaded;
      
      emit(currentState.copyWith(
        destinationAddress: null,
        destinationLatitude: null,
        destinationLongitude: null,
        distance: null,
        duration: null,
        estimatedPrice: null,
      ));
    }
  }
}