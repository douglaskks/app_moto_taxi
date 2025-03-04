// Arquivo: lib/views/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/bloc/auth/auth_bloc.dart';
import '../../controllers/bloc/auth/auth_event.dart';
import '../../core/services/auth_service.dart';
import '../../models/user_models.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _selectedUserType = 'passenger'; // Default: passageiro
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
    return Scaffold(
      body: Stack(
        children: [
          // Fundo com gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue[700]!, Colors.blue[900]!],
              ),
            ),
          ),
          
          // Círculos decorativos
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -50,
            child: Container(
              height: 350,
              width: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          
          // Conteúdo principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Barra superior
                  Row(
                    children: [
                      // Botão de voltar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Criar Conta",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  // Formulário rolável
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Card do formulário
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Informações Pessoais",
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Campo de nome
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Nome completo',
                                      hint: 'Digite seu nome completo',
                                      icon: Icons.person,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor, digite seu nome';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Campo de email
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      hint: 'exemplo@email.com',
                                      icon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor, digite seu email';
                                        }
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                          return 'Por favor, digite um email válido';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Campo de telefone
                                    _buildTextField(
                                      controller: _phoneController,
                                      label: 'Telefone',
                                      hint: '(XX) XXXXX-XXXX',
                                      icon: Icons.phone,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(11),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor, digite seu telefone';
                                        }
                                        if (value.length < 10) {
                                          return 'Telefone inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Card da senha
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Senha de Acesso",
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Campo de senha
                                    TextFormField(
                                      controller: _passwordController,
                                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(Icons.lock, color: Colors.blue[700]),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                            color: Colors.grey[600],
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                        labelText: 'Senha',
                                        hintText: '********',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.blue[200]!),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.blue[200]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.red, width: 1),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 16,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor, digite sua senha';
                                        }
                                        if (value.length < 6) {
                                          return 'A senha deve ter pelo menos 6 caracteres';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Campo de confirmação de senha
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                      obscureText: _obscureConfirmPassword,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(Icons.lock_outline, color: Colors.blue[700]),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                            color: Colors.grey[600],
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword = !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                        labelText: 'Confirmar senha',
                                        hintText: '********',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.blue[200]!),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.blue[200]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.red, width: 1),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 16,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor, confirme sua senha';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'As senhas não coincidem';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Card do tipo de usuário
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Tipo de Conta",
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildUserTypeCard(
                                            title: 'Passageiro',
                                            description: 'Solicitar corridas',
                                            iconData: Icons.emoji_people,
                                            isSelected: _selectedUserType == 'passenger',
                                            onTap: () {
                                              setState(() {
                                                _selectedUserType = 'passenger';
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildUserTypeCard(
                                            title: 'Motorista',
                                            description: 'Oferecer corridas',
                                            iconData: Icons.motorcycle,
                                            isSelected: _selectedUserType == 'driver',
                                            onTap: () {
                                              setState(() {
                                                _selectedUserType = 'driver';
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 30),
                              
                              // Botão de cadastro
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: _isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'CRIAR CONTA',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Link para tela de login
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Já tem uma conta?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'Faça login',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 14 : 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget para campos de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      validator: validator,
    );
  }
  
  // Widget para os cards de tipo de usuário
  Widget _buildUserTypeCard({
    required String title,
    required String description,
    required IconData iconData,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.grey[100],
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              iconData,
              size: 40,
              color: isSelected ? Colors.blue[700] : Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected ? Colors.blue[700] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue[700] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Registrar usuário no Firebase Auth
        final userCredential = await _authService.signUpWithEmail(
          _emailController.text,
          _passwordController.text,
        );
        
        // Criar modelo de usuário
        final user = UserModel(
          id: userCredential.user!.uid,
          name: _nameController.text,
          email: _emailController.text,
          userType: _selectedUserType,
          phoneNumber: _phoneController.text,
          profileImage: null,
          createdAt: DateTime.now(),
        );
        
        // Salvar perfil do usuário no Firestore
        await _authService.createUserProfile(user);
        
        // Se for motorista, redirecionar para tela de verificação de documentos
        if (_selectedUserType == 'driver' && mounted) {
          // Aqui você pode navegar para uma tela de verificação de documentos
          // Por enquanto, apenas mostraremos uma mensagem
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Como motorista, você precisará verificar seus documentos'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        
        if (!mounted) return;
        
        // Notificar o AuthBloc que o usuário está logado
        context.read<AuthBloc>().add(LoggedIn(userCredential.user!.uid, _selectedUserType));
        
        // Mostrar snackbar de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Retornar para a tela de login (o AuthBloc cuidará da navegação para a home correta)
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar conta: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}