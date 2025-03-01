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
  return Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Corridas por Hora',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        // Converte o índice da hora para hora do dia
                        final hour = value.toInt();
                        return Text(
                          '$hour:00',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: 0,
                maxX: 23, // 24 horas
                minY: 0,
                maxY: stats.hourlyRides.isNotEmpty 
                    ? stats.hourlyRides.reduce((a, b) => a > b ? a : b).toDouble() + 1 
                    : 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: stats.hourlyRides.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade300,
                        Colors.blue.shade700,
                      ],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.blue.shade700,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade300.withOpacity(0.4),
                          Colors.blue.shade700.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: stats.hourlyRides.isNotEmpty 
                          ? stats.hourlyRides.reduce((a, b) => a + b) / stats.hourlyRides.length 
                          : 0,
                      color: Colors.green.withOpacity(0.6),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutQuad,
            ),
          ),
        ],
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