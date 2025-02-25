// Arquivo: lib/core/services/chat_service.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? locationUrl; // Formato: "latitude,longitude"

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.locationUrl,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['sender_id'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp']) 
          : DateTime.now(),
      isRead: map['is_read'] ?? false,
      imageUrl: map['image_url'],
      locationUrl: map['location_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_read': isRead,
      'image_url': imageUrl,
      'location_url': locationUrl,
    };
  }
}

class ChatService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Obter referência ao chat de uma corrida
  DatabaseReference _getChatRef(String rideId) {
    return _database.ref().child('chats').child(rideId);
  }
  
  // Enviar mensagem de texto
  Future<void> sendTextMessage(String rideId, String text) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    final String senderId = _auth.currentUser!.uid;
    final DatabaseReference chatRef = _getChatRef(rideId);
    final DatabaseReference newMessageRef = chatRef.push();
    
    await newMessageRef.set({
      'sender_id': senderId,
      'text': text,
      'timestamp': ServerValue.timestamp,
      'is_read': false,
    });
  }
  
  // Enviar localização atual
  Future<void> sendLocation(String rideId, double latitude, double longitude) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    final String senderId = _auth.currentUser!.uid;
    final DatabaseReference chatRef = _getChatRef(rideId);
    final DatabaseReference newMessageRef = chatRef.push();
    
    await newMessageRef.set({
      'sender_id': senderId,
      'text': 'Compartilhou a localização',
      'timestamp': ServerValue.timestamp,
      'is_read': false,
      'location_url': '$latitude,$longitude',
    });
  }
  
  // Enviar imagem (URL da imagem já deve ter sido obtida após upload para o Storage)
  Future<void> sendImage(String rideId, String imageUrl) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    final String senderId = _auth.currentUser!.uid;
    final DatabaseReference chatRef = _getChatRef(rideId);
    final DatabaseReference newMessageRef = chatRef.push();
    
    await newMessageRef.set({
      'sender_id': senderId,
      'text': 'Enviou uma imagem',
      'timestamp': ServerValue.timestamp,
      'is_read': false,
      'image_url': imageUrl,
    });
  }
  
  // Marcar mensagem como lida
  Future<void> markMessageAsRead(String rideId, String messageId) async {
    await _getChatRef(rideId).child(messageId).update({'is_read': true});
  }
  
  // Marcar todas as mensagens como lidas
  Future<void> markAllMessagesAsRead(String rideId) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    final String currentUserId = _auth.currentUser!.uid;
    final DatabaseReference chatRef = _getChatRef(rideId);
    
    final snapshot = await chatRef.get();
    if (snapshot.value != null) {
      final Map<dynamic, dynamic> messages = snapshot.value as Map<dynamic, dynamic>;
      
      // Marcar como lidas apenas as mensagens não enviadas pelo usuário atual
      messages.forEach((key, value) {
        if (value['sender_id'] != currentUserId && value['is_read'] == false) {
          chatRef.child(key).update({'is_read': true});
        }
      });
    }
  }
  
  // Obter stream de mensagens
  Stream<List<ChatMessage>> getMessages(String rideId) {
    return _getChatRef(rideId).onValue.map((event) {
      if (event.snapshot.value == null) {
        return [];
      }
      
      try {
        final Map<dynamic, dynamic> messagesMap = event.snapshot.value as Map<dynamic, dynamic>;
        
        final List<ChatMessage> messages = messagesMap.entries.map((entry) {
          return ChatMessage.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        }).toList();
        
        // Ordenar por timestamp
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        return messages;
      } catch (e) {
        print('Erro ao processar mensagens: $e');
        return [];
      }
    });
  }
  
  // Verificar se há mensagens não lidas
  Future<int> getUnreadMessagesCount(String rideId) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    final String currentUserId = _auth.currentUser!.uid;
    final DatabaseReference chatRef = _getChatRef(rideId);
    
    final snapshot = await chatRef.get();
    if (snapshot.value == null) {
      return 0;
    }
    
    final Map<dynamic, dynamic> messages = snapshot.value as Map<dynamic, dynamic>;
    int unreadCount = 0;
    
    messages.forEach((key, value) {
      if (value['sender_id'] != currentUserId && value['is_read'] == false) {
        unreadCount++;
      }
    });
    
    return unreadCount;
  }
  
  // Obter informações do outro usuário (motorista ou passageiro)
  Future<Map<String, dynamic>> getOtherUserInfo(String rideId) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    final String currentUserId = _auth.currentUser!.uid;
    
    // Obter dados da corrida
    final DatabaseReference rideRef = _database.ref().child('rides').child(rideId);
    final snapshot = await rideRef.get();
    
    if (snapshot.value == null) {
      throw Exception('Corrida não encontrada');
    }
    
    final Map<dynamic, dynamic> rideData = snapshot.value as Map<dynamic, dynamic>;
    final String passengerId = rideData['passenger_id'];
    final String? driverId = rideData['driver_id'];
    
    if (driverId == null) {
      throw Exception('Motorista ainda não atribuído a esta corrida');
    }
    
    // Determinar qual ID buscar com base no usuário atual
    final String otherUserId = (currentUserId == passengerId) ? driverId : passengerId;
    
    // Buscar dados do usuário no Firestore
    final userDoc = await _firestore.collection('users').doc(otherUserId).get();
    
    if (!userDoc.exists) {
      throw Exception('Usuário não encontrado');
    }
    
    return userDoc.data() as Map<String, dynamic>;
  }
  
  // Limpar o chat após a corrida ser finalizada (opcional)
  Future<void> cleanupChat(String rideId) async {
    // Não deletamos o chat, apenas o marcamos como arquivado
    // para manter histórico para possíveis disputas
    final DatabaseReference chatRef = _getChatRef(rideId);
    await chatRef.update({'archived': true});
  }
}