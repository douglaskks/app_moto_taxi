// Arquivo: lib/views/chat/chat_screen.dart

import 'dart:async';

import 'package:app_moto_taxe/views/passenger/map_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../core/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;
  final String otherUserName;
  final String? otherUserImage;

  const ChatScreen({
    Key? key,
    required this.rideId,
    required this.otherUserName,
    this.otherUserImage,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  
  StreamSubscription? _messagesSubscription;
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
    
    // Marcar mensagens como lidas quando a tela é aberta
    _chatService.markAllMessagesAsRead(widget.rideId);
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }
  
  void _loadMessages() {
    _messagesSubscription = _chatService.getMessages(widget.rideId).listen(
      (messages) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        
        // Rolar para o final da lista quando novas mensagens chegarem
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
        
        // Marcar mensagens como lidas
        _markNewMessagesAsRead();
      },
      onError: (error) {
        print('Erro ao carregar mensagens: $error');
        setState(() {
          _isLoading = false;
        });
      },
    );
  }
  
  void _markNewMessagesAsRead() {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    
    for (var message in _messages) {
      if (message.senderId != currentUserId && !message.isRead) {
        _chatService.markMessageAsRead(widget.rideId, message.id);
      }
    }
  }
  
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      await _chatService.sendTextMessage(widget.rideId, text);
      _messageController.clear();
      
      // Adicionar vibração de feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Erro ao enviar mensagem: ${e.toString()}');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
  
  Future<void> _sendImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (pickedFile == null) return;
      
      setState(() {
        _isSending = true;
      });
      
      // Upload da imagem para o Firebase Storage
      final File imageFile = File(pickedFile.path);
      final String fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(widget.rideId)
          .child(fileName);
      
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Enviar URL da imagem para o chat
      await _chatService.sendImage(widget.rideId, downloadUrl);
      
      // Adicionar vibração de feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Erro ao enviar imagem: ${e.toString()}');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
  
  Future<void> _sendLocation() async {
    try {
      setState(() {
        _isSending = true;
      });
      
      // Verificar permissão de localização
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Permissão de localização negada');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar(
          'Permissões de localização negadas permanentemente, não é possível compartilhar localização'
        );
        return;
      }
      
      // Obter localização atual
      final Position position = await Geolocator.getCurrentPosition();
      
      // Enviar localização para o chat
      await _chatService.sendLocation(
        widget.rideId, 
        position.latitude, 
        position.longitude
      );
      
      // Adicionar vibração de feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Erro ao compartilhar localização: ${e.toString()}');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _viewLocation(String locationUrl) {
    try {
      final coordinates = locationUrl.split(',');
      if (coordinates.length != 2) return;
      
      final double latitude = double.parse(coordinates[0]);
      final double longitude = double.parse(coordinates[1]);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapViewScreen(
            latitude: latitude,
            longitude: longitude,
            title: 'Localização Compartilhada',
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Erro ao abrir localização: ${e.toString()}');
    }
  }
  
  void _viewImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Imagem'),
            backgroundColor: Colors.black,
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(
                  imageUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUserImage != null
                  ? NetworkImage(widget.otherUserImage!)
                  : null,
              child: widget.otherUserImage == null
                  ? Icon(Icons.person)
                  : null,
              radius: 16,
            ),
            SizedBox(width: 8),
            Text(widget.otherUserName),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone),
            onPressed: () {
              // Implementar chamada telefônica
              _showErrorSnackBar('Função de chamada não implementada');
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Nenhuma mensagem ainda',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Envie uma mensagem para iniciar a conversa',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final bool isMe = message.senderId == currentUserId;
                            
                            return _buildMessageItem(message, isMe);
                          },
                        ),
                ),
                _buildInputArea(),
              ],
            ),
    );
  }
  
  Widget _buildMessageItem(ChatMessage message, bool isMe) {
    final dateFormat = DateFormat('HH:mm');
    final timeString = dateFormat.format(message.timestamp);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar imagem se houver
            if (message.imageUrl != null)
              GestureDetector(
                onTap: () => _viewImage(message.imageUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    message.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            // Mostrar localização se houver
            if (message.locationUrl != null)
              GestureDetector(
                onTap: () => _viewLocation(message.locationUrl!),
                child: Container(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Ver localização',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Texto da mensagem
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.text.isNotEmpty && 
                      (message.imageUrl != null || message.locationUrl != null))
                    Text(message.text),
                  if (message.text.isNotEmpty && 
                      message.imageUrl == null && message.locationUrl == null)
                    Text(message.text),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead ? Colors.blue : Colors.grey[600],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.photo),
            onPressed: _isSending ? null : _sendImage,
            color: Colors.blue,
          ),
          IconButton(
            icon: Icon(Icons.location_on),
            onPressed: _isSending ? null : _sendLocation,
            color: Colors.blue,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Digite uma mensagem...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          _isSending
              ? SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Colors.blue,
                ),
        ],
      ),
    );
  }
}