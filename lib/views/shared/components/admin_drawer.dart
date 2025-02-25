// lib/views/shared/components/admin_drawer.dart
import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtendo a rota atual para destacar o item selecionado
    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            route: '/admin',
            isSelected: currentRoute == '/admin',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people,
            title: 'Gerenciar Usuários',
            route: '/admin/users',
            isSelected: currentRoute.startsWith('/admin/users'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.motorcycle,
            title: 'Gerenciar Corridas',
            route: '/admin/rides',
            isSelected: currentRoute.startsWith('/admin/rides'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.attach_money,
            title: 'Relatórios Financeiros',
            route: '/admin/financial',
            isSelected: currentRoute.startsWith('/admin/financial'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Configurações',
            route: '/admin/settings',
            isSelected: currentRoute == '/admin/settings',
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.help_outline,
            title: 'Ajuda & Suporte',
            route: '/admin/help',
            isSelected: currentRoute == '/admin/help',
          ),
          const Divider(),
          _buildLogoutItem(context),
        ],
      ),
    );
  }
  
  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 30,
            child: Icon(
              Icons.admin_panel_settings,
              size: 35,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'MotoApp Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Painel Administrativo',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        // Fecha o drawer primeiro
        Navigator.pop(context);
        
        // Se já estiver na rota, não faz nada
        if (isSelected) return;
        
        // Navega para a rota selecionada
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }
  
  Widget _buildLogoutItem(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.exit_to_app,
        color: Colors.red,
      ),
      title: const Text(
        'Sair do Admin',
        style: TextStyle(
          color: Colors.red,
        ),
      ),
      onTap: () {
        // Fecha o drawer primeiro
        Navigator.pop(context);
        
        // Mostrar diálogo de confirmação
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sair do Painel Administrativo'),
            content: const Text('Tem certeza que deseja sair do painel administrativo?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Fecha o diálogo
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  Navigator.pop(context); // Fecha o diálogo
                  
                  // Retorna para a tela principal do app
                  Navigator.pushReplacementNamed(context, '/home');
                  
                  // Opcional: alternar para modo usuário se estiver usando mesmo login
                  // context.read<AuthBloc>().add(SetAdminMode(false));
                },
                child: const Text('Sair'),
              ),
            ],
          ),
        );
      },
    );
  }
}