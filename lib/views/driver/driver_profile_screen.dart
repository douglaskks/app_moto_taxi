// Arquivo: lib/views/driver/driver_profile_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

  @override
  _DriverProfileScreenState createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  // Variáveis para armazenar os dados do usuário
  String _name = '';
  String _email = '';
  String _phone = '';
  String _vehicleModel = '';
  String _vehiclePlate = '';
  String _vehicleYear = '';
  double _rating = 0.0;
  int _totalRides = 0;
  int _completionRate = 0;
  String _profileImageUrl = '';
  
  File? _profileImage;
  final _imagePicker = ImagePicker();
  
  bool _isEditing = false;
  bool _isLoading = true;
  
  // Controladores para campos editáveis
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _vehiclePlateController;
  late TextEditingController _vehicleYearController;
  
  // Referências Firebase
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _vehicleModelController = TextEditingController();
    _vehiclePlateController = TextEditingController();
    _vehicleYearController = TextEditingController();
    
    // Carregar dados do usuário ao iniciar
    _loadUserData();
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
  
  // Método para carregar os dados do usuário do Firestore
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obter usuário atual
      final User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // Buscar os dados do perfil do usuário - ajustado para utilizar a coleção 'users'
        final DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            _name = userData['name'] ?? '';
            _email = userData['email'] ?? currentUser.email ?? '';
            _phone = userData['phoneNumber'] ?? '';
            _vehicleModel = userData['vehicleModel'] ?? '';
            _vehiclePlate = userData['vehiclePlate'] ?? '';
            _vehicleYear = userData['vehicleYear'] ?? '';
            _profileImageUrl = userData['profileImageUrl'] ?? '';
            
            // Inicializar controladores com os dados
            _nameController.text = _name;
            _phoneController.text = _phone;
            _vehicleModelController.text = _vehicleModel;
            _vehiclePlateController.text = _vehiclePlate;
            _vehicleYearController.text = _vehicleYear;
          });
          
          // Carregar estatísticas
          await _loadDriverStatistics(currentUser.uid);
        } else {
          // Se o documento não existir, usar apenas o e-mail do Auth
          setState(() {
            _email = currentUser.email ?? '';
            _nameController.text = currentUser.displayName ?? '';
          });
        }
      }
    } catch (e) {
      _showSnackbar('Erro ao carregar dados: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Método para calcular as estatísticas do motorista
  Future<void> _loadDriverStatistics(String driverId) async {
    try {
      // Consultar as corridas do motorista - ajustado para considerar driver_id conforme suas regras
      final QuerySnapshot ridesSnapshot = await _firestore
          .collection('rides')
          .where('driver_id', isEqualTo: driverId)
          .get();
      
      final List<QueryDocumentSnapshot> rides = ridesSnapshot.docs;
      
      if (rides.isNotEmpty) {
        // Total de corridas
        final int totalRides = rides.length;
        
        // Corridas completadas
        final int completedRides = rides.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'completed';
        }).length;
        
        // Calcular taxa de conclusão
        final int completionRate = totalRides > 0 
            ? (completedRides / totalRides * 100).round() 
            : 0;
        
        // Calcular média de avaliações
        double totalRating = 0;
        int ratedRidesCount = 0;
        
        for (var ride in rides) {
          final data = ride.data() as Map<String, dynamic>;
          if (data['driver_rating'] != null) {
            totalRating += (data['driver_rating'] as num).toDouble();
            ratedRidesCount++;
          }
        }
        
        final double rating = ratedRidesCount > 0
            ? totalRating / ratedRidesCount
            : 0.0;
        
        setState(() {
          _totalRides = totalRides;
          _completionRate = completionRate;
          _rating = rating;
        });
      }
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackbar('Erro ao selecionar imagem: $e');
    }
  }
  
  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return null;
    
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;
      
      final String fileName = 'profile_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(_profileImage!.path)}';
      
      final Reference storageRef = _storage.ref().child('profile_images/$fileName');
      
      final UploadTask uploadTask = storageRef.putFile(_profileImage!);
      final TaskSnapshot taskSnapshot = await uploadTask;
      
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _showSnackbar('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }
  
  void _toggleEditMode() async {
    if (_isEditing) {
      // Validar campos antes de salvar
      if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
        _showSnackbar('Por favor, preencha os campos obrigatórios (Nome e Telefone)');
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Usuário atual
        final User? currentUser = _auth.currentUser;
        if (currentUser == null) {
          _showSnackbar('Usuário não autenticado');
          return;
        }
        
        // Upload da imagem (se existir)
        String? imageUrl;
        if (_profileImage != null) {
          imageUrl = await _uploadProfileImage();
        }
        
        // Dados a serem atualizados - apenas nome, telefone e foto
        // Removendo os campos de veículo que precisam de verificação
        final updatedData = {
          'name': _nameController.text,
          'email': _email,
          'phone': _phoneController.text,
          'lastUpdated': FieldValue.serverTimestamp(),
        };
        
        // Adicionar URL da imagem apenas se foi feito upload
        if (imageUrl != null) {
          updatedData['profileImageUrl'] = imageUrl;
        }
        
        // Atualizar no Firestore - usando a coleção 'users'
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .set(updatedData, SetOptions(merge: true));
        
        // Atualizar estado local com os novos valores
        setState(() {
          _name = _nameController.text;
          _phone = _phoneController.text;
          if (imageUrl != null) {
            _profileImageUrl = imageUrl;
          }
          
          // Não atualizamos os valores do veículo localmente
          // pois eles precisam passar por verificação
        });
        
        _showSnackbar('Perfil atualizado com sucesso!');
      } catch (e) {
        _showSnackbar('Erro ao atualizar perfil: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
    
    setState(() {
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
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _isLoading ? null : _toggleEditMode,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                              : (_profileImageUrl.isNotEmpty 
                                  ? NetworkImage(_profileImageUrl) as ImageProvider
                                  : null),
                          child: (_profileImage == null && _profileImageUrl.isEmpty)
                              ? Icon(Icons.person, size: 80, color: Colors.grey[400])
                              : null,
                        ),
                        if (_isEditing)
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue[700],
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
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
                          _name.isEmpty ? 'Adicione seu nome' : _name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _name.isEmpty ? Colors.grey : Colors.black,
                          ),
                        ),
                  
                  if (!_isEditing && _rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          _rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Cartões de estatísticas
                  if (!_isEditing && _totalRides > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('Corridas', '$_totalRides', Icons.motorcycle),
                        _buildStatCard('Taxa de Conclusão', '$_completionRate%', Icons.check_circle),
                      ],
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Informações de contato
                  _buildSectionTitle('Informações de Contato'),
                  const SizedBox(height: 16),
                  
                  // Email (não editável)
                  _buildInfoRow(
                    'Email',
                    _email,
                    Icons.email,
                    false,
                    _email.isEmpty,
                  ),
                  const SizedBox(height: 16),
                  
                  // Telefone (editável)
                  _isEditing
                      ? TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Telefone',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        )
                      : _buildInfoRow(
                          'Telefone',
                          _phone,
                          Icons.phone,
                          false,
                          _phone.isEmpty,
                        ),
                  
                  const SizedBox(height: 24),
                  
                  // Informações do veículo
                  _buildSectionTitle('Informações do Veículo'),
                  const SizedBox(height: 16),
                  
                  // Modelo
                  _buildInfoRow(
                    'Modelo',
                    _vehicleModel,
                    Icons.motorcycle,
                    false,
                    _vehicleModel.isEmpty,
                  ),
                  const SizedBox(height: 16),
                  
                  // Placa
                  _buildInfoRow(
                    'Placa',
                    _vehiclePlate,
                    Icons.confirmation_number,
                    false,
                    _vehiclePlate.isEmpty,
                  ),
                  const SizedBox(height: 16),
                  
                  // Ano
                  _buildInfoRow(
                    'Ano',
                    _vehicleYear,
                    Icons.calendar_today,
                    false,
                    _vehicleYear.isEmpty,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botões adicionais
                  if (!_isEditing) ...[
                    _buildActionButton(
                      'Documentos do Veículo',
                      Icons.description,
                      () => Navigator.pushNamed(context, '/documents'),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      'Histórico de Corridas',
                      Icons.history,
                      () => Navigator.pushNamed(context, '/ride-history'),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      'Solicitar Alteração de Veículo',
                      Icons.edit_note,
                      () => _showVehicleUpdateDialog(),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
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
  
  Widget _buildInfoRow(String label, String value, IconData icon, bool isEditable, bool isEmpty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700]),
          const SizedBox(width: 16),
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
                  isEmpty ? 'Adicionar $label' : value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {},
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[700], size: 32),
          const SizedBox(height: 8),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  // Método para mostrar o diálogo de atualização do veículo
  void _showVehicleUpdateDialog() {
    // Reseta os controladores com os valores atuais
    _vehicleModelController.text = _vehicleModel;
    _vehiclePlateController.text = _vehiclePlate;
    _vehicleYearController.text = _vehicleYear;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Alteração de Veículo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'As alterações serão revisadas pela nossa equipe antes de serem aprovadas.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _vehicleModelController,
                decoration: const InputDecoration(
                  labelText: 'Modelo do Veículo',
                  prefixIcon: Icon(Icons.motorcycle),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _vehiclePlateController,
                decoration: const InputDecoration(
                  labelText: 'Placa do Veículo',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _vehicleYearController,
                decoration: const InputDecoration(
                  labelText: 'Ano do Veículo',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _submitVehicleUpdateRequest();
              Navigator.pop(context);
            },
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }
  
  // Método para enviar a solicitação de atualização de veículo
  Future<void> _submitVehicleUpdateRequest() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showSnackbar('Usuário não autenticado');
        return;
      }
      
      // Criar um documento na coleção de solicitações
      await _firestore.collection('vehicleUpdateRequests').add({
        'userId': currentUser.uid,
        'currentVehicleModel': _vehicleModel,
        'currentVehiclePlate': _vehiclePlate,
        'currentVehicleYear': _vehicleYear,
        'requestedVehicleModel': _vehicleModelController.text,
        'requestedVehiclePlate': _vehiclePlateController.text,
        'requestedVehicleYear': _vehicleYearController.text,
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
      });
      
      _showSnackbar('Solicitação enviada com sucesso! Nossa equipe irá analisar.');
    } catch (e) {
      _showSnackbar('Erro ao enviar solicitação: $e');
    }
  }
}