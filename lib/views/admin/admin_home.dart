import 'package:app_moto_taxe/controllers/bloc/auth/auth_bloc.dart';
import 'package:app_moto_taxe/controllers/bloc/auth/auth_event.dart';
import 'package:app_moto_taxe/controllers/bloc/auth/auth_state.dart';
import 'package:app_moto_taxe/core/services/admin/admin_dashboard_service.dart';
import 'package:app_moto_taxe/routes.dart';
import 'package:app_moto_taxe/views/admin/driver_management_screen.dart';
import 'package:app_moto_taxe/views/admin/ride_management_screen.dart';
import 'package:app_moto_taxe/views/admin/settings_screen.dart';
import 'package:app_moto_taxe/views/admin/user_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// Removemos o mixin da declaração da classe
class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);
  
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  final AdminDashboardService _dashboardService = AdminDashboardService();
  
  // Dados do dashboard
  int _totalUsers = 0;
  int _totalDrivers = 0;
  int _totalRides = 0;
  double _totalRevenue = 0;
  List<Map<String, dynamic>> _recentRides = [];
  Map<String, double> _weeklyRides = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Verificar permissão de admin antes de carregar dados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAccess();
    });
  }
  
  // Método para verificar se é admin (substituindo a funcionalidade do mixin)
  void _checkAdminAccess() {
    final authBloc = context.read<AuthBloc>();
    final isAdmin = authBloc.state is Authenticated &&
        (authBloc.state as Authenticated).userType == 'admin';
    
    if (!isAdmin) {
      // Redirecionar para tela de não autorizado
      Navigator.of(context).pushReplacementNamed('/unauthorized');
      return;
    }
    
    // Se for admin, carregar os dados
    _loadDashboardData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Carregar dados do dashboard via serviço
      final dashboardData = await _dashboardService.getDashboardData();
      
      setState(() {
        _totalUsers = dashboardData['totalUsers'] ?? 0;
        _totalDrivers = dashboardData['totalDrivers'] ?? 0;
        _totalRides = dashboardData['totalRides'] ?? 0;
        _totalRevenue = dashboardData['totalRevenue'] ?? 0;
        _recentRides = List<Map<String, dynamic>>.from(dashboardData['recentRides'] ?? []);
        _weeklyRides = Map<String, double>.from(dashboardData['weeklyRides'] ?? {});
      });
    } catch (e) {
      print('Erro ao carregar dados do dashboard: $e');
      // Exibir snackbar com erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: CustomScrollView(
                slivers: [
                  // App Bar personalizada
                  SliverAppBar(
                    expandedHeight: 180.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.blue[800],
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: const Text(
                        'Painel Administrativo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue[900]!, Colors.blue[700]!],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MotoApp',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadDashboardData,
                        tooltip: 'Atualizar dados',
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => const SettingsScreen())
                          );
                        },
                        tooltip: 'Configurações',
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Sair'),
                              content: const Text('Tem certeza que deseja sair?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('CANCELAR'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.read<AuthBloc>().add(LoggedOut());
                                  },
                                  child: const Text('SAIR'),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: 'Sair',
                      ),
                    ],
                  ),
                  
                  // Estatísticas gerais
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Visão Geral',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          isSmallScreen
                              ? Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: _buildStatsCard(
                                          title: 'Passageiros', 
                                          value: _totalUsers.toString(),
                                          icon: Icons.people,
                                          color: Colors.blue,
                                        )),
                                        const SizedBox(width: 16),
                                        Expanded(child: _buildStatsCard(
                                          title: 'Motoristas', 
                                          value: _totalDrivers.toString(),
                                          icon: Icons.motorcycle,
                                          color: Colors.green,
                                        )),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(child: _buildStatsCard(
                                          title: 'Corridas', 
                                          value: _totalRides.toString(),
                                          icon: Icons.map,
                                          color: Colors.amber,
                                        )),
                                        const SizedBox(width: 16),
                                        Expanded(child: _buildStatsCard(
                                          title: 'Receita Total', 
                                          value: 'R\$${_totalRevenue.toStringAsFixed(2)}',
                                          icon: Icons.attach_money,
                                          color: Colors.purple,
                                        )),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: _buildStatsCard(
                                      title: 'Usuários', 
                                      value: _totalUsers.toString(),
                                      icon: Icons.people,
                                      color: Colors.blue,
                                    )),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildStatsCard(
                                      title: 'Motoristas', 
                                      value: _totalDrivers.toString(),
                                      icon: Icons.motorcycle,
                                      color: Colors.green,
                                    )),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildStatsCard(
                                      title: 'Corridas', 
                                      value: _totalRides.toString(),
                                      icon: Icons.map,
                                      color: Colors.amber,
                                    )),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildStatsCard(
                                      title: 'Receita', 
                                      value: 'R\$${_totalRevenue.toStringAsFixed(2)}',
                                      icon: Icons.attach_money,
                                      color: Colors.purple,
                                    )),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Gráfico e Corridas Recentes (tabs)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TabBar(
                            controller: _tabController,
                            labelColor: Colors.blue[900],
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.blue[900],
                            tabs: const [
                              Tab(text: 'ESTATÍSTICAS'),
                              Tab(text: 'CORRIDAS RECENTES'),
                            ],
                          ),
                          Container(
                            height: 300,
                            padding: const EdgeInsets.only(top: 16),
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Tab 1: Gráfico de corridas da semana
                                _buildWeeklyRidesChart(),
                                
                                // Tab 2: Lista de corridas recentes
                                _buildRecentRidesList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Menu de acesso rápido
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gerenciamento',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDashboardItem(
                            context,
                            icon: Icons.people,
                            title: 'Usuários',
                            subtitle: 'Gerenciar contas de passageiros',
                            color: Colors.blue,
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => UserManagementScreen())
                              );
                            },
                          ),
                          _buildDashboardItem(
                            context,
                            icon: Icons.motorcycle,
                            title: 'Motoristas',
                            subtitle: 'Gerenciar contas de motoristas',
                            color: Colors.green,
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => DriverManagementScreen())
                              );
                            },
                          ),
                          _buildDashboardItem(
                            context,
                            icon: Icons.map,
                            title: 'Corridas',
                            subtitle: 'Visualizar e gerenciar corridas',
                            color: Colors.amber,
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => RideManagementScreen())
                              );
                            },
                          ),
                          _buildDashboardItem(
                            context,
                            icon: Icons.settings,
                            title: 'Configurações',
                            subtitle: 'Configurações do aplicativo',
                            color: Colors.purple,
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => SettingsScreen())
                              );
                            },
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
  
  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                color: Colors.grey[900],
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeeklyRidesChart() {
    if (_weeklyRides.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum dado disponível',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }
    
    final List<String> days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final List<double> values = days.map((day) => _weeklyRides[day] ?? 0).toList();
    final double maxValue = values.reduce((curr, next) => curr > next ? curr : next);
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueAccent,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${days[groupIndex]}\n${rod.toY.round()} corridas',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[value.toInt() % days.length],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: List.generate(
            days.length, 
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: Colors.blue[400],
                  width: 22,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxValue * 1.2,
                    color: Colors.grey[200],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecentRidesList() {
    if (_recentRides.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma corrida recente',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }
    
    return ListView.separated(
      itemCount: _recentRides.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final ride = _recentRides[index];
        final rideStatus = ride['status'] as String;
        Color statusColor;
        
        switch (rideStatus.toLowerCase()) {
          case 'completed':
            statusColor = Colors.green;
            break;
          case 'in_progress':
            statusColor = Colors.blue;
            break;
          case 'cancelled':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.grey;
        }
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.2),
            child: Icon(Icons.directions_car, color: statusColor),
          ),
          title: Text(
            'Corrida #${ride['id']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${ride['date']} • ${ride['driver']} • R\$${ride['price']}',
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Text(
              rideStatus,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          onTap: () {
            // Navegar para detalhes da corrida
            print('Visualizar detalhes da corrida ${ride['id']}');
          },
        );
      },
    );
  }
  
  Widget _buildDashboardItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}