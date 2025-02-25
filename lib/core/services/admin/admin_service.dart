// lib/core/services/admin/admin_service.dart
import 'package:firebase_database/firebase_database.dart';
import '../../../models/admin/dashboard_stats.dart';
import '../../../models/admin/user_management.dart';
import '../../../models/admin/financial_report.dart';
import '../../../models/admin/ride_management.dart';

class AdminService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  // Referências
  late DatabaseReference _dashboardRef;
  late DatabaseReference _usersRef;
  late DatabaseReference _financialRef;
  late DatabaseReference _ridesRef;
  late DatabaseReference _settingsRef;
  
  AdminService() {
    _dashboardRef = _database.ref().child('admin/dashboard');
    _usersRef = _database.ref().child('users');
    _financialRef = _database.ref().child('financial');
    _ridesRef = _database.ref().child('rides');
    _settingsRef = _database.ref().child('admin/settings');
  }
  
  // Métodos de Dashboard
  
  Future<DashboardStats> getDashboardStats() async {
    try {
      final snapshot = await _dashboardRef.once();
      if (snapshot.snapshot.value == null) {
        return DashboardStats(
          activeUsers: 0,
          onlineDrivers: 0,
          ridesCount: 0,
          dailyRevenue: 0.0,
          hourlyRides: List.filled(24, 0),
          activeRides: [],
        );
      }
      
      Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
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
      Query query = _usersRef;
      
      // Aplicar filtros - note que o Firebase tem limitações em consultas compostas
      // Este é um exemplo simplificado
      if (role != null && role != 'all') {
        query = query.orderByChild('role').equalTo(role);
      } else if (status != null && status != 'all') {
        query = query.orderByChild('status').equalTo(status);
      }
      
      // Paginação simples
      query = query.limitToFirst(limit);
      
      // Obter os dados
      final snapshot = await query.once();
      final List<UserDetails> users = [];
      
      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> values = snapshot.snapshot.value as Map;
        values.forEach((key, userData) {
          // Adicionar o ID
          Map<String, dynamic> user = Map<String, dynamic>.from(userData);
          user['id'] = key;
          
          // Converter para o modelo
          users.add(UserDetails.fromJson(user));
        });
      }
      
      return users;
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }
  
  Future<UserDetails> getUserDetails(String userId) async {
    try {
      final snapshot = await _usersRef.child(userId).once();
      if (snapshot.snapshot.value == null) {
        throw Exception('User not found');
      }
      
      Map<String, dynamic> userData = 
          Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      userData['id'] = userId;
      
      return UserDetails.fromJson(userData);
    } catch (e) {
      throw Exception('Failed to load user details: $e');
    }
  }
  
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _usersRef.child(userId).update({
        'status': status,
        'updated_at': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }
  
  // Métodos de Relatórios Financeiros
  
  Future<FinancialReport> getFinancialReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Obter transações dentro do intervalo de datas
      Query query = _financialRef.child('transactions')
          .orderByChild('date')
          .startAt(startDate.millisecondsSinceEpoch)
          .endAt(endDate.millisecondsSinceEpoch);
          
      final snapshot = await query.once();
      
      // Processar os dados
      List<FinancialTransaction> transactions = [];
      double totalRevenue = 0;
      double platformFees = 0;
      double driverPayouts = 0;
      
      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> values = snapshot.snapshot.value as Map;
        values.forEach((key, data) {
          // Converter para formato adequado
          Map<String, dynamic> transactionData = Map<String, dynamic>.from(data);
          transactionData['id'] = key;
          
          // Criar objeto de transação
          var transaction = FinancialTransaction.fromJson(transactionData);
          transactions.add(transaction);
          
          // Calcular totais
          if (transaction.type == 'credit') {
            totalRevenue += transaction.amount;
          } else if (transaction.type == 'fee') {
            platformFees += transaction.amount;
          } else if (transaction.type == 'payout') {
            driverPayouts += transaction.amount;
          }
        });
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
      Query query = _ridesRef;
      
      // Filtrar por status
      if (status != null && status != 'all') {
        query = query.orderByChild('status').equalTo(status);
      } 
      // Filtrar por data - este é um exemplo simplificado
      else if (startDate != null && endDate != null) {
        query = query.orderByChild('created_at')
            .startAt(startDate.millisecondsSinceEpoch)
            .endAt(endDate.millisecondsSinceEpoch);
      }
      
      // Limitar resultados
      query = query.limitToFirst(limit);
      
      final snapshot = await query.once();
      final List<RideDetails> rides = [];
      
      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> values = snapshot.snapshot.value as Map;
        values.forEach((key, rideData) {
          Map<String, dynamic> ride = Map<String, dynamic>.from(rideData);
          ride['id'] = key;
          
          // Converter dados aninhados
          if (ride['pickup'] is Map) {
            Map<String, dynamic> pickup = Map<String, dynamic>.from(ride['pickup'] as Map);
            ride['pickupAddress'] = pickup['address'];
          }
          
          if (ride['destination'] is Map) {
            Map<String, dynamic> destination = Map<String, dynamic>.from(ride['destination'] as Map);
            ride['destinationAddress'] = destination['address'];
          }
          
          // Adaptar campos para corresponder ao modelo RideDetails
          ride['passengerName'] = ride['passenger_name'] ?? 'Passageiro';
          ride['driverName'] = ride['driver_name'];
          ride['fare'] = ride['estimated_price'] ?? 0.0;
          ride['distance'] = ride['estimated_distance'] ?? 0.0;
          ride['duration'] = ride['estimated_duration'] ?? 0;
          ride['createdAt'] = DateTime.fromMillisecondsSinceEpoch(ride['created_at'] ?? 0);
          
          if (ride['completed_at'] != null) {
            ride['completedAt'] = DateTime.fromMillisecondsSinceEpoch(ride['completed_at']);
          }
          
          // Adicionar informações de pagamento se disponíveis
          if (ride['payment'] != null) {
            Map<String, dynamic> payment = Map<String, dynamic>.from(ride['payment'] as Map);
            ride['paymentInfo'] = {
              'method': payment['method'] ?? ride['payment_method'] ?? 'unknown',
              'status': payment['status'] ?? 'pending',
              'transactionId': payment['transaction_id'],
            };
          }
          
          rides.add(RideDetails.fromJson(ride));
        });
      }
      
      return rides;
    } catch (e) {
      throw Exception('Failed to load rides: $e');
    }
  }
  
  Future<RideDetailsFull> getRideDetails(String rideId) async {
    try {
      final snapshot = await _ridesRef.child(rideId).once();
      if (snapshot.snapshot.value == null) {
        throw Exception('Ride not found');
      }
      
      // Converter dados brutos para o formato esperado
      Map<String, dynamic> rideData = 
          Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      rideData['id'] = rideId;
      
      // Processar dados aninhados
      if (rideData['pickup'] is Map) {
        Map<String, dynamic> pickup = Map<String, dynamic>.from(rideData['pickup'] as Map);
        rideData['pickupAddress'] = pickup['address'];
      }
      
      if (rideData['destination'] is Map) {
        Map<String, dynamic> destination = Map<String, dynamic>.from(rideData['destination'] as Map);
        rideData['destinationAddress'] = destination['address'];
      }
      
      // Adaptar campos para corresponder ao modelo RideDetailsFull
      rideData['passengerName'] = rideData['passenger_name'] ?? 'Passageiro';
      rideData['driverName'] = rideData['driver_name'];
      rideData['passengerId'] = rideData['passenger_id'] ?? '';
      rideData['driverId'] = rideData['driver_id'];
      rideData['fare'] = rideData['estimated_price'] ?? 0.0;
      rideData['distance'] = rideData['estimated_distance'] ?? 0.0;
      rideData['duration'] = rideData['estimated_duration'] ?? 0;
      rideData['platformFee'] = rideData['platform_fee'] ?? (rideData['estimated_price'] ?? 0.0) * 0.15; // 15% como exemplo
      rideData['createdAt'] = DateTime.fromMillisecondsSinceEpoch(rideData['created_at'] ?? 0);
      
      if (rideData['completed_at'] != null) {
        rideData['completedAt'] = DateTime.fromMillisecondsSinceEpoch(rideData['completed_at']);
      }
      
      // Obter histórico de status se existir
      if (rideData['status_history'] is List) {
        List<dynamic> history = rideData['status_history'] as List;
        List<Map<String, dynamic>> statusHistory = [];
        
        for (var item in history) {
          Map<String, dynamic> statusChange = Map<String, dynamic>.from(item);
          statusChange['timestamp'] = DateTime.fromMillisecondsSinceEpoch(statusChange['timestamp'] ?? 0);
          statusHistory.add(statusChange);
        }
        
        rideData['statusHistory'] = statusHistory;
      }
      
      // Adicionar informações de pagamento se disponíveis
      if (rideData['payment'] != null) {
        Map<String, dynamic> payment = Map<String, dynamic>.from(rideData['payment'] as Map);
        rideData['paymentInfo'] = {
          'method': payment['method'] ?? rideData['payment_method'] ?? 'unknown',
          'status': payment['status'] ?? 'pending',
          'transactionId': payment['transaction_id'],
        };
      }
      
      return RideDetailsFull.fromJson(rideData);
    } catch (e) {
      throw Exception('Failed to load ride details: $e');
    }
  }
  
  Future<void> cancelRide(String rideId, String reason) async {
    try {
      // Atualizar o status
      await _ridesRef.child(rideId).update({
        'status': 'cancelled',
        'cancelled_at': ServerValue.timestamp,
        'cancelled_by': 'admin',
        'cancellation_reason': reason,
      });
      
      // Adicionar ao histórico de status
      DatabaseReference historyRef = _ridesRef.child(rideId).child('status_history').push();
      await historyRef.set({
        'status': 'cancelled',
        'timestamp': ServerValue.timestamp,
        'comment': reason,
        'by': 'admin',
      });
    } catch (e) {
      throw Exception('Failed to cancel ride: $e');
    }
  }
  
  // Métodos de Configurações
  
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final snapshot = await _settingsRef.once();
      if (snapshot.snapshot.value == null) {
        // Retornar valores padrão se não houver configurações
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
      
      return Map<String, dynamic>.from(snapshot.snapshot.value as Map);
    } catch (e) {
      throw Exception('Failed to load app settings: $e');
    }
  }
  
  Future<void> updateAppSettings(Map<String, dynamic> settings) async {
    try {
      await _settingsRef.update(settings);
    } catch (e) {
      throw Exception('Failed to update app settings: $e');
    }
  }
}