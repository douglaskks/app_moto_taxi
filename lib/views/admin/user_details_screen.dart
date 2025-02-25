// lib/views/admin/user_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../controllers/bloc/admin/user_details_bloc.dart';
import '../../models/admin/user_management.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userId;
  
  const UserDetailsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserDetailsBloc()..add(LoadUserDetails(userId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes do Usuário'),
        ),
        body: BlocBuilder<UserDetailsBloc, UserDetailsState>(
          builder: (context, state) {
            if (state is UserDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is UserDetailsLoaded) {
              final user = state.user;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserHeader(context, user),
                    const SizedBox(height: 24),
                    _buildStatusSection(context, user),
                    const SizedBox(height: 24),
                    if (user.stats != null) _buildStatsSection(context, user.stats!),
                    const SizedBox(height: 24),
                    if (user.profile != null) _buildProfileSection(context, user.profile!),
                    const SizedBox(height: 24),
                    _buildActionButtons(context, user),
                  ],
                ),
              );
            }
            
            if (state is UserDetailsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar dados: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<UserDetailsBloc>().add(LoadUserDetails(userId));
                      },
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
  
  Widget _buildUserHeader(BuildContext context, UserDetails user) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              backgroundImage: user.profile?.profilePicUrl != null
                  ? NetworkImage(user.profile!.profilePicUrl!)
                  : null,
              child: user.profile?.profilePicUrl == null
                  ? Icon(
                      user.role == 'driver' ? Icons.motorcycle : Icons.person,
                      size: 40,
                      color: Colors.grey[600],
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          user.role == 'driver' ? 'Motorista' : 'Passageiro',
                        ),
                        backgroundColor: user.role == 'driver'
                            ? Colors.blue[100]
                            : Colors.purple[100],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Desde ${dateFormat.format(user.registrationDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusSection(BuildContext context, UserDetails user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Status do Usuário',
                border: OutlineInputBorder(),
              ),
              value: user.status,
              items: const [
                DropdownMenuItem(
                  value: 'active',
                  child: Text('Ativo'),
                ),
                DropdownMenuItem(
                  value: 'suspended',
                  child: Text('Suspenso'),
                ),
                DropdownMenuItem(
                  value: 'blocked',
                  child: Text('Bloqueado'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  context.read<UserDetailsBloc>().add(UpdateUserStatus(value));
                }
              },
            ),
            if (user.status == 'suspended' || user.status == 'blocked')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: user.status == 'suspended'
                        ? Colors.orange[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: user.status == 'suspended'
                            ? Colors.orange
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.status == 'suspended'
                              ? 'Este usuário está temporariamente suspenso. Ele não poderá usar o aplicativo até que seja reativado.'
                              : 'Este usuário está bloqueado. Ele não poderá usar o aplicativo até que seja desbloqueado.',
                          style: TextStyle(
                            color: user.status == 'suspended'
                                ? Colors.orange[800]
                                : Colors.red[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsSection(BuildContext context, UserStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estatísticas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  context,
                  'Total de Corridas',
                  stats.totalRides.toString(),
                  Icons.directions_car,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Avaliação Média',
                  '${stats.averageRating.toStringAsFixed(1)}★',
                  Icons.star,
                  Colors.amber,
                ),
                _buildStatCard(
                  context,
                  stats.totalEarned > 0 ? 'Total Ganho' : 'Total Gasto',
                  'R\$ ${(stats.totalEarned > 0 ? stats.totalEarned : stats.totalSpent).toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Corridas Canceladas',
                  stats.cancelledRides.toString(),
                  Icons.cancel,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileSection(BuildContext context, UserProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações de Perfil',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (profile.phoneNumber != null)
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Telefone'),
                subtitle: Text(profile.phoneNumber!),
              ),
            if (profile.address != null)
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Endereço'),
                subtitle: Text(profile.address!),
              ),
            if (profile.driverInfo != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Informações do Motorista',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.directions_car),
                title: const Text('Veículo'),
                subtitle: Text('${profile.driverInfo!.vehicleModel} (${profile.driverInfo!.vehicleColor})'),
              ),
              ListTile(
                leading: const Icon(Icons.confirmation_number),
                title: const Text('Placa'),
                subtitle: Text(profile.driverInfo!.licensePlate),
              ),
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('CNH'),
                subtitle: Text(profile.driverInfo!.driverLicense),
              ),
              ListTile(
                leading: const Icon(Icons.verified),
                title: const Text('Documentos Verificados'),
                subtitle: Text(profile.driverInfo!.documentsVerified ? 'Sim' : 'Não'),
                trailing: Icon(
                  profile.driverInfo!.documentsVerified
                      ? Icons.check_circle
                      : Icons.pending,
                  color: profile.driverInfo!.documentsVerified
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, UserDetails user) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.message),
            label: const Text('Enviar Mensagem'),
            onPressed: () {
              // Implementar envio de mensagem
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Função de mensagem não implementada'),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.history),
            label: const Text('Ver Histórico'),
            onPressed: () {
              // Navegar para histórico de corridas
              Navigator.pushNamed(
                context,
                '/admin/user-rides',
                arguments: {'userId': user.id},
              );
            },
          ),
        ),
      ],
    );
  }
}