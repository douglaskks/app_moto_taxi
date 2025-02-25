// lib/views/admin/user_management_screen.dart
import 'package:app_moto_taxe/models/admin/user_management.dart';
import 'package:app_moto_taxe/routes.dart';
import 'package:app_moto_taxe/views/admin/user_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/bloc/admin/user_management_bloc.dart';
import '../shared/components/admin_drawer.dart';

class UserManagementScreen extends StatelessWidget with AdminRouteMixin {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget buildAdminScreen(BuildContext context) {
    return BlocProvider(
      create: (context) => UserManagementBloc()..add(LoadUsers()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciamento de Usuários'),
        ),
        drawer: const AdminDrawer(),
        body: BlocBuilder<UserManagementBloc, UserManagementState>(
          builder: (context, state) {
            if (state is UserManagementLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is UserManagementLoaded) {
              return Column(
                children: [
                  _buildFilterBar(context),
                  Expanded(
                    child: _buildUserList(context, state.users),
                  ),
                  if (state.hasMore)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<UserManagementBloc>().add(LoadMoreUsers());
                        },
                        child: const Text('Carregar mais'),
                      ),
                    ),
                ],
              );
            }
            
            if (state is UserManagementError) {
              return Center(
                child: Text(
                  'Erro ao carregar dados: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
  
  Widget _buildFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar usuários',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Implementar busca com debounce
              },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            hint: const Text('Filtrar'),
            items: const [
              DropdownMenuItem(
                value: 'all',
                child: Text('Todos'),
              ),
              DropdownMenuItem(
                value: 'driver',
                child: Text('Motoristas'),
              ),
              DropdownMenuItem(
                value: 'passenger',
                child: Text('Passageiros'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                context.read<UserManagementBloc>().add(FilterUsers(role: value));
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserList(BuildContext context, List<UserDetails> users) {
    if (users.isEmpty) {
      return const Center(child: Text('Nenhum usuário encontrado'));
    }
    
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          title: Text(user.name),
          subtitle: Text(user.email),
          leading: CircleAvatar(
            child: Icon(
              user.role == 'driver' ? Icons.motorcycle : Icons.person,
            ),
          ),
          trailing: Chip(
            label: Text(user.status),
            backgroundColor: _getStatusColor(user.status),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserDetailsScreen(userId: user.id),
              ),
            );
          },
        );
      },
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green[100]!;
      case 'suspended':
        return Colors.orange[100]!;
      case 'blocked':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}