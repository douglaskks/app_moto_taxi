// lib/views/admin/financial_report_screen.dart
import 'package:app_moto_taxe/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../controllers/bloc/admin/financial_bloc.dart';
import '../../models/admin/financial_report.dart';
import '../shared/components/admin_drawer.dart';
import 'package:fl_chart/fl_chart.dart';

class FinancialReportScreen extends StatelessWidget with AdminRouteMixin {
  const FinancialReportScreen({super.key});

  @override
  Widget buildAdminScreen(BuildContext context) {
    return BlocProvider(
      create: (context) => FinancialBloc()..add(
        LoadFinancialReport(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Relatório Financeiro'),
        ),
        drawer: const AdminDrawer(),
        body: BlocBuilder<FinancialBloc, FinancialState>(
          builder: (context, state) {
            if (state is FinancialLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is FinancialLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateRangePicker(context, state),
                    const SizedBox(height: 24),
                    _buildFinancialSummary(context, state.report),
                    const SizedBox(height: 24),
                    _buildRevenueChart(context, state.report),
                    const SizedBox(height: 24),
                    Text(
                      'Transações',
                      style: Theme.of(context).textTheme.titleLarge, // Substituído headline5
                    ),
                    const SizedBox(height: 16),
                    _buildTransactionsList(context, state.report.transactions),
                  ],
                ),
              );
            }
            
            if (state is FinancialError) {
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
  
  Widget _buildDateRangePicker(BuildContext context, FinancialLoaded state) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final report = state.report;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data inicial'),
                  const SizedBox(height: 8),
                  Text(
                    dateFormat.format(report.startDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data final'),
                  const SizedBox(height: 8),
                  Text(
                    dateFormat.format(report.endDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2022),
                  lastDate: DateTime.now(),
                  initialDateRange: DateTimeRange(
                    start: report.startDate,
                    end: report.endDate,
                  ),
                );
                
                if (picked != null) {
                  context.read<FinancialBloc>().add(
                    LoadFinancialReport(
                      startDate: picked.start,
                      endDate: picked.end,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFinancialSummary(BuildContext context, FinancialReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo Financeiro',
          style: Theme.of(context).textTheme.titleLarge, // Substituído headline5
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildSummaryCard(
              context,
              'Receita Total',
              'R\$ ${report.totalRevenue.toStringAsFixed(2)}',
              Colors.green,
              Icons.attach_money,
            ),
            _buildSummaryCard(
              context,
              'Taxas da Plataforma',
              'R\$ ${report.platformFees.toStringAsFixed(2)}',
              Colors.blue,
              Icons.account_balance,
            ),
            _buildSummaryCard(
              context,
              'Pagamentos a Motoristas',
              'R\$ ${report.driverPayouts.toStringAsFixed(2)}',
              Colors.orange,
              Icons.motorcycle,
            ),
            _buildSummaryCard(
              context,
              'Total de Transações',
              report.transactions.length.toString(),
              Colors.purple,
              Icons.receipt_long,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith( // Substituído headline6
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRevenueChart(BuildContext context, FinancialReport report) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Receita por Dia',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // Converte o índice para o dia correspondente
                        if (value >= 0 && value < report.dailyRevenues.length) {
                          return Text(
                            DateFormat('dd/MM').format(report.dailyRevenues[value.toInt()].date),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'R\$ ${value.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 50,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: report.dailyRevenues.asMap().entries.map((entry) {
                  final index = entry.key;
                  final dailyRevenue = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: dailyRevenue.amount,
                        color: Colors.green,
                        width: 15,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                gridData: FlGridData(show: false),
                maxY: report.dailyRevenues.isNotEmpty 
                  ? report.dailyRevenues.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.2 
                  : 100,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
  
  Widget _buildTransactionsList(
    BuildContext context,
    List<FinancialTransaction> transactions,
  ) {
    if (transactions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Nenhuma transação encontrada no período selecionado.'),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text(transaction.description),
            subtitle: Text(dateFormat.format(transaction.date)),
            trailing: Text(
              'R\$ ${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: transaction.type == 'credit' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: transaction.type == 'credit'
                  ? Colors.green[100]
                  : Colors.red[100],
              child: Icon(
                transaction.type == 'credit'
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: transaction.type == 'credit'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            onTap: () {
              // Mostrar detalhes da transação
            },
          ),
        );
      },
    );
  }
}