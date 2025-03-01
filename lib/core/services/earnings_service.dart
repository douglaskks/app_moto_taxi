// Arquivo: lib/core/services/earnings_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EarningsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Registrar uma corrida finalizada no histórico de ganhos do motorista
  Future<void> recordCompletedRide({
    required String rideId,
    required double amount,
    required String pickupAddress,
    required String destinationAddress,
    required double distance,
    required int durationInSeconds,
    required String passengerId,
    required String passengerName,
  }) async {
    try {
      final String driverId = _auth.currentUser?.uid ?? '';
      
      if (driverId.isEmpty) {
        throw Exception('Usuário não autenticado');
      }

      // Obter timestamp atual
      final timestamp = FieldValue.serverTimestamp();
      final DateTime now = DateTime.now();
      
      // Gerar chaves para agrupamento
      final String dayKey = DateFormat('yyyy-MM-dd').format(now);
      final String weekKey = _getWeekKey(now);
      final String monthKey = DateFormat('yyyy-MM').format(now);
      
      // Taxa da plataforma (normalmente seria definida no backend)
      final double platformFee = amount * 0.15; // 15% de taxa
      final double driverAmount = amount - platformFee;
      
      // 1. Registrar a corrida na coleção de ganhos
      await _firestore.collection('driver_earnings').add({
        'driver_id': driverId,
        'ride_id': rideId,
        'amount': amount,
        'platform_fee': platformFee,
        'driver_amount': driverAmount,
        'pickup_address': pickupAddress,
        'destination_address': destinationAddress,
        'distance': distance,
        'duration_seconds': durationInSeconds,
        'passenger_id': passengerId,
        'passenger_name': passengerName,
        'day_key': dayKey,
        'week_key': weekKey,
        'month_key': monthKey,
        'timestamp': timestamp,
        'created_at': timestamp,
      });
      
      // 2. Atualizar estatísticas diárias
      await _updateDailyStats(driverId, dayKey, driverAmount);
      
      // 3. Atualizar estatísticas semanais
      await _updateWeeklyStats(driverId, weekKey, driverAmount);
      
      // 4. Atualizar estatísticas mensais
      await _updateMonthlyStats(driverId, monthKey, driverAmount);
      
      print('EarningsService: Registrado ganho de corrida $rideId: R\$ $amount');
    } catch (e) {
      print('EarningsService: Erro ao registrar ganho: $e');
      rethrow;
    }
  }
  
  // Atualizar estatísticas diárias
  Future<void> _updateDailyStats(String driverId, String dayKey, double amount) async {
    try {
      final docRef = _firestore
          .collection('driver_stats_daily')
          .doc('${driverId}_$dayKey');
      
      // Verificar se o documento já existe
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        // Atualizar estatísticas existentes
        await docRef.update({
          'total_amount': FieldValue.increment(amount),
          'total_rides': FieldValue.increment(1),
          'last_updated': FieldValue.serverTimestamp(),
        });
      } else {
        // Criar novo documento de estatísticas
        await docRef.set({
          'driver_id': driverId,
          'day_key': dayKey,
          'total_amount': amount,
          'total_rides': 1,
          'created_at': FieldValue.serverTimestamp(),
          'last_updated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('EarningsService: Erro ao atualizar estatísticas diárias: $e');
    }
  }
  
  // Atualizar estatísticas semanais
  Future<void> _updateWeeklyStats(String driverId, String weekKey, double amount) async {
    try {
      final docRef = _firestore
          .collection('driver_stats_weekly')
          .doc('${driverId}_$weekKey');
      
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        await docRef.update({
          'total_amount': FieldValue.increment(amount),
          'total_rides': FieldValue.increment(1),
          'last_updated': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set({
          'driver_id': driverId,
          'week_key': weekKey,
          'total_amount': amount,
          'total_rides': 1,
          'created_at': FieldValue.serverTimestamp(),
          'last_updated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('EarningsService: Erro ao atualizar estatísticas semanais: $e');
    }
  }
  
  // Atualizar estatísticas mensais
  Future<void> _updateMonthlyStats(String driverId, String monthKey, double amount) async {
    try {
      final docRef = _firestore
          .collection('driver_stats_monthly')
          .doc('${driverId}_$monthKey');
      
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        await docRef.update({
          'total_amount': FieldValue.increment(amount),
          'total_rides': FieldValue.increment(1),
          'last_updated': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set({
          'driver_id': driverId,
          'month_key': monthKey,
          'total_amount': amount,
          'total_rides': 1,
          'created_at': FieldValue.serverTimestamp(),
          'last_updated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('EarningsService: Erro ao atualizar estatísticas mensais: $e');
    }
  }
  
  // Obter chave da semana no formato "yyyy-Www" (ex: 2025-W08)
  String _getWeekKey(DateTime date) {
    final int weekNumber = ((date.difference(DateTime(date.year, 1, 1)).inDays) / 7).floor() + 1;
    return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }
  
  // Obter ganhos diários
  Future<Map<String, dynamic>> getDailyEarnings(String date) async {
    try {
      final String driverId = _auth.currentUser?.uid ?? '';
      
      if (driverId.isEmpty) {
        throw Exception('Usuário não autenticado');
      }
      
      final docRef = _firestore
          .collection('driver_stats_daily')
          .doc('${driverId}_$date');
          
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        return {
          'total_amount': 0.0,
          'total_rides': 0,
        };
      }
    } catch (e) {
      print('EarningsService: Erro ao buscar ganhos diários: $e');
      return {
        'total_amount': 0.0,
        'total_rides': 0,
        'error': e.toString(),
      };
    }
  }
  
  // Obter ganhos semanais
  Future<Map<String, dynamic>> getWeeklyEarnings(String weekKey) async {
    try {
      final String driverId = _auth.currentUser?.uid ?? '';
      
      if (driverId.isEmpty) {
        throw Exception('Usuário não autenticado');
      }
      
      final docRef = _firestore
          .collection('driver_stats_weekly')
          .doc('${driverId}_$weekKey');
          
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        return {
          'total_amount': 0.0,
          'total_rides': 0,
        };
      }
    } catch (e) {
      print('EarningsService: Erro ao buscar ganhos semanais: $e');
      return {
        'total_amount': 0.0,
        'total_rides': 0,
        'error': e.toString(),
      };
    }
  }
  
  // Obter ganhos mensais
  Future<Map<String, dynamic>> getMonthlyEarnings(String monthKey) async {
    try {
      final String driverId = _auth.currentUser?.uid ?? '';
      
      if (driverId.isEmpty) {
        throw Exception('Usuário não autenticado');
      }
      
      final docRef = _firestore
          .collection('driver_stats_monthly')
          .doc('${driverId}_$monthKey');
          
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        return {
          'total_amount': 0.0,
          'total_rides': 0,
        };
      }
    } catch (e) {
      print('EarningsService: Erro ao buscar ganhos mensais: $e');
      return {
        'total_amount': 0.0,
        'total_rides': 0,
        'error': e.toString(),
      };
    }
  }
  
  // Obter histórico de corridas com faturamento
  Future<List<Map<String, dynamic>>> getRideHistory({
    String? dateFilter, 
    int limit = 20,
  }) async {
    try {
      final String driverId = _auth.currentUser?.uid ?? '';
      
      if (driverId.isEmpty) {
        throw Exception('Usuário não autenticado');
      }
      
      // Iniciar query
      Query query = _firestore
          .collection('driver_earnings')
          .where('driver_id', isEqualTo: driverId);
          
      // Adicionar filtro de data se necessário
      if (dateFilter != null) {
        query = query.where('day_key', isEqualTo: dateFilter);
      }
      
      // Executar a consulta
      final querySnapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      // Converter resultados
      final result = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Converter Timestamp para DateTime se existir
        if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
          final timestamp = data['timestamp'] as Timestamp;
          data['timestamp'] = timestamp.toDate();
        }
        return data;
      }).toList();
      
      return result;
    } catch (e) {
      print('EarningsService: Erro ao buscar histórico de corridas: $e');
      return [];
    }
  }
}