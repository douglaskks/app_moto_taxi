// Arquivo: lib/views/driver/driver_earnings_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({Key? key}) : super(key: key);

  @override
  _DriverEarningsScreenState createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<String> _periods = ['Hoje', 'Esta Semana', 'Este Mês'];
  int _selectedPeriodIndex = 0;
  
  // Dados simulados
  final Map<String, Map<String, dynamic>> _earningStats = {
    'Hoje': {
      'total': 120.50,
      'rides': 8,
      'onlineHours': 6.5,
      'earnings': [
        {'time': '08:15', 'value': 18.50, 'from': 'Boa Viagem', 'to': 'Pina'},
        {'time': '09:40', 'value': 15.75, 'from': 'Pina', 'to': 'Casa Forte'},
        {'time': '11:20', 'value': 12.00, 'from': 'Casa Forte', 'to': 'Derby'},
        {'time': '13:05', 'value': 22.30, 'from': 'Derby', 'to': 'Boa Viagem'},
        {'time': '14:45', 'value': 10.50, 'from': 'Boa Viagem', 'to': 'Pina'},
        {'time': '16:30', 'value': 14.25, 'from': 'Pina', 'to': 'Espinheiro'},
        {'time': '18:10', 'value': 16.80, 'from': 'Espinheiro', 'to': 'Boa Viagem'},
        {'time': '19:50', 'value': 10.40, 'from': 'Boa Viagem', 'to': 'Pina'},
      ],
    },
    'Esta Semana': {
      'total': 780.25,
      'rides': 48,
      'onlineHours': 38.5,
      'earnings': [
        {'day': 'Segunda', 'value': 140.50},
        {'day': 'Terça', 'value': 120.75},
        {'day': 'Quarta', 'value': 155.30},
        {'day': 'Quinta', 'value': 120.50},
        {'day': 'Sexta', 'value': 180.80},
        {'day': 'Sábado', 'value': 62.40},
        {'day': 'Domingo', 'value': 0.0},
      ],
    },
    'Este Mês': {
      'total': 3200.75,
      'rides': 215,
      'onlineHours': 160.0,
      'earnings': [
        {'week': 'Semana 1', 'value': 850.50},
        {'week': 'Semana 2', 'value': 780.25},
        {'week': 'Semana 3', 'value': 920.80},
        {'week': 'Semana 4', 'value': 649.20},
      ],
    },
  };
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periods.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedPeriodIndex = _tabController.index;
        });
      }
    });
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
      ),
      body: SafeArea(
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
                          formatter.format(currentStats['total'] / currentStats['onlineHours']),
                          Icons.trending_up,
                        ),
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
              children: earnings.map((earning) {
                // Normalizar altura das barras
                final maxValue = earnings
                    .map<double>((e) => e['value'] as double)
                    .reduce((a, b) => a > b ? a : b);
                final percentage = earning['value'] / maxValue;
                final height = 150 * (percentage as num).toDouble();
                
                return _buildBarChartColumn(
                  earning['day'].toString(), // Converta para String
                  earning['value'],
                  height,
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
              children: earnings.map((earning) {
                // Normalizar altura das barras
                final maxValue = earnings
                    .map<double>((e) => e['value'] as double)
                    .reduce((a, b) => a > b ? a : b);
                final percentage = earning['value'] / maxValue;
                final height = 150 * (percentage as num).toDouble();
                
                return _buildBarChartColumn(
                  earning['week'].toString(), // Converta para String
                  earning['value'],
                  height,
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