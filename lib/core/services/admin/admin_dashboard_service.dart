import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      // Obter contagem de usuários (passageiros)
      final usersQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'passenger')
          .count()
          .get();
      final totalUsers = usersQuery.count;
      
      // Obter contagem de motoristas
      final driversQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .count()
          .get();
      final totalDrivers = driversQuery.count;
      
      // Obter contagem e dados de corridas
      final ridesQuery = await _firestore.collection('rides').count().get();
      final totalRides = ridesQuery.count;
      
      // Obter corridas recentes
      final recentRidesQuery = await _firestore
          .collection('rides')
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();
      
      final recentRides = recentRidesQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'driver': data['driver_name'] ?? 'Desconhecido',
          'date': _formatDate(data['created_at']),
          'price': data['final_price'] ?? 0.0,
          'status': data['status'] ?? 'unknown',
        };
      }).toList();
      
      // Calcular receita total
      double totalRevenue = 0;
      await _firestore
          .collection('rides')
          .where('status', isEqualTo: 'completed')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          totalRevenue += (doc.data()['final_price'] ?? 0).toDouble();
        }
      });
      
      // Obter dados para gráfico de corridas da semana
      final Map<String, double> weeklyRides = {
        'Dom': 0, 'Seg': 0, 'Ter': 0, 'Qua': 0, 'Qui': 0, 'Sex': 0, 'Sáb': 0
      };
      
      // Calcular data de início da semana (domingo)
      final now = DateTime.now();
      final firstDayOfWeek = now.subtract(Duration(days: now.weekday % 7));
      
      // Consultar corridas da semana atual
      await _firestore
          .collection('rides')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfWeek))
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          final createdAt = (doc.data()['created_at'] as Timestamp).toDate();
          final dayOfWeek = createdAt.weekday % 7; // 0 = domingo, 1 = segunda, etc.
          
          final dayName = _getDayName(dayOfWeek);
          weeklyRides[dayName] = (weeklyRides[dayName] ?? 0) + 1;
        }
      });
      
      return {
        'totalUsers': totalUsers,
        'totalDrivers': totalDrivers,
        'totalRides': totalRides,
        'totalRevenue': totalRevenue,
        'recentRides': recentRides,
        'weeklyRides': weeklyRides,
      };
    } catch (e) {
      print('Erro ao obter dados do dashboard: $e');
      return {
        'totalUsers': 0,
        'totalDrivers': 0,
        'totalRides': 0,
        'totalRevenue': 0,
        'recentRides': [],
        'weeklyRides': {},
      };
    }
  }
  
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Data desconhecida';
    
    final date = timestamp is Timestamp 
        ? timestamp.toDate() 
        : DateTime.fromMillisecondsSinceEpoch(0);
    
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 0: return 'Dom';
      case 1: return 'Seg';
      case 2: return 'Ter';
      case 3: return 'Qua';
      case 4: return 'Qui';
      case 5: return 'Sex';
      case 6: return 'Sáb';
      default: return '';
    }
  }
  
  // Adicionar método para dados detalhados de corridas por período
  Future<Map<String, dynamic>> getRidesDataByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Converter para Timestamp
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);
      
      // Consultar corridas no período
      final ridesQuery = await _firestore
          .collection('rides')
          .where('created_at', isGreaterThanOrEqualTo: startTimestamp)
          .where('created_at', isLessThanOrEqualTo: endTimestamp)
          .get();
          
      // Dados para análise
      int totalRides = ridesQuery.docs.length;
      int completedRides = 0;
      int cancelledRides = 0;
      double totalRevenue = 0;
      double averageRidePrice = 0;
      
      // Mapa para contagem por status
      Map<String, int> ridesByStatus = {};
      
      // Processar documentos
      for (var doc in ridesQuery.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? '';
        
        // Incrementar contagem por status
        ridesByStatus[status] = (ridesByStatus[status] ?? 0) + 1;
        
        // Contagem por status específico
        if (status == 'completed') {
          completedRides++;
          totalRevenue += (data['final_price'] ?? 0).toDouble();
        } else if (status == 'cancelled') {
          cancelledRides++;
        }
      }
      
      // Calcular média se houver corridas completadas
      if (completedRides > 0) {
        averageRidePrice = totalRevenue / completedRides;
      }
      
      // Calcular taxa de conclusão
      double completionRate = totalRides > 0 ? (completedRides / totalRides) * 100 : 0;
      double cancellationRate = totalRides > 0 ? (cancelledRides / totalRides) * 100 : 0;
      
      return {
        'totalRides': totalRides,
        'completedRides': completedRides,
        'cancelledRides': cancelledRides,
        'totalRevenue': totalRevenue,
        'averageRidePrice': averageRidePrice,
        'completionRate': completionRate,
        'cancellationRate': cancellationRate,
        'ridesByStatus': ridesByStatus,
      };
    } catch (e) {
      print('Erro ao obter dados de corridas por período: $e');
      return {
        'totalRides': 0,
        'completedRides': 0,
        'cancelledRides': 0,
        'totalRevenue': 0,
        'averageRidePrice': 0,
        'completionRate': 0,
        'cancellationRate': 0,
        'ridesByStatus': {},
      };
    }
  }
  
  // Obter dados de usuários mais ativos
  Future<List<Map<String, dynamic>>> getTopUsers({int limit = 5}) async {
    try {
      // Obter todas as corridas
      final ridesQuery = await _firestore
          .collection('rides')
          .where('status', isEqualTo: 'completed')
          .get();
      
      // Mapa para contar corridas por usuário
      Map<String, int> rideCountByUser = {};
      Map<String, String> userNames = {};
      
      // Processar documentos
      for (var doc in ridesQuery.docs) {
        final data = doc.data();
        final userId = data['passenger_id']?.toString() ?? '';
        final userName = data['passenger_name']?.toString() ?? 'Usuário';
        
        if (userId.isNotEmpty) {
          rideCountByUser[userId] = (rideCountByUser[userId] ?? 0) + 1;
          userNames[userId] = userName;
        }
      }
      
      // Converter para lista e ordenar
      List<Map<String, dynamic>> topUsers = rideCountByUser.entries.map((entry) {
        return {
          'userId': entry.key,
          'name': userNames[entry.key] ?? 'Usuário',
          'rideCount': entry.value,
        };
      }).toList();
      
      // Ordenar por número de corridas (decrescente)
      topUsers.sort((a, b) => (b['rideCount'] as int).compareTo(a['rideCount'] as int));
      
      // Limitar ao número especificado
      if (topUsers.length > limit) {
        topUsers = topUsers.sublist(0, limit);
      }
      
      return topUsers;
    } catch (e) {
      print('Erro ao obter usuários mais ativos: $e');
      return [];
    }
  }
  
  // Obter dados de motoristas mais ativos
  Future<List<Map<String, dynamic>>> getTopDrivers({int limit = 5}) async {
    try {
      // Obter todas as corridas
      final ridesQuery = await _firestore
          .collection('rides')
          .where('status', isEqualTo: 'completed')
          .get();
      
      // Mapa para contar corridas por motorista
      Map<String, int> rideCountByDriver = {};
      Map<String, String> driverNames = {};
      Map<String, double> revenueByDriver = {};
      
      // Processar documentos
      for (var doc in ridesQuery.docs) {
        final data = doc.data();
        final driverId = data['driver_id']?.toString() ?? '';
        final driverName = data['driver_name']?.toString() ?? 'Motorista';
        final price = (data['final_price'] ?? 0).toDouble();
        
        if (driverId.isNotEmpty) {
          rideCountByDriver[driverId] = (rideCountByDriver[driverId] ?? 0) + 1;
          driverNames[driverId] = driverName;
          revenueByDriver[driverId] = (revenueByDriver[driverId] ?? 0) + price;
        }
      }
      
      // Converter para lista e ordenar
      List<Map<String, dynamic>> topDrivers = rideCountByDriver.entries.map((entry) {
        return {
          'driverId': entry.key,
          'name': driverNames[entry.key] ?? 'Motorista',
          'rideCount': entry.value,
          'revenue': revenueByDriver[entry.key] ?? 0,
        };
      }).toList();
      
      // Ordenar por número de corridas (decrescente)
      topDrivers.sort((a, b) => (b['rideCount'] as int).compareTo(a['rideCount'] as int));
      
      // Limitar ao número especificado
      if (topDrivers.length > limit) {
        topDrivers = topDrivers.sublist(0, limit);
      }
      
      return topDrivers;
    } catch (e) {
      print('Erro ao obter motoristas mais ativos: $e');
      return [];
    }
  }
  
  // Método para obter lista detalhada de motoristas
  Future<List<Map<String, dynamic>>> getDriversList() async {
    try {
      final QuerySnapshot driversSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .get();
          
      return driversSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Nome não informado',
          'phone': data['phoneNumber'] ?? 'Telefone não informado',
          'email': data['email'] ?? 'Email não informado',
          'rating': data['rating'] ?? 0.0,
          'status': data['status'] ?? 'inactive',
          'profileImage': data['profileImage'],
          'registrationDate': _formatDate(data['created_at']),
          // Mais campos podem ser adicionados conforme necessário
        };
      }).toList();
    } catch (e) {
      print('Erro ao obter lista de motoristas: $e');
      return [];
    }
  }
}