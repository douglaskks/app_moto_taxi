// Arquivo: lib/views/driver/driver_profile_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

  @override
  _DriverProfileScreenState createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  // Dados simulados
  String _name = 'João Silva';
  String _email = 'joao.silva@email.com';
  String _phone = '(81) 98765-4321';
  String _vehicleModel = 'Honda CG 160';
  String _vehiclePlate = 'ABC-1234';
  String _vehicleYear = '2022';
  double _rating = 4.8;
  int _totalRides = 852;
  int _completionRate = 97; // em porcentagem
  
  File? _profileImage;
  final _imagePicker = ImagePicker();
  
  bool _isEditing = false;
  
  // Controladores para campos editáveis
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _vehiclePlateController;
  late TextEditingController _vehicleYearController;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _name);
    _phoneController = TextEditingController(text: _phone);
    _vehicleModelController = TextEditingController(text: _vehicleModel);
    _vehiclePlateController = TextEditingController(text: _vehiclePlate);
    _vehicleYearController = TextEditingController(text: _vehicleYear);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlateController.dispose();
    _vehicleYearController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }
  
  void _toggleEditMode() {
    setState(() {
      if (_isEditing) {
        // Salvar alterações
        _name = _nameController.text;
        _phone = _phoneController.text;
        _vehicleModel = _vehicleModelController.text;
        _vehiclePlate = _vehiclePlateController.text;
        _vehicleYear = _vehicleYearController.text;
        
        // Aqui você salvaria as alterações no Firebase
        _showSnackbar('Perfil atualizado com sucesso!');
      }
      
      _isEditing = !_isEditing;
    });
  }
  
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Foto de perfil
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _profileImage != null 
                        ? FileImage(_profileImage!) 
                        : null,
                    child: _profileImage == null
                        ? Icon(Icons.person, size: 80, color: Colors.grey[400])
                        : null,
                  ),
                  if (_isEditing)
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue[700],
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Nome do motorista
            _isEditing
                ? TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : Text(
                    _name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            
            if (!_isEditing) ...[
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  SizedBox(width: 4),
                  Text(
                    _rating.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
            
            SizedBox(height: 24),
            
            // Cartões de estatísticas
            if (!_isEditing)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Corridas', '$_totalRides', Icons.motorcycle),
                  _buildStatCard('Taxa de Conclusão', '$_completionRate%', Icons.check_circle),
                ],
              ),
            
            SizedBox(height: 24),
            
            // Informações de contato
            _buildSectionTitle('Informações de Contato'),
            SizedBox(height: 16),
            
            // Email (não editável)
            _buildInfoRow(
              'Email',
              _email,
              Icons.email,
              false,
            ),
            SizedBox(height: 16),
            
            // Telefone (editável)
            _isEditing
                ? TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Telefone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  )
                : _buildInfoRow(
                    'Telefone',
                    _phone,
                    Icons.phone,
                    false,
                  ),
            
            SizedBox(height: 24),
            
            // Informações do veículo
            _buildSectionTitle('Informações do Veículo'),
            SizedBox(height: 16),
            
            // Modelo
            _isEditing
                ? TextField(
                    controller: _vehicleModelController,
                    decoration: InputDecoration(
                      labelText: 'Modelo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.motorcycle),
                    ),
                  )
                : _buildInfoRow(
                    'Modelo',
                    _vehicleModel,
                    Icons.motorcycle,
                    false,
                  ),
            SizedBox(height: 16),
            
            // Placa
            _isEditing
                ? TextField(
                    controller: _vehiclePlateController,
                    decoration: InputDecoration(
                      labelText: 'Placa',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                  )
                : _buildInfoRow(
                    'Placa',
                    _vehiclePlate,
                    Icons.confirmation_number,
                    false,
                  ),
            SizedBox(height: 16),
            
            // Ano
            _isEditing
                ? TextField(
                    controller: _vehicleYearController,
                    decoration: InputDecoration(
                      labelText: 'Ano',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                  )
                : _buildInfoRow(
                    'Ano',
                    _vehicleYear,
                    Icons.calendar_today,
                    false,
                  ),
            
            SizedBox(height: 32),
            
            // Botões adicionais
            if (!_isEditing) ...[
              _buildActionButton(
                'Documentos do Veículo',
                Icons.description,
                () => _showSnackbar('Documentos não implementados'),
              ),
              SizedBox(height: 16),
              _buildActionButton(
                'Verificação de Antecedentes',
                Icons.security,
                () => _showSnackbar('Verificação não implementada'),
              ),
            ],
            
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon, bool isEditable) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700]),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            IconButton(
              icon: Icon(Icons.edit, size: 20),
              onPressed: () {},
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      width: 150,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[700], size: 32),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}