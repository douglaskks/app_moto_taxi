// Arquivo: lib/core/utils/ride_test_helper.dart

import 'dart:async';
import 'package:app_moto_taxe/core/services/realtime_database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class RideTestHelper {
  static final RealtimeDatabaseService _databaseService = RealtimeDatabaseService();
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  /// Simula um motorista aceitando uma corrida para testes
  /// Útil quando não há motoristas reais disponíveis
  static Future<void> simulateDriverAcceptingRide(String rideId) async {
    try {
      // Criar ID de motorista de teste
      const String testDriverId = "test-driver-id-12345";
      
      // Atualizar corrida no Firebase
      await _database.ref().child('rides').child(rideId).update({
        'status': 'accepted',
        'driver_id': testDriverId,
        'estimated_arrival_time': 5.0,
        'accepted_at': ServerValue.timestamp,
      });
      
      print("RideTestHelper: Simulação de motorista aceitando corrida $rideId");
      
      // Após 5 segundos, simular motorista chegando
      await Future.delayed(const Duration(seconds: 5));
      
      await _database.ref().child('rides').child(rideId).update({
        'status': 'arrived',
        'arrived_at': ServerValue.timestamp,
      });
      
      print("RideTestHelper: Simulação de motorista chegando ao local de embarque");
      
      // Após mais 5 segundos, simular início da corrida
      await Future.delayed(const Duration(seconds: 5));
      
      await _database.ref().child('rides').child(rideId).update({
        'status': 'in_progress',
        'started_at': ServerValue.timestamp,
      });
      
      print("RideTestHelper: Simulação de corrida iniciada");
      
      // Após mais 10 segundos, simular finalização da corrida
      await Future.delayed(const Duration(seconds: 10));
      
      await _database.ref().child('rides').child(rideId).update({
        'status': 'completed',
        'completed_at': ServerValue.timestamp,
      });
      
      print("RideTestHelper: Simulação de corrida finalizada");
    } catch (e) {
      print("RideTestHelper: Erro na simulação - $e");
    }
  }

  /// Exibe um botão para simular a aceitação de uma corrida
  /// Útil para testes durante o desenvolvimento
  static Widget buildTestModeButton(BuildContext context, String rideId) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "MODO DE TESTE", 
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: () => simulateDriverAcceptingRide(rideId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text("Simular Motorista Aceitando"),
          ),
        ],
      ),
    );
  }
  
  /// Método para depurar o conteúdo de uma corrida (logs detalhados)
  static Future<void> debugRideData(String rideId) async {
    try {
      final snapshot = await _database.ref().child('rides').child(rideId).get();
      
      if (snapshot.exists) {
        print("==== DADOS DA CORRIDA $rideId ====");
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          print("$key: $value");
        });
        print("================================");
      } else {
        print("Corrida $rideId não encontrada no banco de dados");
      }
    } catch (e) {
      print("Erro ao depurar corrida $rideId: $e");
    }
  }
}