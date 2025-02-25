// Arquivo: lib/views/payment/payment_success_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/services/payment_service.dart';
import '../passenger/rate_driver_screen.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String rideId;
  final PaymentDetails payment;
  final String driverName;

  const PaymentSuccessScreen({
    Key? key,
    required this.rideId,
    required this.payment,
    required this.driverName,
  }) : super(key: key);

  @override
  _PaymentSuccessScreenState createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
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
    
    // Iniciar animação com pequeno delay
    Future.delayed(Duration(milliseconds: 200), () {
      _animationController.forward();
    });
    
    // Feedback tátil
    HapticFeedback.mediumImpact();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  String _getPaymentMethodName() {
    switch (widget.payment.method) {
      case PaymentMethod.credit:
        return 'Cartão de Crédito';
      case PaymentMethod.debit:
        return 'Cartão de Débito';
      case PaymentMethod.pix:
        return 'PIX';
      case PaymentMethod.wallet:
        return 'Carteira Digital';
      case PaymentMethod.cash:
      default:
        return 'Dinheiro';
    }
  }
  
  IconData _getPaymentMethodIcon() {
    switch (widget.payment.method) {
      case PaymentMethod.credit:
      case PaymentMethod.debit:
        return Icons.credit_card;
      case PaymentMethod.pix:
        return Icons.qr_code;
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet;
      case PaymentMethod.cash:
      default:
        return Icons.money;
    }
  }
  
  Color _getPaymentMethodColor() {
    switch (widget.payment.method) {
      case PaymentMethod.credit:
        return Colors.blue;
      case PaymentMethod.debit:
        return Colors.green;
      case PaymentMethod.pix:
        return Colors.purple;
      case PaymentMethod.wallet:
        return Colors.orange;
      case PaymentMethod.cash:
      default:
        return Colors.green;
    }
  }
  
  void _navigateToRating() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => RateDriverScreen(
          rideId: widget.rideId,
          driverName: widget.driverName,
          driverId: widget.payment.driverId ?? '',
        ),
      ),
    );
  }
  
  void _backToHome() {
    // Voltar para a tela inicial, removendo todas as telas anteriores da pilha
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // Formatadores
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Pagamento Concluído'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animação de sucesso
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 80,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              
              // Mensagem de sucesso
              Text(
                'Pagamento Realizado com Sucesso!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                widget.payment.method == PaymentMethod.cash
                    ? 'Lembre-se de pagar ao motorista em dinheiro.'
                    : 'Seu pagamento foi processado com sucesso.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              
              // Detalhes do pagamento
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalhes do Pagamento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow(
                      'Data',
                      widget.payment.completedAt != null
                          ? dateFormat.format(widget.payment.completedAt!)
                          : dateFormat.format(widget.payment.createdAt),
                    ),
                    _buildInfoRow(
                      'Hora',
                      widget.payment.completedAt != null
                          ? timeFormat.format(widget.payment.completedAt!)
                          : timeFormat.format(widget.payment.createdAt),
                    ),
                    _buildInfoRow(
                      'Valor',
                      'R\$ ${widget.payment.amount.toStringAsFixed(2)}',
                    ),
                    _buildInfoRow(
                      'Método',
                      _getPaymentMethodName(),
                      _getPaymentMethodIcon(),
                      _getPaymentMethodColor(),
                    ),
                    _buildInfoRow(
                      'Status',
                      widget.payment.method == PaymentMethod.cash
                          ? 'Aguardando pagamento ao motorista'
                          : 'Concluído',
                      widget.payment.method == PaymentMethod.cash
                          ? Icons.hourglass_empty
                          : Icons.check_circle,
                      widget.payment.method == PaymentMethod.cash
                          ? Colors.orange
                          : Colors.green,
                    ),
                    if (widget.payment.transactionId != null)
                      _buildInfoRow(
                        'Transação',
                        widget.payment.transactionId!,
                      ),
                  ],
                ),
              ),
              Spacer(),
              
              // Botões de ação
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _navigateToRating,
                  child: Text('Avaliar Motorista'),
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
                  onPressed: _backToHome,
                  child: Text('Voltar para Início'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, [IconData? icon, Color? iconColor]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor),
                SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}