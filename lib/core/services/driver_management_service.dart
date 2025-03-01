import 'package:firebase_database/firebase_database.dart';
import '../../models/admin/user_management.dart';

class DriverManagementService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late DatabaseReference _usersRef;

  DriverManagementService() {
    _usersRef = _database.ref().child('users');
  }

  Future<List<UserDetails>> getAllDrivers({
    bool? activeOnly,
    bool? documentsVerified,
  }) async {
    try {
      // Obter todos os usuários primeiro
      final snapshot = await _usersRef.once();
      final List<UserDetails> drivers = [];

      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> values = snapshot.snapshot.value as Map;
        
        values.forEach((key, userData) {
          try {
            // Adicionar o ID
            Map<String, dynamic> user = Map<String, dynamic>.from(userData);
            user['id'] = key;
            
            // Filtrar apenas motoristas
            if (user['role'] == 'driver') {
              // Aplicar filtros adicionais
              bool includeDriver = true;
              
              // Filtro de status ativo
              if (activeOnly == true && user['status'] != 'active') {
                includeDriver = false;
              }
              
              // Filtro de documentos verificados
              if (documentsVerified == true) {
                bool hasVerifiedDocs = false;
                if (user['profile'] != null && 
                    user['profile']['driverInfo'] != null &&
                    user['profile']['driverInfo']['documentsVerified'] == true) {
                  hasVerifiedDocs = true;
                }
                
                if (!hasVerifiedDocs) {
                  includeDriver = false;
                }
              }
              
              // Se passar em todos os filtros, adicionar à lista
              if (includeDriver) {
                drivers.add(UserDetails.fromJson(user));
              }
            }
          } catch (e) {
            print('Erro ao processar motorista: $e');
            // Continuar processando outros motoristas
          }
        });
      }
      
      return drivers;
    } catch (e) {
      print('Erro ao buscar motoristas: $e');
      throw Exception('Falha ao carregar motoristas: $e');
    }
  }

  // Método para atualizar status do motorista
  Future<void> updateDriverStatus(String driverId, String newStatus) async {
    try {
      await _usersRef.child(driverId).update({
        'status': newStatus,
        'updated_at': ServerValue.timestamp,
      });
    } catch (e) {
      print('Erro ao atualizar status do motorista: $e');
      throw Exception('Falha ao atualizar status do motorista: $e');
    }
  }

  // Método para verificar documentos do motorista
  Future<void> verifyDriverDocuments(String driverId, bool verified) async {
    try {
      await _usersRef.child(driverId).update({
        'profile/driverInfo/documentsVerified': verified,
        'updated_at': ServerValue.timestamp,
      });
    } catch (e) {
      print('Erro ao verificar documentos do motorista: $e');
      throw Exception('Falha ao verificar documentos do motorista: $e');
    }
  }
}