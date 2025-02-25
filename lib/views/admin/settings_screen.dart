// lib/views/admin/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/bloc/admin/settings_bloc.dart';
import '../shared/components/admin_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc()..add(LoadSettings()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configurações'),
        ),
        drawer: const AdminDrawer(),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is SettingsLoaded) {
              return _SettingsForm(settings: state.settings);
            }
            
            if (state is SettingsError) {
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
                      'Erro ao carregar configurações: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<SettingsBloc>().add(LoadSettings());
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
}

class _SettingsForm extends StatefulWidget {
  final Map<String, dynamic> settings;
  
  const _SettingsForm({
    Key? key,
    required this.settings,
  }) : super(key: key);

  @override
  _SettingsFormState createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;
  
  // Configurações gerais
  late bool _enableNotifications;
  late bool _requireDocumentVerification;
  late bool _allowCashPayment;
  
  // Configurações financeiras
  late double _platformFeePercentage;
  late double _minFare;
  late double _pricePerKm;
  late double _pricePerMinute;
  
  // Configurações do aplicativo
  late String _selectedLanguage;
  late String _appTheme;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  void _loadSettings() {
    final settings = widget.settings;
    
    // Configurações gerais
    _enableNotifications = settings['enableNotifications'] ?? true;
    _requireDocumentVerification = settings['requireDocumentVerification'] ?? true;
    _allowCashPayment = settings['allowCashPayment'] ?? true;
    
    // Configurações financeiras
    _platformFeePercentage = (settings['platformFeePercentage'] ?? 15.0).toDouble();
    _minFare = (settings['minFare'] ?? 5.0).toDouble();
    _pricePerKm = (settings['pricePerKm'] ?? 2.0).toDouble();
    _pricePerMinute = (settings['pricePerMinute'] ?? 0.2).toDouble();
    
    // Configurações do aplicativo
    _selectedLanguage = settings['language'] ?? 'pt_BR';
    _appTheme = settings['theme'] ?? 'system';
  }
  
  void _markAsDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }
  
  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final updatedSettings = {
        // Configurações gerais
        'enableNotifications': _enableNotifications,
        'requireDocumentVerification': _requireDocumentVerification,
        'allowCashPayment': _allowCashPayment,
        
        // Configurações financeiras
        'platformFeePercentage': _platformFeePercentage,
        'minFare': _minFare,
        'pricePerKm': _pricePerKm,
        'pricePerMinute': _pricePerMinute,
        
        // Configurações do aplicativo
        'language': _selectedLanguage,
        'theme': _appTheme,
      };
      
      context.read<SettingsBloc>().add(SaveSettings(updatedSettings));
      
      setState(() {
        _isDirty = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações salvas com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      onChanged: _markAsDirty,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildGeneralSettingsCard(),
          const SizedBox(height: 16),
          _buildFinancialSettingsCard(),
          const SizedBox(height: 16),
          _buildAppSettingsCard(),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isDirty ? _saveSettings : null,
            child: const Text('SALVAR CONFIGURAÇÕES'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGeneralSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações Gerais',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Habilitar notificações push'),
              subtitle: const Text('Enviar notificações push para usuários e motoristas'),
              value: _enableNotifications,
              onChanged: (value) {
                setState(() {
                  _enableNotifications = value;
                  _markAsDirty();
                });
              },
            ),
            SwitchListTile(
              title: const Text('Verificação de documentos obrigatória'),
              subtitle: const Text('Exigir verificação de documentos para motoristas'),
              value: _requireDocumentVerification,
              onChanged: (value) {
                setState(() {
                  _requireDocumentVerification = value;
                  _markAsDirty();
                });
              },
            ),
            SwitchListTile(
              title: const Text('Permitir pagamento em dinheiro'),
              subtitle: const Text('Habilitar opção de pagamento em dinheiro'),
              value: _allowCashPayment,
              onChanged: (value) {
                setState(() {
                  _allowCashPayment = value;
                  _markAsDirty();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFinancialSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações Financeiras',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Percentual de taxa da plataforma'),
              subtitle: Text('${_platformFeePercentage.toStringAsFixed(1)}%'),
              trailing: SizedBox(
                width: 200,
                child: Slider(
                  min: 5.0,
                  max: 30.0,
                  divisions: 50,
                  value: _platformFeePercentage,
                  label: '${_platformFeePercentage.toStringAsFixed(1)}%',
                  onChanged: (value) {
                    setState(() {
                      _platformFeePercentage = value;
                      _markAsDirty();
                    });
                  },
                ),
              ),
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Valor mínimo da corrida (R\$)',
                border: OutlineInputBorder(),
              ),
              initialValue: _minFare.toString(),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o valor mínimo';
                }
                if (double.tryParse(value) == null) {
                  return 'Informe um valor numérico válido';
                }
                return null;
              },
              onChanged: (value) {
                final newValue = double.tryParse(value);
                if (newValue != null) {
                  _minFare = newValue;
                  _markAsDirty();
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Preço por km (R\$)',
                border: OutlineInputBorder(),
              ),
              initialValue: _pricePerKm.toString(),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o preço por km';
                }
                if (double.tryParse(value) == null) {
                  return 'Informe um valor numérico válido';
                }
                return null;
              },
              onChanged: (value) {
                final newValue = double.tryParse(value);
                if (newValue != null) {
                  _pricePerKm = newValue;
                  _markAsDirty();
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Preço por minuto (R\$)',
                border: OutlineInputBorder(),
              ),
              initialValue: _pricePerMinute.toString(),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o preço por minuto';
                }
                if (double.tryParse(value) == null) {
                  return 'Informe um valor numérico válido';
                }
                return null;
              },
              onChanged: (value) {
                final newValue = double.tryParse(value);
                if (newValue != null) {
                  _pricePerMinute = newValue;
                  _markAsDirty();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações do Aplicativo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Idioma',
                border: OutlineInputBorder(),
              ),
              value: _selectedLanguage,
              items: const [
                DropdownMenuItem(
                  value: 'pt_BR',
                  child: Text('Português (Brasil)'),
                ),
                DropdownMenuItem(
                  value: 'en_US',
                  child: Text('English (US)'),
                ),
                DropdownMenuItem(
                  value: 'es_ES',
                  child: Text('Español'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                    _markAsDirty();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tema',
                border: OutlineInputBorder(),
              ),
              value: _appTheme,
              items: const [
                DropdownMenuItem(
                  value: 'system',
                  child: Text('Sistema (automático)'),
                ),
                DropdownMenuItem(
                  value: 'light',
                  child: Text('Claro'),
                ),
                DropdownMenuItem(
                  value: 'dark',
                  child: Text('Escuro'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _appTheme = value;
                    _markAsDirty();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}