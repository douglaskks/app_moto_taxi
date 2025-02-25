// lib/views/admin/admin_dashboard.dart
import 'package:app_moto_taxe/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/bloc/admin/admin_dashboard_bloc.dart';
import '../../models/admin/dashboard_stats.dart';
import 'package:fl_chart/fl_chart.dart';
import '../shared/components/admin_drawer.dart';
import '../shared/components/stats_card.dart';

class AdminDashboardScreen extends StatelessWidget with AdminRouteMixin {
  const AdminDashboardScreen({super.key});

  @override
  Widget buildAdminScreen(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminDashboardBloc()..add(LoadDashboardStats()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel Administrativo'),
        ),
        drawer: const AdminDrawer(),
        body: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
          builder: (context, state) {
            if (state is AdminDashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is AdminDashboardLoaded) {
              final stats = state.stats;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visão Geral',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildOverviewCards(stats),
                    const SizedBox(height: 24),
                    Text(
                      'Atividade Recente',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildActivityCharts(stats),
                    const SizedBox(height: 24),
                    Text(
                      'Corridas Ativas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildActiveRidesList(stats.activeRides),
                  ],
                ),
              );
            }
            
            if (state is AdminDashboardError) {
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
  
  Widget _buildOverviewCards(DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatsCard(
          title: 'Usuários Ativos',
          value: stats.activeUsers.toString(),
          icon: Icons.people,
          color: Colors.blue,
        ),
        StatsCard(
          title: 'Motoristas Online',
          value: stats.onlineDrivers.toString(),
          icon: Icons.motorcycle,
          color: Colors.green,
        ),
        StatsCard(
          title: 'Corridas Hoje',
          value: stats.ridesCount.toString(),
          icon: Icons.directions,
          color: Colors.orange,
        ),
        StatsCard(
          title: 'Faturamento do Dia',
          value: 'R\$ ${stats.dailyRevenue.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.purple,
        ),
      ],
    );
  }
  
  Widget _buildActivityCharts(DashboardStats stats) {
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: stats.hourlyRides.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.toDouble());
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              dotData: const FlDotData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 4 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${value.toInt()}h',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }
  
  Widget _buildActiveRidesList(List<ActiveRide> rides) {
    if (rides.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Não há corridas ativas no momento.'),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text('${ride.passengerName} → ${ride.destinationAddress}'),
            subtitle: Text('Motorista: ${ride.driverName}'),
            trailing: Text('R\$ ${ride.fare.toStringAsFixed(2)}'),
            leading: const CircleAvatar(
              child: Icon(Icons.motorcycle),
            ),
            onTap: () {
              // Navegar para detalhes da corrida
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
}