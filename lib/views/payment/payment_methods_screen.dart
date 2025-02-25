// Arquivo: lib/views/payment/payment_methods_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/payment_service.dart';
import 'add_card_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final bool selectMode;
  final Function(PaymentMethod, String)? onSelect;

  const PaymentMethodsScreen({
    Key? key, 
    this.selectMode = false,
    this.onSelect,
  }) : super(key: key);

  @override
  _PaymentMethodsScreenState createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentService _paymentService = PaymentService();
  
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }
  
  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final methods = await _paymentService.getPaymentMethods();
      setState(() {
        _paymentMethods = methods;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar métodos de pagamento: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _setDefaultMethod(String methodId) async {
    try {
      await _paymentService.setDefaultPaymentMethod(methodId);
      
      // Fornecer feedback tátil
      HapticFeedback.lightImpact();
      
      // Recarregar para refletir a mudança
      _loadPaymentMethods();
      
      _showSuccessSnackBar('Método de pagamento padrão atualizado');
    } catch (e) {
      _showErrorSnackBar('Erro ao definir método padrão: ${e.toString()}');
    }
  }
  
  Future<void> _deleteMethod(String methodId) async {
    try {
      await _paymentService.deletePaymentMethod(methodId);
      
      // Fornecer feedback tátil
      HapticFeedback.mediumImpact();
      
      // Recarregar para refletir a mudança
      _loadPaymentMethods();
      
      _showSuccessSnackBar('Método de pagamento removido');
    } catch (e) {
      _showErrorSnackBar('Erro ao remover método de pagamento: ${e.toString()}');
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
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _navigateToAddCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCardScreen(),
      ),
    );
    
    if (result == true) {
      _loadPaymentMethods();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectMode ? 'Selecionar Forma de Pagamento' : 'Formas de Pagamento'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _paymentMethods.isEmpty
              ? _buildEmptyState()
              : _buildMethodsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCard,
        child: Icon(Icons.add),
        tooltip: 'Adicionar Cartão',
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Nenhum método de pagamento cadastrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Adicione um cartão ou outra forma de pagamento',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Adicionar Método de Pagamento'),
            onPressed: _navigateToAddCard,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMethodsList() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Opção de dinheiro sempre disponível
        _buildPaymentMethodItem(
          {
            'id': 'cash',
            'method': 'cash',
            'details': {'name': 'Dinheiro'},
            'is_default': _paymentMethods.every((m) => m['is_default'] != true),
          },
          showDefaultOption: false,
        ),
        
        // Dinheiro com PIX sempre disponível
        _buildPaymentMethodItem(
          {
            'id': 'pix',
            'method': 'pix',
            'details': {'name': 'PIX'},
            'is_default': false,
          },
          showDefaultOption: true,
        ),
        
        Divider(height: 32),
        
        Text(
          'Cartões',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        
        SizedBox(height: 16),
        
        ..._paymentMethods.map((method) => _buildPaymentMethodItem(method)),
      ],
    );
  }
  
  Widget _buildPaymentMethodItem(Map<String, dynamic> method, {bool showDefaultOption = true}) {
    final String methodId = method['id'];
    final String methodType = method['method'];
    final Map<String, dynamic> details = method['details'];
    final bool isDefault = method['is_default'] ?? false;
    
    // Determinar o ícone baseado no método
    IconData methodIcon;
    Color iconColor;
    
    switch (methodType) {
      case 'credit':
        methodIcon = Icons.credit_card;
        iconColor = Colors.blue;
        break;
      case 'debit':
        methodIcon = Icons.credit_card;
        iconColor = Colors.green;
        break;
      case 'pix':
        methodIcon = Icons.qr_code;
        iconColor = Colors.purple;
        break;
      case 'wallet':
        methodIcon = Icons.account_balance_wallet;
        iconColor = Colors.orange;
        break;
      case 'cash':
      default:
        methodIcon = Icons.money;
        iconColor = Colors.green;
        break;
    }
    
    return Card(
      elevation: isDefault ? 4 : 1,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDefault 
            ? BorderSide(color: Colors.blue, width: 2) 
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.selectMode
            ? () {
                // Se estiver em modo de seleção, retorna o método escolhido
                PaymentMethod selectedMethod;
                switch (methodType) {
                  case 'credit':
                    selectedMethod = PaymentMethod.credit;
                    break;
                  case 'debit':
                    selectedMethod = PaymentMethod.debit;
                    break;
                  case 'pix':
                    selectedMethod = PaymentMethod.pix;
                    break;
                  case 'wallet':
                    selectedMethod = PaymentMethod.wallet;
                    break;
                  case 'cash':
                  default:
                    selectedMethod = PaymentMethod.cash;
                    break;
                }
                widget.onSelect?.call(selectedMethod, methodId);
                Navigator.pop(context, {'method': selectedMethod, 'id': methodId});
              }
            : null,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  methodIcon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          methodType == 'cash'
                              ? 'Dinheiro'
                              : methodType == 'pix'
                                  ? 'PIX'
                                  : details['brand'] ?? 'Cartão',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 8),
                        if (isDefault)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Padrão',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      methodType == 'cash'
                          ? 'Pagamento em dinheiro ao motorista'
                          : methodType == 'pix'
                              ? 'Pagamento instantâneo via PIX'
                              : details['number'] != null
                                  ? 'Final ${details['number'].substring(details['number'].length - 4)}'
                                  : 'Cartão',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.selectMode && methodType != 'cash' && showDefaultOption)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'default') {
                      _setDefaultMethod(methodId);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(methodId);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Definir como padrão'),
                          ],
                        ),
                      ),
                    if (methodType != 'cash' && methodType != 'pix')
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Remover', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(String methodId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover Método de Pagamento'),
        content: Text('Tem certeza que deseja remover este método de pagamento?'),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Remover', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              _deleteMethod(methodId);
            },
          ),
        ],
      ),
    );
  }
}