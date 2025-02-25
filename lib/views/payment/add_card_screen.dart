// Arquivo: lib/views/payment/add_card_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/payment_service.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({Key? key}) : super(key: key);

  @override
  _AddCardScreenState createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final PaymentService _paymentService = PaymentService();
  
  // Controladores de texto
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  
  bool _isProcessing = false;
  PaymentMethod _cardType = PaymentMethod.credit;
  String _cardBrand = '';
  
  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
  
  // Formatador para o número do cartão
  String _formatCardNumber(String text) {
    if (text.isEmpty) return '';
    
    text = text.replaceAll(' ', ''); // Remove espaços existentes
    final chunks = <String>[];
    
    for (int i = 0; i < text.length; i += 4) {
      int end = i + 4;
      if (end > text.length) end = text.length;
      chunks.add(text.substring(i, end));
    }
    
    return chunks.join(' ');
  }
  
  // Formatador para data de expiração
  String _formatExpiryDate(String text) {
    if (text.isEmpty) return '';
    
    text = text.replaceAll('/', ''); // Remove barras existentes
    
    if (text.length > 2) {
      return '${text.substring(0, 2)}/${text.substring(2)}';
    }
    
    return text;
  }
  
  // Identificar a bandeira do cartão
  void _identifyCardBrand(String cardNumber) {
    if (cardNumber.isEmpty) {
      setState(() {
        _cardBrand = '';
      });
      return;
    }
    
    // Remover espaços
    cardNumber = cardNumber.replaceAll(' ', '');
    
    // Regras simplificadas para identificação de bandeiras
    if (cardNumber.startsWith('4')) {
      setState(() {
        _cardBrand = 'Visa';
      });
    } else if (cardNumber.startsWith('5')) {
      setState(() {
        _cardBrand = 'Mastercard';
      });
    } else if (cardNumber.startsWith('3')) {
      setState(() {
        _cardBrand = 'American Express';
      });
    } else if (cardNumber.startsWith('6')) {
      setState(() {
        _cardBrand = 'Discover';
      });
    } else {
      setState(() {
        _cardBrand = '';
      });
    }
  }

  Future<void> _saveCard() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Obter valores dos campos
      String cardNumber = _cardNumberController.text.replaceAll(' ', '');
      String cardHolder = _cardHolderController.text;
      String expiryDate = _expiryDateController.text;
      String cvv = _cvvController.text;
      
      // Separar mês e ano da data de expiração
      List<String> expiryParts = expiryDate.split('/');
      int expiryMonth = int.parse(expiryParts[0]);
      int expiryYear = int.parse('20${expiryParts[1]}'); // Assumindo formato MM/YY
      
      // Criar detalhes do cartão
      Map<String, dynamic> cardDetails = {
        'number': cardNumber,
        'holder': cardHolder,
        'expiry_month': expiryMonth,
        'expiry_year': expiryYear,
        'cvv': cvv,
        'brand': _cardBrand.isNotEmpty ? _cardBrand : 'Desconhecido',
      };
      
      // Salvar cartão
      await _paymentService.registerPaymentMethod(
        method: _cardType,
        details: cardDetails,
      );
      
      // Feedback tátil
      HapticFeedback.mediumImpact();
      
      // Mostrar feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cartão adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Voltar para a tela anterior
      Navigator.pop(context, true);
    } catch (e) {
      // Mostrar erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar cartão: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Cartão'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Card animation placeholder (in a real app, you might want to add card flip animation)
              _buildCardPreview(),
              SizedBox(height: 24),
              
              // Tipo de cartão
              _buildCardTypeSelector(),
              SizedBox(height: 16),
              
              // Número do cartão
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Número do Cartão',
                  hintText: '0000 0000 0000 0000',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _cardBrand.isNotEmpty
                      ? Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            _cardBrand,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        )
                      : null,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final formattedText = _formatCardNumber(newValue.text);
                    return TextEditingValue(
                      text: formattedText,
                      selection: TextSelection.collapsed(offset: formattedText.length),
                    );
                  }),
                ],
                onChanged: (value) {
                  _identifyCardBrand(value);
                },
                validator: (value) {
                  if (value == null || value.replaceAll(' ', '').length < 16) {
                    return 'Por favor, insira um número de cartão válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Nome do titular
              TextFormField(
                controller: _cardHolderController,
                decoration: InputDecoration(
                  labelText: 'Nome do Titular',
                  hintText: 'NOME COMO ESTÁ NO CARTÃO',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do titular';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Data de expiração e CVV
              Row(
                children: [
                  // Data de expiração
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: InputDecoration(
                        labelText: 'Validade',
                        hintText: 'MM/AA',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final formattedText = _formatExpiryDate(newValue.text);
                          return TextEditingValue(
                            text: formattedText,
                            selection: TextSelection.collapsed(offset: formattedText.length),
                          );
                        }),
                      ],
                      validator: (value) {
                        if (value == null || value.length < 5) {
                          return 'Formato inválido';
                        }
                        
                        List<String> parts = value.split('/');
                        if (parts.length != 2) {
                          return 'Formato inválido';
                        }
                        
                        int? month = int.tryParse(parts[0]);
                        int? year = int.tryParse(parts[1]);
                        
                        if (month == null || month < 1 || month > 12) {
                          return 'Mês inválido';
                        }
                        
                        if (year == null) {
                          return 'Ano inválido';
                        }
                        
                        // Verificar se o cartão não está expirado
                        final now = DateTime.now();
                        final currentYear = now.year % 100; // Últimos 2 dígitos
                        final currentMonth = now.month;
                        
                        if (year < currentYear || (year == currentYear && month < currentMonth)) {
                          return 'Cartão expirado';
                        }
                        
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  // CVV
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        prefixIcon: Icon(Icons.security),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 3) {
                          return 'CVV inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              
              // Botão de salvar
              ElevatedButton(
                onPressed: _isProcessing ? null : _saveCard,
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
                    : Text('Adicionar Cartão'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Informações de segurança
              _buildSecurityInfo(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCardTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<PaymentMethod>(
              title: Text('Crédito'),
              value: PaymentMethod.credit,
              groupValue: _cardType,
              onChanged: (value) {
                setState(() {
                  _cardType = value!;
                });
              },
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          Expanded(
            child: RadioListTile<PaymentMethod>(
              title: Text('Débito'),
              value: PaymentMethod.debit,
              groupValue: _cardType,
              onChanged: (value) {
                setState(() {
                  _cardType = value!;
                });
              },
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCardPreview() {
    // Cores baseadas no tipo de cartão
    Color cardColor = _cardType == PaymentMethod.credit
        ? Colors.blue.shade800
        : Colors.green.shade800;

    // Gradiente para um efeito mais atraente
    List<Color> gradientColors = _cardType == PaymentMethod.credit
        ? [Colors.blue.shade700, Colors.blue.shade900]
        : [Colors.green.shade700, Colors.green.shade900];

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.4),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Padrão de fundo tipo cartão
          Positioned.fill(
            child: CustomPaint(
              painter: CardPatternPainter(),
            ),
          ),
          
          // Chip do cartão
          Positioned(
            top: 80,
            left: 24,
            child: Container(
              width: 40,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [Colors.amber.shade600, Colors.amber.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          // Conteúdo do cartão
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo de cartão
                Text(
                  _cardType == PaymentMethod.credit ? 'Cartão de Crédito' : 'Cartão de Débito',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                // Número do cartão
                Text(
                  _cardNumberController.text.isEmpty
                      ? '0000 0000 0000 0000'
                      : _cardNumberController.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Courier',
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                // Data e nome do titular
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TITULAR',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _cardHolderController.text.isEmpty
                              ? 'NOME DO TITULAR'
                              : _cardHolderController.text.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VALIDADE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _expiryDateController.text.isEmpty
                              ? 'MM/AA'
                              : _expiryDateController.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Bandeira do cartão
          if (_cardBrand.isNotEmpty)
            Positioned(
              top: 24,
              right: 24,
              child: Text(
                _cardBrand,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSecurityInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Informações de Segurança',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Suas informações de cartão são criptografadas e armazenadas com segurança. Nunca compartilhamos seus dados completos do cartão.',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Este app utiliza tecnologia de criptografia de ponta a ponta para proteger suas transações.',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Painter para o padrão de fundo do cartão
class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    // Desenhar padrão circular
    for (int i = 0; i < 5; i++) {
      double circleSize = size.width * 0.4 * (1 + i * 0.5);
      canvas.drawCircle(
        Offset(size.width * 1.2, size.height * 0.5),
        circleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}