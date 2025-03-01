import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/admin/dashboard_stats.dart';
import '../../../models/admin/user_management.dart';
import '../../../models/admin/financial_report.dart';
import '../../../models/admin/ride_management.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Métodos de Dashboard
  Future<DashboardStats> getDashboardStats() async {
    try {
      final snapshot = await _firestore.collection('admin').doc('dashboard').get();
      if (!snapshot.exists) {
        return DashboardStats(
          activeUsers: 0,
          onlineDrivers: 0,
          ridesCount: 0,
          dailyRevenue: 0.0,
          hourlyRides: List.filled(24, 0),
          activeRides: [],
        );
      }
      
      Map<String, dynamic> data = snapshot.data()!;
      return DashboardStats.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load dashboard stats: $e');
    }
  }
  
  // Métodos de Usuários
  Future<List<UserDetails>> getUsers({
    String? role,
    String? status,
    String? searchQuery,
    int limit = 20,
    String? lastUserId,
  }) async {
    try {
      Query query = _firestore.collection('users');
      
      // Aplicar filtros
      if (role != null && role != 'all') {
        query = query.where('role', isEqualTo: role);
      }
      
      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }
      
      // Paginação
      query = query.limit(limit);
      
      if (lastUserId != null) {
        DocumentSnapshot lastDoc = await _firestore.collection('users').doc(lastUserId).get();
        query = query.startAfterDocument(lastDoc);
      }
      
      // Executar consulta
      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return UserDetails.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }
  
  Future<UserDetails> getUserDetails(String userId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      if (!snapshot.exists) {
        throw Exception('User not found');
      }
      
      Map<String, dynamic> userData = snapshot.data()!;
      userData['id'] = userId;
      
      return UserDetails.fromJson(userData);
    } catch (e) {
      throw Exception('Failed to load user details: $e');
    }
  }
  
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }
  
  // Métodos Financeiros
  Future<FinancialReport> getFinancialReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      Query query = _firestore.collection('financial/transactions/items')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate);
      
      QuerySnapshot snapshot = await query.get();
      
      List<FinancialTransaction> transactions = [];
      double totalRevenue = 0;
      double platformFees = 0;
      double driverPayouts = 0;
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        var transaction = FinancialTransaction.fromJson(data);
        transactions.add(transaction);
        
        if (transaction.type == 'credit') {
          totalRevenue += transaction.amount;
        } else if (transaction.type == 'fee') {
          platformFees += transaction.amount;
        } else if (transaction.type == 'payout') {
          driverPayouts += transaction.amount;
        }
      }
      
      return FinancialReport(
        totalRevenue: totalRevenue,
        platformFees: platformFees,
        driverPayouts: driverPayouts,
        transactions: transactions,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to load financial report: $e');
    }
  }
  
  // Métodos de Gerenciamento de Corridas
  Future<List<RideDetails>> getRides({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int limit = 20,
    String? lastRideId,
  }) async {
    try {
      Query query = _firestore.collection('rides');
      
      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }
      
      if (startDate != null && endDate != null) {
        query = query.where('created_at', isGreaterThanOrEqualTo: startDate)
                     .where('created_at', isLessThanOrEqualTo: endDate);
      }
      
      query = query.limit(limit);
      
      if (lastRideId != null) {
        DocumentSnapshot lastDoc = await _firestore.collection('rides').doc(lastRideId).get();
        query = query.startAfterDocument(lastDoc);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      List<RideDetails> rides = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Adaptar campos para o modelo
        data['passengerName'] = data['passenger_name'] ?? 'Passageiro';
        data['driverName'] = data['driver_name'];
        data['fare'] = data['estimated_price'] ?? 0.0;
        data['distance'] = data['estimated_distance'] ?? 0.0;
        data['duration'] = data['estimated_duration'] ?? 0;
        
        // Endereços
        if (data['pickup'] != null) {
          data['pickupAddress'] = data['pickup']['address'];
        }
        
        if (data['destination'] != null) {
          data['destinationAddress'] = data['destination']['address'];
        }
        
        // Datas
        if (data['created_at'] != null) {
          if (data['created_at'] is Timestamp) {
            data['createdAt'] = (data['created_at'] as Timestamp).toDate();
          }
        }
        
        if (data['completed_at'] != null) {
          if (data['completed_at'] is Timestamp) {
            data['completedAt'] = (data['completed_at'] as Timestamp).toDate();
          }
        }
        
        // Pagamento
        if (data['payment'] != null) {
          data['paymentInfo'] = {
            'method': data['payment']['method'] ?? data['payment_method'] ?? 'unknown',
            'status': data['payment']['status'] ?? 'pending',
            'transactionId': data['payment']['transaction_id'],
          };
        }
        
        rides.add(RideDetails.fromJson(data));
      }
      
      return rides;
    } catch (e) {
      throw Exception('Failed to load rides: $e');
    }
  }
  
  // Configurações
  // lib/core/services/admin/admin_service.dart
