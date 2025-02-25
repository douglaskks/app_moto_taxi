// Arquivo: lib/views/passenger/passenger_home.dart
import 'package:app_moto_taxe/controllers/bloc/auth/auth_bloc.dart';
import 'package:app_moto_taxe/controllers/bloc/auth/auth_event.dart';
import 'package:app_moto_taxe/views/passenger/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PassengerHome extends StatelessWidget {
  const PassengerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MotoApp - Passageiro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LoggedOut());
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bem-vindo, Passageiro!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navegar para a tela de solicitar corrida
                Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen(),));
              },
              child: const Text('Solicitar Corrida'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                // Alternar para perfil de motorista se o usuário tiver ambos os perfis
                context.read<AuthBloc>().add(const SwitchUserType('driver'));
              },
              child: const Text('Mudar para Motorista'),
            ),
          ],
        ),
      ),
    );
  }
}