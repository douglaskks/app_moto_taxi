import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/services/realtime_database_service.dart';

class RideRequestScreen extends StatefulWidget {
  // Adicionando rideId como parâmetro
  final String? rideId;
  final String passengerId;
  final String passengerName;
  final double passengerRating;
  final String pickupAddress;
  final String destinationAddress;
  final double estimatedDistance;
  final double estimatedDuration;
  final double estimatedFare;
  // Adicionando distância até o passageiro
  final double distanceToPickup;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RideRequestScreen({
    Key? key,
    this.rideId, // Opcional para compatibilidade com código existente
    required this.passengerId,
    required this.passengerName,
    required this.passengerRating,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.estimatedFare,
    this.distanceToPickup = 0.0, // Valor padrão para compatibilidade
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  _RideRequestScreenState createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  Timer? _timeoutTimer;
  int _remainingTime = 30; // 15 segundos para aceitar
  
  // Adicionar serviço de banco de dados e estado de carregamento
  final RealtimeDatabaseService _databaseService = RealtimeDatabaseService();
  bool _isAccepting = false;
  
  @override
  void initState() {
    super.initState();
    
    // Configurar animações
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _animationController.forward();
    
    // Iniciar timer para expiração automática
    _timeoutTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime--;
      });
      
      if (_remainingTime <= 0) {
        _timeoutTimer?.cancel();
        widget.onReject();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }
  
  // Adicionar método para aceitar corrida com Firebase
  void _acceptRide() async {
    // Se não houver rideId, usar callback normal
    if (widget.rideId == null) {
      widget.onAccept();
      return;
    }
    
    setState(() {
      _isAccepting = true;
    });
    
    try {
      // Estimar tempo de chegada baseado na distância (5 minutos + 1 minuto para cada km)
      double estimatedArrivalTime = 5 + widget.distanceToPickup;
      
      // Aceitar corrida no Firebase
      await _databaseService.acceptRide(widget.rideId!, estimatedArrivalTime);
      
      // Chamar callback de aceite
      widget.onAccept();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao aceitar corrida: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _isAccepting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: ScaleTransition(
        scale: _scaleAnimation,
        child: Center(
          child: Container(
            margin: EdgeInsets.all(24),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Colors.orange,
                      size: 32,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Nova Solicitação de Corrida',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 32),
                
                // Informações do passageiro
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.passengerName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text(
                                widget.passengerRating.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                
                // Adicionar distância até o passageiro se for > 0
                if (widget.distanceToPickup > 0)
                  Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.near_me, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Distância até o passageiro: ${widget.distanceToPickup.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Detalhes da corrida
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Local de origem
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.my_location, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Local de embarque',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  widget.pickupAddress,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Linha pontilhada
                      Row(
                        children: [
                          SizedBox(width: 12),
                          Container(
                            height: 30,
                            width: 2,
                            child: ListView.builder(
                              itemCount: 6,
                              itemBuilder: (context, index) {
                                return Container(
                                  height: 4,
                                  width: 2,
                                  margin: EdgeInsets.symmetric(vertical: 1),
                                  color: Colors.grey,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      // Local de destino
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destino',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  widget.destinationAddress,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                
                // Informações adicionais
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoItem(
                      'Distância',
                      '${widget.estimatedDistance.toStringAsFixed(1)} km',
                      Icons.straighten,
                    ),
                    _buildInfoItem(
                      'Tempo',
                      '${widget.estimatedDuration.toInt()} min',
                      Icons.access_time,
                    ),
                    _buildInfoItem(
                      'Valor',
                      'R\$ ${widget.estimatedFare.toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                  ],
                ),
                SizedBox(height: 24),
                
                // Temporizador
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Tempo restante: $_remainingTime segundos',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                
                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAccepting 
                            ? null 
                            : () {
                          _timeoutTimer?.cancel();
                          widget.onReject();
                        },
                        child: Text(
                          'RECUSAR',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAccepting 
                            ? null 
                            : () {
                          _timeoutTimer?.cancel();
                          _acceptRide();
                        },
                        child: _isAccepting
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'ACEITAR',
                                style: TextStyle(fontSize: 16),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Mostrar ID da corrida se disponível (pode ocultar em produção)
                if (widget.rideId != null && false) // Define como true para debug
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      'ID: ${widget.rideId}',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[700], size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}