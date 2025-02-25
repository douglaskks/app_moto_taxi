// Arquivo: lib/core/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Armazenar callbacks para diferentes tipos de notificações
  final Map<String, Function(Map<String, dynamic>)> _notificationHandlers = {};
  
  // Inicializar o serviço de notificações
  Future<void> initialize(BuildContext context) async {
    // Configurar permissões
    await _requestPermissions();
    
    // Configurar notificações locais
    await _setupLocalNotifications();
    
    // Configurar callbacks do Firebase Messaging
    _setupFirebaseMessaging(context);
    
    // Obter token FCM (Firebase Cloud Messaging)
    await getToken();
  }
  
  // Solicitar permissões para notificações
  Future<void> _requestPermissions() async {
    // Permissões para iOS
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    
    // Permissões para Android
    if (Platform.isAndroid) {
      // Para Android 13 (API level 33) ou superior
      await _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }
  
  // Configurar notificações locais
  Future<void> _setupLocalNotifications() async {
    // Inicializar configurações para Android
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Inicializar configurações para iOS
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      /*onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        // Tratar notificações locais em iOS quando o app está em primeiro plano
      },*/
    );
    
    // Inicializar plugin com as configurações
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Tratar tap na notificação
        if (response.payload != null) {
          _handlePayload(response.payload!);
        }
      },
    );
  }
  
  // Configurar Firebase Messaging
  void _setupFirebaseMessaging(BuildContext context) {
    // Tratar mensagens recebidas quando o app está em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensagem recebida em primeiro plano: ${message.notification?.title}');
      
      _showLocalNotification(
        message.notification?.title ?? 'Nova notificação',
        message.notification?.body ?? '',
        message.data,
      );
      
      // Processar dados da mensagem
      if (message.data.isNotEmpty) {
        _processNotificationData(message.data);
      }
    });
    
    // Tratar quando o app é aberto a partir de uma notificação em segundo plano/encerrado
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Aplicativo aberto a partir de notificação: ${message.notification?.title}');
      
      // Processar dados da mensagem
      if (message.data.isNotEmpty) {
        _processNotificationData(message.data);
      }
    });
    
    // Verificar se o app foi aberto a partir de uma notificação (cold start)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && message.data.isNotEmpty) {
        print('Aplicativo iniciado a partir de notificação: ${message.notification?.title}');
        
        // Processar dados da mensagem após um pequeno delay para garantir que o app está inicializado
        Future.delayed(Duration(milliseconds: 500), () {
          _processNotificationData(message.data);
        });
      }
    });
  }
  
  // Mostrar notificação local
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    // Criar detalhes para Android
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'moto_taxi_channel',
      'Notificações MotoApp',
      channelDescription: 'Canal para notificações do aplicativo de mototáxi',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
      enableVibration: true,
    );
    
    // Criar detalhes para iOS
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff',
    );
    
    // Criar detalhes gerais
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Gerar ID único para a notificação
    final int notificationId = Random().nextInt(100000);
    
    // Converter data para string JSON para usar como payload
    final String payload = data.toString();
    
    // Mostrar a notificação
    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  // Processar dados da notificação
  void _processNotificationData(Map<String, dynamic> data) {
    // Verificar se há um tipo de notificação definido
    final String notificationType = data['type'] ?? '';
    
    // Chamar o handler específico para este tipo de notificação
    if (notificationType.isNotEmpty && _notificationHandlers.containsKey(notificationType)) {
      _notificationHandlers[notificationType]!(data);
    }
  }
  
  // Tratar payload ao tocar na notificação
  // Tratar payload ao tocar na notificação
  void _handlePayload(String payload) {
    try {
      // Abordagem manual para converter a string para Map
      final Map<String, dynamic> data = {};
      
      // Remove chaves e divide por vírgulas
      final List<String> pairs = payload
        .replaceAll('{', '')
        .replaceAll('}', '')
        .split(', ');
      
      // Processa cada par chave-valor
      for (String pair in pairs) {
        final List<String> keyValue = pair.split(': ');
        if (keyValue.length == 2) {
          data[keyValue[0]] = keyValue[1];
        }
      }
      
      _processNotificationData(data);
    } catch (e) {
      print('Erro ao processar payload: $e');
    }
  }
  
  // Obter token FCM para o dispositivo atual
  Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Erro ao obter token FCM: $e');
      return null;
    }
  }
  
  // Salvar token no Firestore para o usuário atual
Future<void> saveTokenToDatabase(String userId, String token) async {
  try {
    await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({'fcm_token': token});
    
    print('Token FCM salvo para o usuário: $userId');
  } catch (e) {
    print('Erro ao salvar token FCM: $e');
    
    // Se o documento não existir ainda, tente criar em vez de atualizar
    try {
      await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({'fcm_token': token}, SetOptions(merge: true));
      
      print('Token FCM criado para o usuário: $userId');
    } catch (e) {
      print('Erro ao criar token FCM: $e');
    }
  }
}

// Remover token FCM ao fazer logout
Future<void> removeTokenFromDatabase(String userId) async {
  try {
    // Remover o token no Firestore
    await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({'fcm_token': FieldValue.delete()});
    
    print('Token FCM removido para o usuário: $userId');
    
    // Opcional: você também pode invalidar o token no FCM
    await _firebaseMessaging.deleteToken();
    
  } catch (e) {
    print('Erro ao remover token FCM: $e');
  }
}
  
  // Inscrever-se em um tópico
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }
  
  // Cancelar inscrição em um tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
  
  // Registrar um handler para um tipo específico de notificação
  void registerNotificationHandler(String type, Function(Map<String, dynamic>) handler) {
    _notificationHandlers[type] = handler;
  }
  
  // Cancelar o registro de um handler
  void unregisterNotificationHandler(String type) {
    _notificationHandlers.remove(type);
  }
  
  // Enviar notificação local (para testes ou notificações locais)
  Future<void> showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    await _showLocalNotification(title, body, data);
  }
}

// Extensão para converter List<List<String>> para Map
extension ListToMapExtension on Iterable<List<String>> {
  Map<String, String> toMap() {
    return Map.fromEntries(
      map((list) => MapEntry(list[0], list[1])),
    );
  }
}