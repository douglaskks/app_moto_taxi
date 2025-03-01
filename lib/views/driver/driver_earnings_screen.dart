// Arquivo: lib/views/driver/driver_earnings_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/earnings_service.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({Key? key}) : super(key: key);

  @override
  _DriverEarningsScreenState createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EarningsService _earningsService = EarningsService();
  
  final List<String> _periods = ['Hoje', 'Esta Semana', 'Este Mês'];
  int _selectedPeriodIndex = 0;
  
  // Dados reais
  Map<String, Map<String, dynamic>> _earningStats = {
    'Hoje': {
      'total': 0.0,
      'rides': 0,
      'onlineHours': 0.0,
      'earnings': [],
    },
    'Esta Semana': {
      'total': 0.0,
      'rides': 0,
      'onlineHours': 0.0,
      'earnings': [],
    },
    'Este Mês': {
      'total': 0.0,
      'rides': 0,
      'onlineHours': 0.0,
      'earnings': [],
    },
  };
  
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periods.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedPeriodIndex = _tabController.index;
        });
        // Carregar dados para a nova tab selecionada
        _loadData(_selectedPeriodIndex);
      }
    });
    
    // Carregar dados iniciais
    _loadData(_selectedPeriodIndex);
  }
  
  // Carregar dados com base no período selecionado
  Future<void> _loadData(int periodIndex) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final DateTime now = DateTime.now();
      
      switch (periodIndex) {
        case 0: // Hoje
          final String today = DateFormat('yyyy-MM-dd').format(now);
          
          // Buscar estatísticas do dia
          final dailyStats = await _earningsService.getDailyEarnings(today);
          
          // Buscar corridas do dia
          final rides = await _earningsService.getRideHistory(dateFilter: today);
          
          setState(() {
            _earningStats['Hoje'] = {
              'total': dailyStats['total_amount'] ?? 0.0,
              'rides': dailyStats['total_rides'] ?? 0,
              'onlineHours': dailyStats['online_hours'] ?? 0.0,
              'earnings': rides.map((ride) {
                // Extrair hora da corrida
                String time = "00:00";
                if (ride['timestamp'] != null) {
                  final DateTime timestamp = ride['timestamp'];
                  time = DateFormat('HH:mm').format(timestamp);
                }
                
                return {
                  'time': time,
                  'value': ride['driver_amount'] ?? 0.0,
                  'from': ride['pickup_address'] ?? '',
                  'to': ride['destination_address'] ?? '',
                };
              }).toList(),
            };
          });
          break;
          
        case 1: // Esta Semana
          // Calcular início da semana (segunda-feira)
          final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          
          // Criar mapa para dias da semana
          final Map<String, Map<String, dynamic>> weekData = {
            'Segunda': {'value': 0.0, 'rides': 0},
            'Terça': {'value': 0.0, 'rides': 0},
            'Quarta': {'value': 0.0, 'rides': 0},
            'Quinta': {'value': 0.0, 'rides': 0},
            'Sexta': {'value': 0.0, 'rides': 0},
            'Sábado': {'value': 0.0, 'rides': 0},
            'Domingo': {'value': 0.0, 'rides': 0},
          };
          
          // Calcular chave da semana
          final String weekKey = _getWeekKey(now);
          
          // Buscar estatísticas da semana
          final weeklyStats = await _earningsService.getWeeklyEarnings(weekKey);
          
          // Buscar dados diários para cada dia da semana
          double totalAmount = 0.0;
          int totalRides = 0;
          
          for (int i = 0; i < 7; i++) {
            final DateTime day = startOfWeek.add(Duration(days: i));
            final String dayKey = DateFormat('yyyy-MM-dd').format(day);
            final String weekDay = _getDayName(day.weekday);
            
            // Buscar estatísticas do dia
            final dayStats = await _earningsService.getDailyEarnings(dayKey);
            
            final double dayAmount = dayStats['total_amount'] ?? 0.0;
            final int dayRides = dayStats['total_rides'] ?? 0;
            
            weekData[weekDay] = {
              'value': dayAmount,
              'rides': dayRides,
            };
            
            totalAmount += dayAmount;
            totalRides += dayRides;
          }
          
          // Transformar dados para o formato esperado pela UI
          final List<Map<String, dynamic>> weekEarnings = weekData.entries.map((entry) {
            return {
              'day': entry.key,
              'value': entry.value['value'],
              'rides': entry.value['rides'],
            };
          }).toList();
          
          setState(() {
            _earningStats['Esta Semana'] = {
              'total': totalAmount,
              'rides': totalRides,
              'onlineHours': weeklyStats['online_hours'] ?? 0.0,
              'earnings': weekEarnings,
            };
          });
          break;
          
        case 2: // Este Mês
          // Calcular primeiro dia do mês
          final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
          
          // Calcular chave do mês
          final String monthKey = DateFormat('yyyy-MM').format(now);
          
          // Buscar estatísticas do mês
          final monthlyStats = await _earningsService.getMonthlyEarnings(monthKey);
          
          // Dividir o mês em semanas
          final List<Map<String, dynamic>> weeklyData = [];
          
          // Número de semanas no mês atual (aproximado)
          final int numWeeks = (DateTime(now.year, now.month + 1, 0).day / 7).ceil();
          
          for (int i = 0; i < numWeeks; i++) {
            final DateTime weekStart = firstDayOfMonth.add(Duration(days: i * 7));
            final DateTime weekEnd = weekStart.add(Duration(days: 6));
            
            final String weekLabel = 'Semana ${i + 1}';
            final String weekKey = _getWeekKey(weekStart);
            
            // Buscar estatísticas da semana
            final weekStats = await _earningsService.getWeeklyEarnings(weekKey);
            
            weeklyData.add({
              'week': weekLabel,
              'value': weekStats['total_amount'] ?? 0.0,
              'rides': weekStats['total_rides'] ?? 0,
            });
          }
          
          setState(() {
            _earningStats['Este Mês'] = {
              'total': monthlyStats['total_amount'] ?? 0.0,
              'rides': monthlyStats['total_rides'] ?? 0,
              'onlineHours': monthlyStats['online_hours'] ?? 0.0,
              'earnings': weeklyData,
            };
          });
          break;
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
      // Mostrar erro ao usuário, se necessário
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Obter chave da semana no formato "yyyy-Www" (ex: 2025-W08)
  String _getWeekKey(DateTime date) {
    final int weekNumber = ((date.difference(DateTime(date.year, 1, 1)).inDays) / 7).floor() + 1;
    return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }
  
  // Obter nome do dia da semana
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Segunda';
      case 2: return 'Terça';
      case 3: return 'Quarta';
      case 4: return 'Quinta';
      case 5: return 'Sexta';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return '';
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStats = _earningStats[_periods[_selectedPeriodIndex]]!;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Ganhos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _periods.map((period) => Tab(text: period)).toList(),
          indicatorColor: Colors.blue[700],
          labelColor: Colors.blue[700],
          unselectedLabelColor: Colors.grey,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadData(_selectedPeriodIndex),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: () => _loadData(_selectedPeriodIndex),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Resumo de ganhos
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue[700]!, Colors.blue[900]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total de Ganhos',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              formatter.format(currentStats['total']),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryItem(
                                  'Corridas',
                                  '${currentStats['rides']}',
                                  Icons.motorcycle,
                                ),
                                _buildSummaryItem(
                                  'Horas Online',
                                  '${currentStats['onlineHours']}h',
                                  Icons.access_time,
                                ),
                                _buildSummaryItem(
                                  'Média/Hora',
                                  formatter.format(
                                    currentStats['onlineHours'] > 0
                                        ? currentStats['total'] / currentStats['onlineHours']
                                        : 0.0
                                  ),
                                  Icons.trending_up  // Adicionando o terceiro argumento que estava faltando
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Histórico de ganhos
                      Text(
                        'Histórico de Ganhos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Lista de ganhos
                      Expanded(
                        child: _buildEarningsList(currentStats),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEarningsList(Map<String, dynamic> stats) {
    final List<dynamic> earnings = stats['earnings'];
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    if (earnings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.money_off, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Nenhum ganho registrado neste período',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    // Hoje - lista de corridas detalhadas
    if (_selectedPeriodIndex == 0) {
      return ListView.builder(
        itemCount: earnings.length,
        itemBuilder: (context, index) {
          final earning = earnings[index];
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Icon(Icons.motorcycle, color: Colors.blue[700]),
              ),
              title: Text(
                '${earning['from']} → ${earning['to']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(earning['time']),
              trailing: Text(
                formatter.format(earning['value']),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green[700],
                ),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            ),
          );
        },
      );
    }
    
    // Esta Semana - gráfico de barras por dia
    else if (_selectedPeriodIndex == 1) {
      return Column(
        children: [
          Container(
            height: 200,
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: earnings.map<Widget>((earning) {
                // Normalizar altura das barras
                final maxValue = earnings
                    .map<double>((e) => e['value'] as double)
                    .reduce((a, b) => a > b ? a : b);
                
                final double barValue = earning['value'] as double;
                final double percentage = maxValue > 0 ? barValue / maxValue : 0;
                final double height = 150 * percentage;
                
                return _buildBarChartColumn(
                  earning['day'],
                  barValue,
                  height > 0 ? height : 1, // Garantir altura mínima para dias com valor zero
                  formatter,
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: earnings.length,
              itemBuilder: (context, index) {
                final earning = earnings[index];
                return ListTile(
                  title: Text(earning['day']),
                  trailing: Text(
                    formatter.format(earning['value']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  subtitle: Text('${earning['rides']} corridas'),
                );
              },
            ),
          ),
        ],
      );
    }
    
    // Este Mês - gráfico de barras por semana
    else {
      return Column(
        children: [
          Container(
            height: 200,
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: earnings.map<Widget>((earning) {
                // Normalizar altura das barras
                final maxValue = earnings
                    .map<double>((e) => e['value'] as double)
                    .reduce((a, b) => a > b ? a : b);
                
                final double barValue = earning['value'] as double;
                final double percentage = maxValue > 0 ? barValue / maxValue : 0;
                final double height = 150 * percentage;
                
                return _buildBarChartColumn(
                  earning['week'],
                  barValue,
                  height > 0 ? height : 1, // Garantir altura mínima para semanas com valor zero
                  formatter,
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: earnings.length,
              itemBuilder: (context, index) {
                final earning = earnings[index];
                return ListTile(
                  title: Text(earning['week']),
                  trailing: Text(
                    formatter.format(earning['value']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  subtitle: Text('${earning['rides']} corridas'),
                );
              },
            ),
          ),
        ],
      );
    }
  }
  
  Widget _buildBarChartColumn(String label, double value, double height, NumberFormat formatter) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          formatter.format(value),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Container(
          width: 30,
          height: height,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[400]!, Colors.blue[800]!],
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}