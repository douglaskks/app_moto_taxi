import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserStatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Referência à coleção de usuários
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  // Obter ID do usuário atual
  String? get _currentUserId => _auth.currentUser?.uid;

  // Atualizar estatísticas do usuário após uma corrida
  Future<void> updateUserStatisticsAfterRide({
    required double rideDistance, 
    required double ridePrice,
    required String rideId,
  }) async {
    if (_currentUserId == null) return;

    final userRef = _usersCollection.doc(_currentUserId);
    final now = DateTime.now();
    
    // Formato para o mês atual (ex: '2025-03' para março de 2025)
    final currentMonth = DateFormat('yyyy-MM').format(now);
    
    // Referência para estatísticas do mês atual
    final statsRef = userRef.collection('ride_statistics').doc(currentMonth);
    
    // Calcular economia (apenas se o preço for menor que 5)
    double savedAmount = 0;
    if (ridePrice < 5.0) {
      savedAmount = 5.0 - ridePrice;
    }
    
    try {
      // Verificar se o documento de estatísticas do mês já existe
      final statsDoc = await statsRef.get();
      
      if (statsDoc.exists) {
        // Atualizar estatísticas existentes do mês
        Map<String, dynamic> data = statsDoc.data() as Map<String, dynamic>;
        
        await statsRef.update({
          'total_rides': (data['total_rides'] ?? 0) + 1,
          'total_distance': (data['total_distance'] ?? 0) + rideDistance,
          'total_saved': (data['total_saved'] ?? 0) + savedAmount,
          'ride_ids': FieldValue.arrayUnion([rideId]),
          'last_updated': now,
        });
      } else {
        // Criar novo documento de estatísticas para o mês
        await statsRef.set({
          'total_rides': 1,
          'total_distance': rideDistance,
          'total_saved': savedAmount,
          'ride_ids': [rideId],
          'month': currentMonth,
          'created_at': now,
          'last_updated': now,
        });
      }
      
      // Também atualizar estatísticas totais do usuário
      await userRef.set({
        'statistics': {
          'total_rides_all_time': FieldValue.increment(1),
          'total_distance_all_time': FieldValue.increment(rideDistance),
          'total_saved_all_time': FieldValue.increment(savedAmount),
          'last_ride_date': now,
        }
      }, SetOptions(merge: true));
      
    } catch (e) {
      print('Erro ao atualizar estatísticas: $e');
      // Aqui você pode implementar uma lógica de retry ou logging de erros
    }
  }
  
  // Obter estatísticas totais do usuário
  Future<Map<String, dynamic>> getUserStatistics() async {
    if (_currentUserId == null) {
      return {
        'total_rides': 0,
        'total_distance': 0,
        'total_saved': 0,
      };
    }

    try {
      final userDoc = await _usersCollection.doc(_currentUserId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final stats = userData['statistics'] as Map<String, dynamic>? ?? {};
        
        return {
          'total_rides': stats['total_rides_all_time'] ?? 0,
          'total_distance': stats['total_distance_all_time'] ?? 0,
          'total_saved': stats['total_saved_all_time'] ?? 0,
        };
      }
    } catch (e) {
      print('Erro ao obter estatísticas: $e');
    }
    
    // Valores padrão se ocorrer um erro
    return {
      'total_rides': 0,
      'total_distance': 0,
      'total_saved': 0,
    };
  }
  
  // Obter estatísticas do mês atual
  Future<Map<String, dynamic>> getCurrentMonthStatistics() async {
    if (_currentUserId == null) {
      return {
        'total_rides': 0,
        'total_distance': 0,
        'total_saved': 0,
      };
    }
    
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    
    try {
      final statsDoc = await _usersCollection
          .doc(_currentUserId)
          .collection('ride_statistics')
          .doc(currentMonth)
          .get();
      
      if (statsDoc.exists) {
        final data = statsDoc.data() as Map<String, dynamic>;
        
        return {
          'total_rides': data['total_rides'] ?? 0,
          'total_distance': data['total_distance'] ?? 0,
          'total_saved': data['total_saved'] ?? 0,
        };
      }
    } catch (e) {
      print('Erro ao obter estatísticas do mês atual: $e');
    }
    
    // Valores padrão se ocorrer um erro
    return {
      'total_rides': 0,
      'total_distance': 0,
      'total_saved': 0,
    };
  }
  
  // Obter histórico mensal de estatísticas
  Future<List<Map<String, dynamic>>> getMonthlyStatisticsHistory({int limit = 12}) async {
    if (_currentUserId == null) return [];
    
    try {
      final querySnapshot = await _usersCollection
          .doc(_currentUserId)
          .collection('ride_statistics')
          .orderBy('month', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'month': data['month'],
          'total_rides': data['total_rides'] ?? 0,
          'total_distance': data['total_distance'] ?? 0,
          'total_saved': data['total_saved'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Erro ao obter histórico de estatísticas: $e');
      return [];
    }
  }
}