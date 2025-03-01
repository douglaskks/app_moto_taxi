import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/bloc/admin/driver_management_bloc.dart';
import '../../models/admin/user_management.dart';
import '../admin/user_details_screen.dart';

class DriverManagementScreen extends StatelessWidget {
  const DriverManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DriverManagementBloc()..add(LoadDriversList()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciamento de Motoristas'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                _showFilterDialog(context);
              },
            ),
          ],
        ),
        body: BlocBuilder<DriverManagementBloc, DriverManagementState>(
          builder: (context, state) {
            if (state is DriverManagementLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DriverManagementLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DriverManagementBloc>().add(LoadDriversList());
                },
                child: ListView.builder(
                  itemCount: state.drivers.length,
                  itemBuilder: (context, index) {
                    final driver = state.drivers[index];
                    return _buildDriverListItem(context, driver);
                  },
                ),
              );
            }

            if (state is DriverManagementError) {
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
                      'Erro ao carregar motoristas: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DriverManagementBloc>().add(LoadDriversList());
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddDriverDialog(context);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildDriverListItem(BuildContext context, UserDetails driver) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          backgroundImage: driver.profile?.profilePicUrl != null
              ? NetworkImage(driver.profile!.profilePicUrl!)
              : null,
          child: driver.profile?.profilePicUrl == null
              ? const Icon(
                  Icons.motorcycle,
                  size: 24,
                  color: Colors.grey,
                )
              : null,
        ),
        title: Text(
          driver.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(driver.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: const Text(
                    'Motorista',
                    style: TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.blue[100],
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                const SizedBox(width: 8),
                if (driver.profile?.driverInfo?.documentsVerified == true)
                  Chip(
                    label: const Text(
                      'Documentos Verificados',
                      style: TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.green[100],
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          driver.status == 'active'
              ? Icons.check_circle
              : driver.status == 'suspended'
                  ? Icons.warning
                  : Icons.block,
          color: driver.status == 'active'
              ? Colors.green
              : driver.status == 'suspended'
                  ? Colors.orange
                  : Colors.red,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailsScreen(userId: driver.id),
            ),
          );
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtrar Motoristas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Apenas motoristas ativos'),
                value: false,
                onChanged: (bool? value) {},
              ),
              CheckboxListTile(
                title: const Text('Documentos verificados'),
                value: false,
                onChanged: (bool? value) {},
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Aplicar filtros
                Navigator.of(context).pop();
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  void _showAddDriverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Motorista'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Lógica para adicionar motorista
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidade não implementada')),
                );
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }
}