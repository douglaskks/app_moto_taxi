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

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite seu email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite sua senha';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Entrar'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: const Text('Não tem conta? Cadastre-se'),
              ),
            ],
          ),
        ),
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
      
      // Busca do perfil do usuário
      try {
        final userModel = await _authService.getUserProfile(userCredential.user!.uid);
        // ...resto do código continua igual
      } catch (profileError) {
        // Tratamento específico para erros ao buscar o perfil
        if (!mounted) return;
        
        String mensagem = 'Erro ao buscar perfil do usuário';
        if (profileError is FirebaseException) {
          if (profileError.code == 'permission-denied') {
            mensagem = 'Você não tem permissão para acessar este perfil';
          } else if (profileError.code == 'not-found') {
            mensagem = 'Perfil não encontrado. Por favor, complete seu cadastro';
            // Aqui poderia redirecionar para tela de completar cadastro
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem)),
        );
      }
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
        SnackBar(content: Text(mensagemErro)),
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
        SnackBar(content: Text(mensagemErro)),
      );
    } on SocketException catch (_) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão. Verifique sua internet')),
      );
    } on TimeoutException catch (_) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tempo limite excedido. Tente novamente')),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Captura qualquer outro erro não previsto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: ${e.toString()}')),
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
    super.dispose();
  }
}