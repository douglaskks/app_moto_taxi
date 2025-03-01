// Arquivo: lib/views/ride_rating_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class RideRatingScreen extends StatefulWidget {
  final String rideId;
  final String userId;          // ID do usuário sendo avaliado (motorista ou passageiro)
  final String evaluatorId;     // ID do usuário fazendo a avaliação
  final String userName;        // Nome do usuário sendo avaliado
  final String? userPhoto;      // Foto do usuário sendo avaliado
  final bool isDriverRating;    // true: motorista avaliando passageiro, false: passageiro avaliando motorista

  const RideRatingScreen({
    Key? key,
    required this.rideId,
    required this.userId,
    required this.evaluatorId,
    required this.userName,
    this.userPhoto,
    required this.isDriverRating,
  }) : super(key: key);

  @override
  _RideRatingScreenState createState() => _RideRatingScreenState();
}

class _RideRatingScreenState extends State<RideRatingScreen> {
  double _rating = 5;
  String _comment = '';
  bool _isSubmitting = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Determinar qual campo atualizar com base em quem está avaliando
      final String ratingField = widget.isDriverRating ? 'passenger_rating' : 'driver_rating';
      final String commentField = widget.isDriverRating ? 'passenger_comment' : 'driver_comment';

      // 1. Atualizar no Realtime Database
      await FirebaseDatabase.instance
          .ref()
          .child('rides/${widget.rideId}')
          .update({
        ratingField: _rating,
        commentField: _comment,
        '${ratingField}_at': ServerValue.timestamp,
      });

      // 2. Atualizar no Firestore
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .update({
        ratingField: _rating,
        commentField: _comment,
        '${ratingField}_at': FieldValue.serverTimestamp(),
      });

      // 3. Atualizar contadores de avaliação do usuário (opcional)
      await _updateUserRatingStats();

      // 4. Exibir mensagem de sucesso e fechar tela
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avaliação enviada com sucesso!')),
        );

        // Fechar a tela após um breve delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop(true); // Retorna true indicando que a avaliação foi enviada
          }
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar avaliação: $e')),
        );
      }
    }
  }
  
  // Atualizar estatísticas de avaliação do usuário
  Future<void> _updateUserRatingStats() async {
    try {
      // Determinar coleção correta com base em quem está sendo avaliado
      final String collection = widget.isDriverRating ? 'users' : 'users';
      
      // Obter documento atual do usuário
      final userDoc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(widget.userId)
          .get();
      
      if (!userDoc.exists) return;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Calcular nova média de avaliações
      int totalRatings = userData['total_ratings'] ?? 0;
      double avgRating = userData['avg_rating'] ?? 5.0;
      
      // Calcular nova média: ((média atual * total) + nova avaliação) / (total + 1)
      double newAvgRating = ((avgRating * totalRatings) + _rating) / (totalRatings + 1);
      
      // Atualizar documento do usuário
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(widget.userId)
          .update({
        'total_ratings': FieldValue.increment(1),
        'avg_rating': newAvgRating,
      });
    } catch (e) {
      print('Erro ao atualizar estatísticas de avaliação: $e');
      // Não interromper o fluxo principal se isso falhar
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.isDriverRating ? 'Avaliar Passageiro' : 'Avaliar Motorista';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Foto e nome do usuário
            CircleAvatar(
              radius: 50,
              backgroundImage: widget.userPhoto != null
                  ? NetworkImage(widget.userPhoto!)
                  : null,
              child: widget.userPhoto == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            // Texto explicativo
            Text(
              'Como foi sua experiência com ${widget.isDriverRating ? "este passageiro" : "este motorista"}?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Estrelas para avaliação
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  iconSize: 40,
                  color: index < _rating ? Colors.amber : Colors.grey[300],
                  icon: const Icon(Icons.star),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _getRatingText(),
              style: TextStyle(
                fontSize: 16,
                color: _getRatingColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            // Campo de comentário
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Comentário (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              maxLines: 4,
              onChanged: (value) {
                setState(() {
                  _comment = value;
                });
              },
            ),
            const SizedBox(height: 32),
            
            // Botão de enviar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ENVIAR AVALIAÇÃO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText() {
    if (_rating >= 5) return 'Excelente!';
    if (_rating >= 4) return 'Muito bom!';
    if (_rating >= 3) return 'Bom';
    if (_rating >= 2) return 'Regular';
    return 'Ruim';
  }

  Color _getRatingColor() {
    if (_rating >= 4) return Colors.green;
    if (_rating >= 3) return Colors.amber.shade700;
    if (_rating >= 2) return Colors.orange;
    return Colors.red;
  }
}