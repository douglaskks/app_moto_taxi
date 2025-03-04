import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
class ProfilePassengerScreen extends StatefulWidget {
  const ProfilePassengerScreen({Key? key}) : super(key: key);

  @override
  State<ProfilePassengerScreen> createState() => _ProfilePassengerScreenState();
}

class _ProfilePassengerScreenState extends State<ProfilePassengerScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  File? _imageFile;
  
  // Controladores para os campos de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  
  // Formatadores para inputs específicos
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####', 
    filter: {"#": RegExp(r'[0-9]')},
  );
  
  final _documentMask = MaskTextInputFormatter(
    mask: '###.###.###-##', 
    filter: {"#": RegExp(r'[0-9]')},
  );
  
  String? _profileImageUrl;
  Map<String, dynamic>? _userData;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Deixar a barra de status visível mas com a cor que queremos
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Definir cores
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.blue[800], // Mesma cor do app bar
    statusBarIconBrightness: Brightness.light,));
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _documentController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }
  
  // Carregar dados do usuário
  Future<void> _loadUserData() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    final User? currentUser = _auth.currentUser;
    
    if (currentUser != null) {
      // Buscar dados do Firestore
      final docSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
          
      if (docSnapshot.exists) {
        setState(() {
          _userData = docSnapshot.data() as Map<String, dynamic>;
          _profileImageUrl = _userData?['profileImage']; // Corrigido: profileImage em vez de profile_image_url
          
          // Preencher os controladores com os nomes corretos dos campos
          _nameController.text = _userData?['name'] ?? '';
          _emailController.text = _userData?['email'] ?? currentUser.email ?? '';
          _phoneController.text = _userData?['phoneNumber'] ?? ''; // Corrigido: phoneNumber em vez de phone
          _addressController.text = _userData?['address'] ?? '';
          _documentController.text = _userData?['document'] ?? '';  // CPF
          _emergencyContactController.text = _userData?['emergency_contact'] ?? '';
        });
      } else {
        // Se o documento ainda não existir no Firestore
        _nameController.text = currentUser.displayName ?? '';
        _emailController.text = currentUser.email ?? '';
        _phoneController.text = currentUser.phoneNumber ?? '';
      }
    }
  } catch (e) {
    print('Erro ao carregar dados do usuário: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar perfil: $e')),
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

  
  // Selecionar imagem da galeria ou câmera
  Future<void> _selectImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (pickedImage != null) {
        setState(() {
          _imageFile = File(pickedImage.path);
        });
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    }
  }
  
  // Mostrar diálogo para escolher fonte da imagem
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar foto de perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _selectImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _selectImage(ImageSource.camera);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
        ],
      ),
    );
  }
  
  // Salvar dados do usuário
  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // Referência para o documento do usuário
        final userRef = _firestore.collection('users').doc(currentUser.uid);
        
        // Fazer upload da imagem, se houver uma nova
        String? imageUrl = _profileImageUrl;
        if (_imageFile != null) {
          final storageRef = _storage
              .ref()
              .child('user_profiles')
              .child('${currentUser.uid}.jpg');
              
          await storageRef.putFile(_imageFile!);
          imageUrl = await storageRef.getDownloadURL();
        }
        
        // Dados a serem salvos - usando os nomes corretos dos campos
        final userData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(), // Corrigido
          'address': _addressController.text.trim(),
          'document': _documentController.text.trim(), // CPF
          'emergency_contact': _emergencyContactController.text.trim(),
          'profileImage': imageUrl, // Corrigido
          'updated_at': FieldValue.serverTimestamp(),
        };
        
        // Atualizar o Firestore
        await userRef.set(userData, SetOptions(merge: true));
        
        // Atualizar SharedPreferences para uso rápido em outras partes do app
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _nameController.text.trim());
        await prefs.setString('user_phone', _phoneController.text.trim());
        
        // Atualizar perfil do Firebase Auth
        await currentUser.updateDisplayName(_nameController.text.trim());
        
        // Se o email for alterado, é necessário atualizar a autenticação
        if (currentUser.email != _emailController.text.trim()) {
          await currentUser.updateEmail(_emailController.text.trim());
        }
        
        setState(() {
          _profileImageUrl = imageUrl;
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
      }
    } catch (e) {
      print('Erro ao salvar dados do usuário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(  
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Meu Perfil'),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                // Reverter alterações
                _loadUserData();
                setState(() {
                  _isEditing = false;
                  _imageFile = null;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Cabeçalho com foto de perfil
                  Container(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Stack(
                            children: [
                              // Foto de perfil
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _imageFile != null
                                      ? Image.file(
                                          _imageFile!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        )
                                      : _profileImageUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: _profileImageUrl!,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => const CircularProgressIndicator(),
                                              errorWidget: (context, url, error) => const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.grey,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.grey,
                                            ),
                                ),
                              ),
                              // Botão para editar foto
                              if (_isEditing)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue[600],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                      onPressed: _showImagePickerDialog,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _nameController.text.isNotEmpty ? _nameController.text : 'Passageiro',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (!_isEditing && _emailController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: Text(
                                _emailController.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Formulário de informações pessoais
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informações Pessoais',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Nome completo
                          _buildTextField(
                            controller: _nameController,
                            label: 'Nome Completo',
                            enabled: _isEditing,
                            prefixIcon: Icons.person,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, informe seu nome';
                              }
                              return null;
                            },
                          ),
                          
                          // E-mail
                          _buildTextField(
                            controller: _emailController,
                            label: 'E-mail',
                            enabled: _isEditing,
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, informe seu e-mail';
                              } else if (!value.contains('@') || !value.contains('.')) {
                                return 'Informe um e-mail válido';
                              }
                              return null;
                            },
                          ),
                          
                          // Telefone
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Telefone',
                            enabled: _isEditing,
                            prefixIcon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [_phoneMask],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, informe seu telefone';
                              } else if (value.length < 14) {
                                return 'Telefone incompleto';
                              }
                              return null;
                            },
                          ),
                          
                          // CPF
                          _buildTextField(
                            controller: _documentController,
                            label: 'CPF',
                            enabled: _isEditing,
                            prefixIcon: Icons.badge,
                            keyboardType: TextInputType.number,
                            inputFormatters: [_documentMask],
                            validator: (value) {
                              if (_isEditing && (value == null || value.isEmpty)) {
                                return 'Por favor, informe seu CPF';
                              } else if (_isEditing && value!.length < 14) {
                                return 'CPF incompleto';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Text(
                            'Informações Adicionais',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Endereço
                          _buildTextField(
                            controller: _addressController,
                            label: 'Endereço',
                            enabled: _isEditing,
                            prefixIcon: Icons.home,
                            maxLines: 2,
                          ),
                          
                          // Contato de emergência
                          _buildTextField(
                            controller: _emergencyContactController,
                            label: 'Contato de Emergência',
                            enabled: _isEditing,
                            prefixIcon: Icons.emergency,
                            helperText: 'Nome e telefone de alguém para contato em caso de emergência',
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Botão de salvar
                          if (_isEditing)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveUserData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isSaving
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        'SALVAR ALTERAÇÕES',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
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
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? helperText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[700]!, width: 1),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          helperText: helperText,
        ),
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }
}