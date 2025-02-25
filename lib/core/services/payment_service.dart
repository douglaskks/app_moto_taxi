// Arquivo: lib/core/services/payment_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

enum PaymentMethod {
  cash,      // Dinheiro
  credit,    // Cartão de crédito
  debit,     // Cartão de débito
  pix,       // Pix (pagamento instantâneo brasileiro)
  wallet     // Carteira digital do app
}

enum PaymentStatus {
  pending,    // Pagamento pendente
  processing, // Pagamento em processamento
  completed,  // Pagamento concluído com sucesso
  failed,     // Pagamento falhou
  refunded,   // Pagamento reembolsado
  cancelled   // Pagamento cancelado
}

class PaymentDetails {
  final String id;
  final String rideId;
  final String passengerId;
  final String? driverId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? transactionId;
  final String? failureReason;
  final double? appFee; // Taxa do aplicativo
  
  PaymentDetails({
    required this.id,
    required this.rideId,
    required this.passengerId,
    this.driverId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.transactionId,
    this.failureReason,
    this.appFee,
  });
  
  factory PaymentDetails.fromMap(Map<String, dynamic> map, String id) {
    return PaymentDetails(
      id: id,
      rideId: map['ride_id'] ?? '',
      passengerId: map['passenger_id'] ?? '',
      driverId: map['driver_id'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${map['method']}',
        orElse: () => PaymentMethod.cash,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${map['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: map['created_at'] != null 
          ? (map['created_at'] is Timestamp 
            ? (map['created_at'] as Timestamp).toDate() 
            : DateTime.fromMillisecondsSinceEpoch(map['created_at']))
          : DateTime.now(),
      completedAt: map['completed_at'] != null 
          ? (map['completed_at'] is Timestamp 
            ? (map['completed_at'] as Timestamp).toDate() 
            : DateTime.fromMillisecondsSinceEpoch(map['completed_at']))
          : null,
      transactionId: map['transaction_id'],
      failureReason: map['failure_reason'],
      appFee: (map['app_fee'] ?? 0.0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'ride_id': rideId,
      'passenger_id': passengerId,
      'driver_id': driverId,
      'amount': amount,
      'method': method.toString().split('.').last,
      'status': status.toString().split('.').last,
      'created_at': createdAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'transaction_id': transactionId,
      'failure_reason': failureReason,
      'app_fee': appFee,
    };
  }
}

class PaymentService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  // Configurações
  final double _appFeePercentage = 0.15; // 15% de taxa para o app
  
  // Registrar um novo método de pagamento para o usuário
  Future<void> registerPaymentMethod({
    required PaymentMethod method,
    required Map<String, dynamic> details,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    final String userId = _auth.currentUser!.uid;
    
    // Gera um ID único para o método de pagamento
    DocumentReference methodRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .doc();
    
    // Salva os detalhes do método de pagamento
    await methodRef.set({
      'method': method.toString().split('.').last,
      'details': details,
      'is_default': false,
      'created_at': FieldValue.serverTimestamp(),
    });
    
    // Se for o primeiro método, define como padrão
    QuerySnapshot methods = await _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .get();
    
    if (methods.docs.length == 1) {
      await methodRef.update({'is_default': true});
    }
  }
  
  // Obter métodos de pagamento do usuário
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    final String userId = _auth.currentUser!.uid;
    
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .orderBy('created_at', descending: true)
        .get();
    
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }
  
  // Definir método de pagamento padrão
  Future<void> setDefaultPaymentMethod(String methodId) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    final String userId = _auth.currentUser!.uid;
    
    // Primeiro, remove o estado padrão de todos os métodos
    QuerySnapshot methods = await _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .where('is_default', isEqualTo: true)
        .get();
    
    for (var doc in methods.docs) {
      await doc.reference.update({'is_default': false});
    }
    
    // Define o novo método padrão
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .doc(methodId)
        .update({'is_default': true});
  }
  
  // Excluir método de pagamento
  Future<void> deletePaymentMethod(String methodId) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    final String userId = _auth.currentUser!.uid;
    
    // Verifica se o método é o padrão
    DocumentSnapshot method = await _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .doc(methodId)
        .get();
    
    bool isDefault = (method.data() as Map<String, dynamic>)['is_default'] ?? false;
    
    // Exclui o método
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .doc(methodId)
        .delete();
    
    // Se era o padrão, define outro como padrão (se existir)
    if (isDefault) {
      QuerySnapshot methods = await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();
      
      if (methods.docs.isNotEmpty) {
        await methods.docs.first.reference.update({'is_default': true});
      }
    }
  }
  
  // Criar um pagamento para uma corrida
  Future<PaymentDetails> createPayment({
    required String rideId,
    required double amount,
    required PaymentMethod method,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    final String passengerId = _auth.currentUser!.uid;
    
    // Obter informações da corrida
    final rideSnapshot = await _database
        .ref()
        .child('rides')
        .child(rideId)
        .get();
    
    if (rideSnapshot.value == null) {
      throw Exception('Corrida não encontrada');
    }
    
    final Map<dynamic, dynamic> rideData = rideSnapshot.value as Map<dynamic, dynamic>;
    final String? driverId = rideData['driver_id'];
    
    // Calcular taxa do aplicativo
    final double appFee = amount * _appFeePercentage;
    
    // Criar entrada no Firestore
    DocumentReference paymentRef = _firestore
        .collection('payments')
        .doc();
    
    final PaymentDetails payment = PaymentDetails(
      id: paymentRef.id,
      rideId: rideId,
      passengerId: passengerId,
      driverId: driverId,
      amount: amount,
      method: method,
      status: method == PaymentMethod.cash 
          ? PaymentStatus.pending 
          : PaymentStatus.processing,
      createdAt: DateTime.now(),
      appFee: appFee,
    );
    
    await paymentRef.set(payment.toMap());
    
    // Se for pagamento em dinheiro, marcar como pendente
    // Se for outro método, processar o pagamento
    if (method != PaymentMethod.cash) {
      // Em uma integração real, aqui seria o ponto para conectar com a API
      // do gateway de pagamento (Stripe, PayPal, etc.)
      
      // Simulando um processamento de pagamento bem-sucedido
      await Future.delayed(Duration(seconds: 2));
      
      await paymentRef.update({
        'status': PaymentStatus.completed.toString().split('.').last,
        'completed_at': FieldValue.serverTimestamp(),
        'transaction_id': 'sim_${DateTime.now().millisecondsSinceEpoch}',
      });
      
      // Atualizar o status da corrida
      await _database
          .ref()
          .child('rides')
          .child(rideId)
          .update({'payment_status': 'completed'});
      
      // Em uma implementação real, aqui você também faria:
      // 1. Transferir o pagamento para a conta do motorista (menos a taxa)
      // 2. Enviar recibos por email
      // 3. Atualizar saldos em carteiras digitais, se aplicável
    }
    
    return payment;
  }
  
  // Confirmar pagamento em dinheiro (chamado pelo motorista)
  Future<void> confirmCashPayment(String paymentId) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    final String driverId = _auth.currentUser!.uid;
    
    // Verificar se o motorista é o correto para esta corrida
    DocumentSnapshot paymentDoc = await _firestore
        .collection('payments')
        .doc(paymentId)
        .get();
    
    if (!paymentDoc.exists) {
      throw Exception('Pagamento não encontrado');
    }
    
    Map<String, dynamic> paymentData = paymentDoc.data() as Map<String, dynamic>;
    
    if (paymentData['driver_id'] != driverId) {
      throw Exception('Motorista não autorizado para esta operação');
    }
    
    if (paymentData['method'] != PaymentMethod.cash.toString().split('.').last) {
      throw Exception('Este pagamento não é em dinheiro');
    }
    
    // Atualizar status do pagamento
    await paymentDoc.reference.update({
      'status': PaymentStatus.completed.toString().split('.').last,
      'completed_at': FieldValue.serverTimestamp(),
    });
    
    // Atualizar status de pagamento da corrida
    await _database
        .ref()
        .child('rides')
        .child(paymentData['ride_id'])
        .update({'payment_status': 'completed'});
  }
  
  // Obter histórico de pagamentos do usuário
  Future<List<PaymentDetails>> getPaymentHistory() async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    final String userId = _auth.currentUser!.uid;
    
    // Verificar se é passageiro ou motorista
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
    
    if (!userDoc.exists) {
      throw Exception('Usuário não encontrado');
    }
    
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    String userType = userData['userType'] ?? '';
    
    // Buscar pagamentos baseados no tipo de usuário
    QuerySnapshot payments;
    if (userType == 'passenger') {
      payments = await _firestore
          .collection('payments')
          .where('passenger_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();
    } else {
      payments = await _firestore
          .collection('payments')
          .where('driver_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();
    }
    
    return payments.docs.map((doc) {
      return PaymentDetails.fromMap(
        doc.data() as Map<String, dynamic>, 
        doc.id
      );
    }).toList();
  }
  
  // Obter detalhes de um pagamento específico
  Future<PaymentDetails?> getPaymentDetails(String paymentId) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    DocumentSnapshot doc = await _firestore
        .collection('payments')
        .doc(paymentId)
        .get();
    
    if (!doc.exists) {
      return null;
    }
    
    return PaymentDetails.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
  
  // Calcular preço estimado para uma corrida
  double calculateEstimatedPrice(double distanceInKm, double durationInMinutes) {
    // Fórmula básica para cálculo de preço:
    // Preço base + (preço por km * distância) + (preço por minuto * duração estimada)
    
    const double basePrice = 2.0;     // Taxa base (bandeirada)
    const double pricePerKm = 2.5;    // Preço por km
    const double pricePerMinute = 0.2; // Preço por minuto
    
    return basePrice + (pricePerKm * distanceInKm) + (pricePerMinute * durationInMinutes);
  }
  
  // Verificar se um usuário tem pelo menos um método de pagamento cadastrado
  Future<bool> hasPaymentMethod() async {
    if (_auth.currentUser == null) {
      return false;
    }
    
    final String userId = _auth.currentUser!.uid;
    
    QuerySnapshot methods = await _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .limit(1)
        .get();
    
    return methods.docs.isNotEmpty;
  }
}