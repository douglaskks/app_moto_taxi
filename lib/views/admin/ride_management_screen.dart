// lib/views/admin/ride_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../controllers/bloc/admin/ride_management_bloc.dart';
import '../../models/admin/ride_management.dart';
import '../shared/components/admin_drawer.dart';

class RideManagementScreen extends StatelessWidget {
  const RideManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RideManagementBloc()..add(LoadRides()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciamento de Corridas'),
        ),
        drawer: const AdminDrawer(),
        body: BlocBuilder<RideManagementBloc, RideManagementState>(
          builder: (context, state) {
            if (state is RideManagementLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is RideManagementLoaded) {
              return Column(
                children: [
                  _buildFilterBar(context, state),
                  Expanded(
                    child: _buildRidesList(context, state.rides),
                  ),
                  if (state.hasMore)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<RideManagementBloc>().add(LoadMoreRides());
                        },
                        child: const Text('Carregar mais'),
                      ),
                    ),
                ],
              );
            }
            
            if (state is RideManagementError) {
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
  
  Widget _buildFilterBar(BuildContext context, RideManagementLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar corridas',
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
                    hint: const Text('Status'),
                    value: state.statusFilter,
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('Todos'),
                      ),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pendente'),
                      ),
                      DropdownMenuItem(
                        value: 'ongoing',
                        child: Text('Em Andamento'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Concluída'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Cancelada'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        context.read<RideManagementBloc>().add(FilterRides(status: value));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildDateRangeButton(context, state),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar'),
                    onPressed: () {
                      context.read<RideManagementBloc>().add(LoadRides());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDateRangeButton(BuildContext context, RideManagementLoaded state) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startDate = state.startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final endDate = state.endDate ?? DateTime.now();
    
    return Expanded(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.date_range),
        label: Text(
          'Período: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
          style: const TextStyle(fontSize: 12),
        ),
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDateRange: DateTimeRange(
              start: startDate,
              end: endDate,
            ),
          );
          
          if (picked != null) {
            context.read<RideManagementBloc>().add(
              FilterRides(
                startDate: picked.start,
                endDate: picked.end,
                status: state.statusFilter,
              ),
            );
          }
        },
      ),
    );
  }
  
  Widget _buildRidesList(BuildContext context, List<RideDetails> rides) {
    if (rides.isEmpty) {
      return const Center(
        child: Text('Nenhuma corrida encontrada com os filtros atuais'),
      );
    }
    
    return ListView.builder(
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text('${ride.passengerName} → ${_formatAddress(ride.destinationAddress)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Motorista: ${ride.driverName ?? 'Não atribuído'}'),
                Text('Data: ${_formatDate(ride.createdAt)}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${ride.fare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusChip(ride.status),
              ],
            ),
            leading: _buildStatusIcon(ride.status),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/admin/rides/details',
                arguments: {'rideId': ride.id},
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pendente';
        break;
      case 'accepted':
        color = Colors.blue;
        label = 'Aceita';
        break;
      case 'ongoing':
        color = Colors.green;
        label = 'Em Andamento';
        break;
      case 'completed':
        color = Colors.purple;
        label = 'Concluída';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelada';
        break;
      default:
        color = Colors.grey;
        label = 'Desconhecido';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case 'pending':
        icon = Icons.watch_later;
        color = Colors.orange;
        break;
      case 'accepted':
        icon = Icons.thumb_up;
        color = Colors.blue;
        break;
      case 'ongoing':
        icon = Icons.directions_bike;
        color = Colors.green;
        break;
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.purple;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }
    
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color),
    );
  }
  
  String _formatAddress(String address) {
    if (address.length > 25) {
      return '${address.substring(0, 22)}...';
    }
    return address;
  }
  
  String _formatDate(DateTime date) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return dateFormat.format(date);
  }
}