// Arquivo: lib/views/admin/admin_home.dart
import 'package:app_moto_taxe/controllers/bloc/auth/auth_bloc.dart';
import 'package:app_moto_taxe/controllers/bloc/auth/auth_event.dart';
import 'package:app_moto_taxe/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminHome extends StatelessWidget with AdminRouteMixin{
  const AdminHome({Key? key}) : super(key: key);

  @override
  Widget buildAdminScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MotoApp - Administrador'),
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
              'Painel do Administrador',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 24),
            _buildDashboardItem(
              context,
              icon: Icons.people,
              title: 'Usuários',
              onTap: () {
                // Navegar para gerenciamento de usuários
              },
            ),
            _buildDashboardItem(
              context,
              icon: Icons.motorcycle,
              title: 'Motoristas',
              onTap: () {
                // Navegar para gerenciamento de motoristas
              },
            ),
            _buildDashboardItem(
              context,
              icon: Icons.map,
              title: 'Corridas',
              onTap: () {
                // Navegar para visualização de corridas
              },
            ),
            _buildDashboardItem(
              context,
              icon: Icons.settings,
              title: 'Configurações',
              onTap: () {
                // Navegar para configurações do aplicativo
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 36),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}