Future<Map<String, dynamic>> getAppSettings() async {
  try {
    final snapshot = await _firestore.collection('admin').doc('settings').get();
    if (!snapshot.exists) {
      // Retornar valores padrão
      return {
        'enableNotifications': true,
        'requireDocumentVerification': true,
        'allowCashPayment': true,
        'platformFeePercentage': 15.0,
        'minFare': 5.0,
        'pricePerKm': 2.0,
        'pricePerMinute': 0.2,
        'language': 'pt_BR',
        'theme': 'system',
      };
    }
    
    return snapshot.data()!;
  } catch (e) {
    throw Exception('Falha ao carregar configurações: $e');
  }
}

Future<void> updateAppSettings(Map<String, dynamic> settings) async {
  try {
    await _firestore.collection('admin').doc('settings').set(
      settings,
      SetOptions(merge: true),
    );
  } catch (e) {
    throw Exception('Falha ao atualizar configurações: $e');
  }
}

// Métodos getRideDetails e cancelRide DEVEM ESTAR NO MESMO NÍVEL 
// que updateAppSettings, NÃO DENTRO DELE
Future<RideDetailsFull> getRideDetails(String rideId) async {
  try {
    final snapshot = await _firestore.collection('rides').doc(rideId).get();
    if (!snapshot.exists) {
      throw Exception('Corrida não encontrada');
    }
    
    Map<String, dynamic> data = snapshot.data()!;
    data['id'] = rideId;
    
    // Adaptar campos para o modelo
    data['passengerName'] = data['passenger_name'] ?? 'Passageiro';
    data['driverName'] = data['driver_name'];
    data['fare'] = data['estimated_price'] ?? 0.0;
    data['distance'] = data['estimated_distance'] ?? 0.0;
    data['duration'] = data['estimated_duration'] ?? 0;
    
    // Campos específicos do RideDetailsFull
    data['passengerId'] = data['passenger_id'] ?? '';
    data['driverId'] = data['driver_id'];
    data['platformFee'] = _calculatePlatformFee(data);
    
    // Buscar histórico de status
    data['statusHistory'] = await _fetchStatusHistory(rideId);
    
    // Datas
    if (data['created_at'] is Timestamp) {
      data['createdAt'] = (data['created_at'] as Timestamp).millisecondsSinceEpoch;
    }
    
    if (data['completed_at'] is Timestamp) {
      data['completedAt'] = (data['completed_at'] as Timestamp).millisecondsSinceEpoch;
    }
    
    // Pagamento
    if (data['payment'] != null) {
      data['paymentInfo'] = {
        'method': data['payment']['method'] ?? data['payment_method'] ?? 'unknown',
        'status': data['payment']['status'] ?? 'pending',
        'transactionId': data['payment']['transaction_id'],
      };
    }
    
    return RideDetailsFull.fromJson(data);
  } catch (e) {
    throw Exception('Falha ao carregar detalhes da corrida: $e');
  }
}

// Métodos auxiliares
double _calculatePlatformFee(Map<String, dynamic> rideData) {
  // Lógica para calcular a taxa da plataforma
  double fare = rideData['estimated_price'] ?? 0.0;
  return fare * 0.1; // Exemplo: 10% de taxa
}

Future<List<StatusChange>> _fetchStatusHistory(String rideId) async {
  try {
    final historySnapshot = await _firestore
        .collection('rides')
        .doc(rideId)
        .collection('status_history')
        .orderBy('timestamp')
        .get();
    
    return historySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data();
      data['timestamp'] = doc['timestamp']?.millisecondsSinceEpoch ?? 0;
      return StatusChange.fromJson(data);
    }).toList();
  } catch (e) {
    // Log do erro ou tratamento conforme necessário
    return [];
  }
}

Future<void> cancelRide(String rideId, {String reason = 'Cancelado pelo administrador'}) async {
  try {
    // Buscar a corrida primeiro para validar sua existência
    await getRideDetails(rideId);
    
    // Atualizar o status da corrida para cancelado
    await _firestore.collection('rides').doc(rideId).update({
      'status': 'cancelled',
      'cancellation_reason': reason,
      'cancelled_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    throw Exception('Falha ao cancelar corrida: $e');
  }
}
}