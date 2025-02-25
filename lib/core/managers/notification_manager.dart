// Arquivo: lib/core/managers/notification_manager.dart

import 'package:app_moto_taxe/controllers/bloc/ride/ride_state.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../../views/driver/ride_request_screen.dart';
import '../../controllers/bloc/ride/ride_bloc.dart';
import '../../controllers/bloc/ride/ride_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  
  factory NotificationManager() {
    return _instance;
  }
  
  NotificationManager._internal();
  
  final NotificationService _notificationService = NotificationService();
  
  // Inicializar os handlers de notificação
  void initialize(BuildContext context) {
    // Registrar handlers para diferentes tipos de notificação
    _registerRideAcceptedHandler(context);
    _registerDriverArrivedHandler(context);
    _registerRideStartedHandler(context);
    _registerRideCompletedHandler(context);
    _registerNewRideRequestHandler(context);
    _registerRideCancelledHandler(context);
    
    // Registrar o token FCM quando o usuário fizer login
    _registerTokenAfterLogin(context);
  }
  
  // Registrar token FCM após login
  void _registerTokenAfterLogin(BuildContext context) {
    // Esta função seria chamada após um login bem-sucedido
    // Para simplificar, assumimos que o usuário já está logado
    // No mundo real, você usaria um sistema de eventos ou um listener de autenticação
  }
  
  // Handler para notificação de corrida aceita (para passageiros)
  void _registerRideAcceptedHandler(BuildContext context) {
    _notificationService.registerNotificationHandler(
      'ride_accepted',
      (Map<String, dynamic> data) {
        final String rideId = data['ride_id'] ?? '';
        final String driverId = data['driver_id'] ?? '';
        final String driverName = data['driver_name'] ?? '';
        final String driverRating = data['driver_rating'] ?? '0.0';
        final String driverPhone = data['driver_phone'] ?? '';
        final String vehicleModel = data['vehicle_model'] ?? '';
        final String licensePlate = data['license_plate'] ?? '';
        final String estimatedArrivalTime = data['estimated_arrival_time'] ?? '0';
        
        // Mostrar notificação de motorista encontrado
        _showRideAcceptedDialog(
          context,
          rideId,
          driverId,
          driverName,
          double.tryParse(driverRating) ?? 0.0,
          driverPhone,
          vehicleModel,
          licensePlate,
          double.tryParse(estimatedArrivalTime) ?? 0.0,
        );
        
        // Atualizar o estado do BLoC, se estiver disponível
        try {
          if (context.read<RideBloc>().state is SearchingDriver) {
            context.read<RideBloc>().add(TrackRide(rideId: rideId));
          }
        } catch (e) {
          print('Erro ao atualizar estado do RideBloc: $e');
        }
      },
    );
  }
  
  // Handler para notificação de motorista chegou (para passageiros)
  void _registerDriverArrivedHandler(BuildContext context) {
    _notificationService.registerNotificationHandler(
      'driver_arrived',
      (Map<String, dynamic> data) {
        final String rideId = data['ride_id'] ?? '';
        
        // Mostrar notificação de motorista chegou
        _showDriverArrivedDialog(context, rideId);
        
        // Atualizar o estado do BLoC, se estiver disponível
        try {
          context.read<RideBloc>().add(UpdateRideStatus(
            rideId: rideId,
            status: 'arrived',
          ));
        } catch (e) {
          print('Erro ao atualizar estado do RideBloc: $e');
        }
      },
    );
  }
  
  // Handler para notificação de corrida iniciada (para passageiros)
  void _registerRideStartedHandler(BuildContext context) {
    _notificationService.registerNotificationHandler(
      'ride_started',
      (Map<String, dynamic> data) {
        final String rideId = data['ride_id'] ?? '';
        
        // Atualizar o estado do BLoC, se estiver disponível
        try {
          context.read<RideBloc>().add(UpdateRideStatus(
            rideId: rideId,
            status: 'in_progress',
          ));
        } catch (e) {
          print('Erro ao atualizar estado do RideBloc: $e');
        }
      },
    );
  }
  
  // Handler para notificação de corrida concluída (para passageiros)
  void _registerRideCompletedHandler(BuildContext context) {
    _notificationService.registerNotificationHandler(
      'ride_completed',
      (Map<String, dynamic> data) {
        final String rideId = data['ride_id'] ?? '';
        final String finalPrice = data['final_price'] ?? '0.0';
        
        // Mostrar diálogo de corrida concluída
        _showRideCompletedDialog(
          context,
          rideId,
          double.tryParse(finalPrice) ?? 0.0,
        );
        
        // Atualizar o estado do BLoC, se estiver disponível
        try {
          context.read<RideBloc>().add(UpdateRideStatus(
            rideId: rideId,
            status: 'completed',
          ));
        } catch (e) {
          print('Erro ao atualizar estado do RideBloc: $e');
        }
      },
    );
  }
  
  // Handler para notificação de nova solicitação de corrida (para motoristas)
  void _registerNewRideRequestHandler(BuildContext context) {
    _notificationService.registerNotificationHandler(
      'new_ride_request',
      (Map<String, dynamic> data) {
        final String rideId = data['ride_id'] ?? '';
        final String pickupAddress = data['pickup_address'] ?? '';
        final String destinationAddress = data['destination_address'] ?? '';
        final String estimatedPrice = data['estimated_price'] ?? '0.0';
        final String distanceToPickup = data['distance_to_pickup'] ?? '0.0';
        
        // Mostrar tela de solicitação de corrida
        _showRideRequestScreen(
          context,
          rideId,
          pickupAddress,
          destinationAddress,
          double.tryParse(estimatedPrice) ?? 0.0,
          double.tryParse(distanceToPickup) ?? 0.0,
        );
      },
    );
  }
  
  // Handler para notificação de corrida cancelada
  void _registerRideCancelledHandler(BuildContext context) {
    _notificationService.registerNotificationHandler(
      'ride_cancelled',
      (Map<String, dynamic> data) {
        final String rideId = data['ride_id'] ?? '';
        final String cancelledBy = data['cancelled_by'] ?? 'system';
        
        // Mostrar mensagem de corrida cancelada
        _showRideCancelledDialog(
          context,
          rideId,
          cancelledBy,
        );
        
        // Atualizar o estado do BLoC, se estiver disponível
        try {
          context.read<RideBloc>().add(StopTrackingRide());
        } catch (e) {
          print('Erro ao atualizar estado do RideBloc: $e');
        }
      },
    );
  }
  
  // Mostrar diálogo de motorista encontrado
  void _showRideAcceptedDialog(
    BuildContext context,
    String rideId,
    String driverId,
    String driverName,
    double driverRating,
    String driverPhone,
    String vehicleModel,
    String licensePlate,
    double estimatedArrivalTime,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Motorista encontrado!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$driverName está a caminho do local de embarque.'),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text('$driverRating'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.motorcycle, size: 16),
                  SizedBox(width: 4),
                  Text('$vehicleModel - $licensePlate'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16),
                  SizedBox(width: 4),
                  Text('Tempo estimado: ${estimatedArrivalTime.toInt()} min'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  // Mostrar diálogo de motorista chegou
  void _showDriverArrivedDialog(BuildContext context, String rideId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 8),
              Text('Motorista chegou!'),
            ],
          ),
          content: Text('Seu motorista chegou ao local de embarque.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  // Mostrar diálogo de corrida concluída
  void _showRideCompletedDialog(
    BuildContext context,
    String rideId,
    double finalPrice,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Corrida concluída'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Obrigado por usar nosso aplicativo!'),
              SizedBox(height: 16),
              Text(
                'Valor final: R\$ ${finalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 16),
              Text('Como foi sua experiência?'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Avaliar depois'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: Text('Avaliar agora'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Navegar para tela de avaliação
                // Implementar no futuro
              },
            ),
          ],
        );
      },
    );
  }
  
  // Mostrar tela de solicitação de corrida (para motoristas)
  void _showRideRequestScreen(
    BuildContext context,
    String rideId,
    String pickupAddress,
    String destinationAddress,
    double estimatedPrice,
    double distanceToPickup,
  ) {
    // Converter km para minutos estimados (velocidade média de 30 km/h)
    final double estimatedDuration = (distanceToPickup / 30) * 60;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideRequestScreen(
          passengerId: 'user123', // Este valor viria do backend
          passengerName: 'Passageiro', // Este valor viria do backend
          passengerRating: 4.5, // Este valor viria do backend
          pickupAddress: pickupAddress,
          destinationAddress: destinationAddress,
          estimatedDistance: distanceToPickup,
          estimatedDuration: estimatedDuration,
          estimatedFare: estimatedPrice,
          onAccept: () {
            // Lógica para aceitar corrida
            try {
              // Estimativa de tempo para chegar (baseado na distância)
              final double arrivalTime = (distanceToPickup / 30) * 60; // em minutos
              
              context.read<RideBloc>().add(AcceptRide(
                rideId: rideId,
                estimatedArrivalTime: arrivalTime,
              ));
              
              Navigator.pop(context);
              // Navegar para tela de corrida em andamento
              // Implementar no futuro
            } catch (e) {
              print('Erro ao aceitar corrida: $e');
            }
          },
          onReject: () {
            // Lógica para rejeitar corrida
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
  
  // Mostrar diálogo de corrida cancelada
  void _showRideCancelledDialog(
    BuildContext context,
    String rideId,
    String cancelledBy,
  ) {
    String title = 'Corrida cancelada';
    String message = 'A corrida foi cancelada.';
    
    if (cancelledBy == 'passenger') {
      message = 'O passageiro cancelou a corrida.';
    } else if (cancelledBy == 'driver') {
      message = 'O motorista cancelou a corrida. Buscando outro motorista...';
    } else {
      message = 'A corrida foi cancelada pelo sistema.';
    }
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}