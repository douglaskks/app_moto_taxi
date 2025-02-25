// Arquivo: lib/views/passenger/rate_driver_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateDriverScreen extends StatefulWidget {
  final String rideId;
  final String driverName;
  final String driverId;

  const RateDriverScreen({
    Key? key,
    required this.rideId,
    required this.driverName,
    required this.driverId,
  }) : super(key: key);

  @override
  _RateDriverScreenState createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> with SingleTickerProviderStateMixin {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _showSuccessAnimation = false;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  // Critérios de avaliação
  final Map<String, int> _criteria = {
    'Limpeza do veículo': 5,
    'Direção segura': 5,
    'Cordialidade': 5,
  };
  
  @override
  void initState() {
    super.initState();
    
    // Configurar animações
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, selecione uma avaliação.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseAuth auth = FirebaseAuth.instance;
      
      if (auth.currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      final String userId = auth.currentUser!.uid;
      
      // Salvar avaliação
      await firestore.collection('ratings').add({
        'ride_id': widget.rideId,
        'driver_id': widget.driverId,
        'passenger_id': userId,
        'rating': _rating,
        'criteria': _criteria,
        'comment': _commentController.text,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      // Atualizar status da corrida
      await firestore.collection('rides').doc(widget.rideId).update({
        'rated': true,
        'rating': _rating,
      });
      
      // Atualizar avaliação média do motorista
      // Primeiro, obter todas as avaliações do motorista
      final ratingsSnapshot = await firestore
          .collection('ratings')
          .where('driver_id', isEqualTo: widget.driverId)
          .get();
      
      // Calcular média
      double totalRating = 0;
      int count = 0;
      
      for (var doc in ratingsSnapshot.docs) {
        totalRating += doc.data()['rating'] as int;
        count++;
      }
      
      double averageRating = count > 0 ? totalRating / count : 0;
      
      // Atualizar perfil do motorista
      await firestore.collection('users').doc(widget.driverId).update({
        'rating': averageRating,
        'total_ratings': count,
      });
      
      // Feedback tátil
      HapticFeedback.mediumImpact();
      
      // Mostrar animação de sucesso
      setState(() {
        _isSubmitting = false;
        _showSuccessAnimation = true;
      });
      
      _animationController.forward();
      
      // Voltar após alguns segundos
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar avaliação: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avaliar Motorista'),
        automaticallyImplyLeading: false,
      ),
      body: _showSuccessAnimation
          ? _buildSuccessAnimation()
          : _buildRatingForm(),
    );
  }
  
  Widget _buildSuccessAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 100,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 24),
          Text(
            'Avaliação Enviada!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Obrigado pelo seu feedback.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRatingForm() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com foto do motorista
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Como foi sua viagem com',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    widget.driverName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Avaliação por estrelas
            Text(
              'Avaliação Geral',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                      // Feedback tátil
                      HapticFeedback.lightImpact();
                    },
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                _getRatingLabel(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getRatingColor(),
                ),
              ),
            ),
            SizedBox(height: 32),
            
            // Critérios específicos
            Text(
              'Critérios Específicos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ..._criteria.entries.map((entry) {
              return _buildCriterionRating(entry.key, entry.value);
            }),
            SizedBox(height: 32),
            
            // Comentário
            Text(
              'Deixe um comentário (opcional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'O que você gostou? O que poderia melhorar?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            SizedBox(height: 24),
            
            // Botão de enviar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text('Enviando...'),
                        ],
                      )
                    : Text('Enviar Avaliação'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text('Pular'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCriterionRating(String name, int value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _criteria[name] = index + 1;
                    });
                    // Recalcular média
                    _recalculateOverallRating();
                    // Feedback tátil
                    HapticFeedback.lightImpact();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      index < value ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 24,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
  
  void _recalculateOverallRating() {
    // Calcular média dos critérios
    int total = 0;
    _criteria.forEach((key, value) {
      total += value;
    });
    
    int newRating = (total / _criteria.length).round();
    
    setState(() {
      _rating = newRating;
    });
  }
  
  String _getRatingLabel() {
    if (_rating >= 5) {
      return 'Excelente!';
    } else if (_rating >= 4) {
      return 'Muito bom!';
    } else if (_rating >= 3) {
      return 'Bom';
    } else if (_rating >= 2) {
      return 'Regular';
    } else {
      return 'Ruim';
    }
  }
  
  Color _getRatingColor() {
    if (_rating >= 5) {
      return Colors.green;
    } else if (_rating >= 4) {
      return Colors.lightGreen;
    } else if (_rating >= 3) {
      return Colors.amber;
    } else if (_rating >= 2) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}