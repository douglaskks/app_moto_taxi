// lib/views/admin/ride_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../controllers/bloc/admin/ride_details_bloc.dart';
import '../../models/admin/ride_management.dart';

class RideDetailsScreen extends StatelessWidget {
  final String rideId;
  
    const RideDetailsScreen({
    super.key,  // Mudança para usar super.key
    required this.rideId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RideDetailsBloc()..add(LoadRideDetails(rideId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes da Corrida'),
          actions: [
            BlocBuilder<RideDetailsBloc, RideDetailsState>(
              builder: (context, state) {
                if (state is RideDetailsLoaded) {
                  return IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showActionsMenu(context, state.ride);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<RideDetailsBloc, RideDetailsState>(
          builder: (context, state) {
            if (state is RideDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is RideDetailsLoaded) {
              final ride = state.ride;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(context, ride),
                    const SizedBox(height: 16),
                    _buildRouteCard(context, ride),
                    const SizedBox(height: 16),
                    _buildParticipantsCard(context, ride),
                    const SizedBox(height: 16),
                    _buildPaymentCard(context, ride),
                    const SizedBox(height: 16),
                    // Remova ou ajuste a verificação de statusHistory
                    _buildActionButtons(context, ride),
                  ],
                ),
              );
            }
            
            if (state is RideDetailsError) {
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
                        context.read<RideDetailsBloc>().add(LoadRideDetails(rideId));
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
  
  Widget _buildStatusCard(BuildContext context, RideDetailsFull ride) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (ride.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pendente';
        statusIcon = Icons.watch_later;
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusText = 'Aceita';
        statusIcon = Icons.thumb_up;
        break;
      case 'ongoing':
        statusColor = Colors.green;
        statusText = 'Em Andamento';
        statusIcon = Icons.directions_bike;
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusText = 'Concluída';
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Cancelada';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Desconhecido';
        statusIcon = Icons.help;
    }
    
    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.2),
              radius: 24,
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Corrida $statusText',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(ride.createdAt),
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'R\$ ${ride.fare.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRouteCard(BuildContext context, RideDetailsFull ride) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rota',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    Container(
                      height: 30,
                      width: 2,
                      color: Colors.grey[300],
                    ),
                    const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Origem',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        ride.pickupAddress,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Destino',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        ride.destinationAddress,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  context,
                  Icons.straighten,
                  '${ride.distance.toStringAsFixed(1)} km',
                  'Distância',
                ),
                _buildInfoItem(
                  context,
                  Icons.access_time,
                  '${ride.duration} min',
                  'Duração',
                ),
                _buildInfoItem(
                  context,
                  Icons.speed,
                  '${(ride.distance / (ride.duration / 60)).toStringAsFixed(1)} km/h',
                  'Velocidade Média',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildParticipantsCard(BuildContext context, RideDetailsFull ride) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participantes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Text(ride.passengerName),
              subtitle: const Text('Passageiro'),
              trailing: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/admin/users/details',
                    arguments: {'userId': ride.passengerId},
                  );
                },
              ),
            ),
            if (ride.driverName != null) ...[
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(
                    Icons.motorcycle,
                    color: Colors.white,
                  ),
                ),
                title: Text(ride.driverName!),
                subtitle: const Text('Motorista'),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/admin/users/details',
                      arguments: {'userId': ride.driverId},
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentCard(BuildContext context, RideDetailsFull ride) {
    if (ride.paymentInfo == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pagamento',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Informações de pagamento não disponíveis'),
              ),
            ],
          ),
        ),
      );
    }
    
    final payment = ride.paymentInfo!;
    final paymentStatusColor = payment.status == 'completed'
        ? Colors.green
        : payment.status == 'pending'
            ? Colors.orange
            : Colors.red;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagamento',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  payment.method == 'cash'
                      ? Icons.money
                      : payment.method == 'credit_card'
                          ? Icons.credit_card
                          : Icons.account_balance,
                  size: 28,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.method == 'cash'
                            ? 'Dinheiro'
                            : payment.method == 'credit_card'
                                ? 'Cartão de Crédito'
                                : 'Outro',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (payment.transactionId != null)
                        Text(
                          'Trans: ${payment.transactionId}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: paymentStatusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    payment.status == 'completed'
                        ? 'Pago'
                        : payment.status == 'pending'
                            ? 'Pendente'
                            : 'Falha',
                    style: TextStyle(
                      color: paymentStatusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Valor da corrida:'),
                Text(
                  'R\$ ${ride.fare.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Taxa da plataforma:'),
                Text(
                  'R\$ ${ride.platformFee.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ganho do motorista:'),
                Text(
                  'R\$ ${(ride.fare - ride.platformFee).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Exemplo de como usar os novos campos
Widget _buildStatusHistoryCard(BuildContext context, RideDetailsFull ride) {
  final statusHistory = ride.statusHistory;
  if (statusHistory == null || statusHistory.isEmpty) {
    return SizedBox.shrink();
  }
  
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histórico de Status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: statusHistory.length,
            itemBuilder: (context, index) {
              final status = statusHistory[index];
              return ListTile(
                title: Text(status.status),
                subtitle: Text(status.comment ?? ''),
                trailing: Text(_formatDate(status.timestamp)),
              );
            },
          ),
        ],
      ),
    ),
  );
}
  
  Widget _buildStatusHistoryItem(BuildContext context, StatusChange statusChange, bool isFirst) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    String statusText;
    Color statusColor;
    
    switch (statusChange.status) {
      case 'pending':
        statusText = 'Pendente';
        statusColor = Colors.orange;
        break;
      case 'accepted':
        statusText = 'Aceita';
        statusColor = Colors.blue;
        break;
      case 'ongoing':
        statusText = 'Em Andamento';
        statusColor = Colors.green;
        break;
      case 'completed':
        statusText = 'Concluída';
        statusColor = Colors.purple;
        break;
      case 'cancelled':
        statusText = 'Cancelada';
        statusColor = Colors.red;
        break;
      default:
        statusText = statusChange.status;
        statusColor = Colors.grey;
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isFirst ? statusColor : Colors.grey[400],
                shape: BoxShape.circle,
              ),
            ),
            if (!isFirst)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isFirst ? statusColor : Colors.black,
                    ),
                  ),
                  Text(
                    dateFormat.format(statusChange.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (statusChange.comment != null && statusChange.comment!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    statusChange.comment!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons(BuildContext context, RideDetailsFull ride) {
    if (ride.status == 'completed' || ride.status == 'cancelled') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('Gerar Relatório'),
              onPressed: () {
                // Implementar geração de relatório
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Função não implementada'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.email),
              label: const Text('Enviar Recibo'),
              onPressed: () {
                // Implementar envio de recibo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Função não implementada'),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
    
    return Row(
      children: [
        if (ride.status == 'pending' || ride.status == 'accepted') ...[
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: const Text('Cancelar Corrida', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _showCancelDialog(context);
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.message),
            label: const Text('Contatar Participantes'),
            onPressed: () {
              // Implementar contato
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Função não implementada'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancelar Corrida'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tem certeza que deseja cancelar esta corrida? Esta ação não pode ser desfeita.',
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Motivo do cancelamento',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Não'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Sim, Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
                context.read<RideDetailsBloc>().add(
                  CancelRide('Cancelado pelo administrador'),
                );
              },
            ),
          ],
        );
      },
    );
  }
  
  void _showActionsMenu(BuildContext context, RideDetailsFull ride) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Gerar Relatório'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar geração de relatório
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Enviar Recibo por Email'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar envio de recibo
                },
              ),
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Ver Rota no Mapa'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar visualização de mapa
                },
              ),
              if (ride.status != 'completed' && ride.status != 'cancelled')
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: const Text('Cancelar Corrida', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showCancelDialog(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  String _formatDate(DateTime date) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return dateFormat.format(date);
  }
}
