// Arquivo: lib/views/shared/chat_icon_badge.dart

import 'package:flutter/material.dart';
import '../../core/services/chat_service.dart';

class ChatIconBadge extends StatefulWidget {
  final String rideId;
  final VoidCallback onPressed;
  final Color? color;
  final double? size;

  const ChatIconBadge({
    Key? key,
    required this.rideId,
    required this.onPressed,
    this.color,
    this.size,
  }) : super(key: key);

  @override
  _ChatIconBadgeState createState() => _ChatIconBadgeState();
}

class _ChatIconBadgeState extends State<ChatIconBadge> {
  final ChatService _chatService = ChatService();
  int _unreadCount = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }
  
  @override
  void didUpdateWidget(ChatIconBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rideId != widget.rideId) {
      _loadUnreadCount();
    }
  }
  
  Future<void> _loadUnreadCount() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final count = await _chatService.getUnreadMessagesCount(widget.rideId);
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar contagem de mensagens não lidas: $e');
      if (mounted) {
        setState(() {
          _unreadCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.chat,
            color: widget.color,
            size: widget.size,
          ),
          onPressed: () {
            widget.onPressed();
            // Resetar contador após clicar
            setState(() {
              _unreadCount = 0;
            });
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (_isLoading)
          Positioned(
            right: 0,
            top: 0,
            child: SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ),
      ],
    );
  }
}