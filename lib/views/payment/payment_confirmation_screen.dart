// Arquivo: lib/views/payment/payment_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/payment_service.dart';
import 'payment_methods_screen.dart';
import 'payment_success_screen.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final String rideId;
  final double amount;
  final String driverName;
  final String originAddress;
  final String destinationAddress;
  
  const PaymentConfirmationScreen({
    Key? key,
    required this.rideId,
    required this.amount,
    required this.driverName,
    required this.originAddress,
    required this.destinationAddress,
  }) : super(key: key);

  @override
  _PaymentConfirmationScreenState createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final PaymentService _paymentService = PaymentService();
  
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  String _selectedMethodId = 'cash';
  String _selectedMethodName = 'Dinheiro';
  bool _isProcessing = false;
  bool _hasPaymentMethods = false;
  
  @override
  void initState() {
    super.initState();
    _checkPaymentMethods();
  }
  
  Future<void> _checkPaymentMethods() async {
    try {
      bool hasMethod = await _paymentService.hasPaymentMethod();
      setState(() {
        _hasPaymentMethods = hasMethod;
      });
    } catch (e) {
      print('Erro ao verificar métodos de pagamento: $e');
    }
  }
  
  Future<void> _selectPaymentMethod() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentMethodsScreen(
            selectMode: true,
            onSelect: (method, id) {
              setState(() {
                _selectedMethod = method;
                _selectedMethodId = id;
                
                switch (method) {
                  case PaymentMethod.credit:
                    _selectedMethodName = 'Cartão de Crédito';
                    break;
                  case PaymentMethod.debit:
                    _selectedMethodName = 'Cartão de Débito';
                    break;
                  case PaymentMethod.pix:
                    _selectedMethodName = 'PIX';
                    break;
                  case PaymentMethod.wallet:
                    _selectedMethodName = 'Carteira Digital';
                    break;
                  case PaymentMethod.cash:
                  default:
                    _selectedMethodName = 'Dinheiro';
                    break;
                }
              });
            },
          ),
        ),
      );
      
      if (result is Map<String, dynamic>) {
        setState(() {
          _selectedMethod = result['method'];
          _selectedMethodId = result['id'];
          
          switch (_selectedMethod) {
            case PaymentMethod.credit:
              _selectedMethodName = 'Cartão de Crédito';
              break;
            case PaymentMethod.debit:
              _selectedMethodName = 'Cartão de Débito';
              break;
            case PaymentMethod.pix:
              _selectedMethodName = 'PIX';
              break;
            case PaymentMethod.wallet:
              _selectedMethodName = 'Carteira Digital';
              break;
            case PaymentMethod.cash:
            default:
              _selectedMethodName = 'Dinheiro';
              break;
          }
        });
      }
    } catch (e) {
      print('Erro ao selecionar método de pagamento: $e');
    }
  }
  
  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Processar o pagamento
      final payment = await _paymentService.createPayment(
        rideId: widget.rideId,
        amount: widget.amount,
        method: _selectedMethod,
      );
      
      // Feedback tátil
      HapticFeedback.mediumImpact();
      
      // Navegar para tela de sucesso
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              rideId: widget.rideId,
              payment: payment,
              driverName: widget.driverName,
            ),
          ),
        );
      }
    } catch (e) {
      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar pagamento: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 24,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmação de Pagamento'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações da corrida
              _buildRideInfoCard(),
              SizedBox(height: 24),
              
              // Resumo de valores
              Text(
                'Resumo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildPriceItem('Tarifa da corrida', widget.amount * 0.85),
              _buildPriceItem('Taxa de serviço', widget.amount * 0.15),
              Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'R\$ ${widget.amount.toStringAsFixed(2)}',
                    style: formatter,
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Método de pagamento
              Text(
                'Método de Pagamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildPaymentMethodSelector(),
              Spacer(),
              
              // Botão de confirmar pagamento
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  child: _isProcessing
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
                            Text('Processando...'),
                          ],
                        )
                      : Text('Confirmar Pagamento'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              if (_selectedMethod == PaymentMethod.cash)
                Center(
                  child: Text(
                    'Lembre-se de pagar ao motorista em dinheiro',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRideInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.emoji_people, color: Colors.blue),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Motorista',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        widget.driverName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Origem
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.circle, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Origem',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  widget.originAddress,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Linha conectora
                      Container(
                        margin: EdgeInsets.only(left: 8),
                        height: 20,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      // Destino
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destino',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  widget.destinationAddress,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceItem(String label, double value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            'R\$ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodSelector() {
    return InkWell(
      onTap: _selectPaymentMethod,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            // Ícone baseado no método de pagamento
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getPaymentMethodColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPaymentMethodIcon(),
                color: _getPaymentMethodColor(),
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Método de Pagamento',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _selectedMethodName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
  
  IconData _getPaymentMethodIcon() {
    switch (_selectedMethod) {
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
    switch (_selectedMethod) {
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
}