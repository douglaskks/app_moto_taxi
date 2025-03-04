// Arquivo: lib/views/auth/login_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:app_moto_taxe/controllers/bloc/auth/auth_bloc.dart';
import 'package:app_moto_taxe/controllers/bloc/auth/auth_event.dart';
import 'package:app_moto_taxe/core/services/auth_service.dart';
import 'package:app_moto_taxe/core/services/notification_service.dart';
import 'package:app_moto_taxe/views/auth/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
void initState() {
  super.initState();
  _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  
  // Aqui está ocorrendo o erro - vamos corrigir a inicialização
  _fadeAnimation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeInOut,
  );
  
  _animationController.forward();
}

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
          
          // Overlay com círculos decorativos
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Logo ou ícone
                      Hero(
                        tag: 'app-logo',
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Icon(
                            Icons.motorcycle,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Título do app
                      Text(
                        "MotoApp",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 28 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Subtítulo
                      Text(
                        "Sua viagem rápida e segura",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Card do formulário
                      Container(
                        padding: const EdgeInsets.all(24),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 20 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Campo de email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.email, color: Colors.blue[700]),
                                  labelText: 'Email',
                                  hintText: 'exemplo@email.com',
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
                                    return 'Por favor, digite seu email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Por favor, digite um email válido';
                                  }
                                  return null;
                                },
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
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 10),
                              
                              // Link "Esqueceu a senha?"
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // Implementar recuperação de senha
                                  },
                                  child: Text(
                                    'Esqueceu a senha?',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Botão de login
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                        'ENTRAR',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Botão de registro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Não tem uma conta?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RegisterScreen()),
                              );
                            },
                            child: Text(
                              'Cadastre-se',
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
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Tentativa de login
        final userCredential = await _authService.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
        
        // ADICIONAR AQUI: Obter e salvar o token FCM
        try {
          final token = await NotificationService().getToken();
          if (token != null) {
            await NotificationService().saveTokenToDatabase(userCredential.user!.uid, token);
          }
        } catch (tokenError) {
          print('Erro ao salvar token FCM: $tokenError');
          // Não interromper o fluxo de login se falhar ao salvar o token
        }

        final userModel = await _authService.getUserProfile(userCredential.user!.uid);
        print('Login bem-sucedido: userId=${userCredential.user!.uid}, userType=${userModel.userType}');
        context.read<AuthBloc>().add(LoggedIn(userCredential.user!.uid, userModel.userType));
      } on FirebaseAuthException catch (authError) {
        if (!mounted) return;
        
        String mensagemErro;
        switch (authError.code) {
          case 'invalid-email':
            mensagemErro = 'O formato do email é inválido';
            break;
          case 'user-disabled':
            mensagemErro = 'Esta conta foi desativada';
            break;
          case 'user-not-found':
            mensagemErro = 'Nenhum usuário encontrado com este email';
            break;
          case 'wrong-password':
            mensagemErro = 'Senha incorreta';
            break;
          case 'invalid-credential':
            mensagemErro = 'As credenciais fornecidas são inválidas';
            break;
          case 'too-many-requests':
            mensagemErro = 'Muitas tentativas de login. Tente novamente mais tarde';
            break;
          case 'network-request-failed':
            mensagemErro = 'Erro de conexão. Verifique sua internet';
            break;
          case 'account-exists-with-different-credential':
            mensagemErro = 'Esta conta já existe com outro método de login';
            break;
          case 'operation-not-allowed':
            mensagemErro = 'Este método de login não está habilitado';
            break;
          default:
            mensagemErro = 'Erro ao fazer login: ${authError.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemErro),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } on FirebaseException catch (firebaseError) {
        if (!mounted) return;
        
        String mensagemErro;
        switch (firebaseError.code) {
          case 'permission-denied':
            mensagemErro = 'Permissão negada para esta operação';
            break;
          case 'unavailable':
            mensagemErro = 'Serviço temporariamente indisponível. Tente novamente mais tarde';
            break;
          default:
            mensagemErro = 'Erro do Firebase: ${firebaseError.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemErro),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } on SocketException catch (_) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão. Verifique sua internet'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } on TimeoutException catch (_) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tempo limite excedido. Tente novamente'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        
        // Captura qualquer outro erro não previsto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: ${e.toString()}'),
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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}