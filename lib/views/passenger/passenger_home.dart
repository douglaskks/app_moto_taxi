// Arquivo: lib/views/passenger/passenger_home.dart
import 'package:app_moto_taxe/controllers/bloc/auth/auth_bloc.dart';
import 'package:app_moto_taxe/controllers/bloc/auth/auth_event.dart';
import 'package:app_moto_taxe/controllers/bloc/auth/auth_state.dart';
import 'package:app_moto_taxe/core/services/location_service.dart';
import 'package:app_moto_taxe/views/passenger/map_screen.dart';
import 'package:app_moto_taxe/views/passenger/profile_screen.dart';
import 'package:app_moto_taxe/views/passenger/ride_history_screen.dart';
import 'package:app_moto_taxe/views/passenger/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  final LocationService _locationService = LocationService();
  String _currentAddress = "Carregando localização...";
  bool _loadingLocation = true;
  final String _weatherInfo = "23°C Ensolarado";
  String _greeting = "Olá";
  String _userName = "Passageiro";
  
  // Lista de corridas rápidas frequentes
  final List<Map<String, dynamic>> _quickRides = [];
  
  // Lista de promoções
  final List<Map<String, String>> _promotions = [
    {
      'title': 'Desconto na primeira corrida',
      //'description': 'Use o código BEMVINDO para ganhar 20% de desconto',
      'description': 'Ganhe R\$10 por cada amigo',
      //'image': 'lib/assets/images/promocao.png',
      'color': '#FF3D71'
    },
    {
      'title': 'Indique e ganhe',
      'description': 'Ganhe R\$10 por cada amigo que usar seu código',
      //'image': 'assets/promo2.jpg',
      'color': '#0095FF'
    },
    {
      'title': 'Corridas de segunda a sexta',
      //'description': 'Desconto de 15% em corridas entre 10h e 16h',
      'description': 'Ganhe R\$10 por cada amigo',
      //'image': 'assets/promo3.jpg',
      'color': '#00D68F'
    },
  ];

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _loadQuickRides();
    _setGreeting();
    _determinePosition();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = "Bom dia";
      } else if (hour < 18) {
        _greeting = "Boa tarde";
      } else {
        _greeting = "Boa noite";
      }
    });
  }

  Future<void> _getUserInfo() async {
    // Em um app real, isso provavelmente viria de um estado global ou BLoC
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Passageiro';
    });

    // Também poderia buscar do BLoC de Auth
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      // Apenas use o userId ou busque o nome do usuário 
      // de outra fonte usando o userId
      final userId = authState.userId;
      final userName = prefs.getString('name_$userId') ?? _userName;
      
      setState(() {
        _userName = userName;
      });
    }
  }

  Future<void> _loadQuickRides() async {
    // Em um app real, isso viria de um banco de dados ou API
    setState(() {
      _quickRides.clear();
      _quickRides.addAll([
        {
          'title': 'Casa',
          'address': 'Rua da sua casa, 123, Recife',
          'icon': Icons.home,
          'color': Colors.blue[700]
        },
        {
          'title': 'Trabalho',
          'address': 'Av. do seu trabalho, 456, Recife',
          'icon': Icons.work,
          'color': Colors.amber[700]
        },
        {
          'title': 'Shopping Recife',
          'address': 'Av. República do Líbano, 251, Recife',
          'icon': Icons.shopping_bag,
          'color': Colors.purple[700]
        },
      ]);
    });
  }

  Future<void> _determinePosition() async {
    setState(() {
      _loadingLocation = true;
    });
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = "Serviço de localização desativado";
          _loadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = "Permissão de localização negada";
            _loadingLocation = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = "Permissões de localização negadas permanentemente";
          _loadingLocation = false;
        });
        return;
      }

      // Corrigido: uso de LocationSettings em vez de desiredAccuracy
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      if (!mounted) return;
      
      String address = await _locationService.getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (!mounted) return;
      
      setState(() {
        _currentAddress = address;
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentAddress = "Não foi possível obter localização";
        _loadingLocation = false;
      });
    }
  }

  void _navigateToMapScreen(String? destinationAddress) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => const MapScreen(),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obter dimensões da tela para responsividade
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
    // Ajustar tamanhos com base no tamanho da tela
    final headerFontSize = isSmallScreen ? 22.0 : 26.0;
    final subHeaderFontSize = isSmallScreen ? 16.0 : 18.0;
    final locationFontSize = isSmallScreen ? 12.0 : 14.0;
    final cardHeight = isSmallScreen ? 100.0 : 120.0;
    final quickRideWidth = isSmallScreen ? 120.0 : 140.0;
    final promoHeight = isSmallScreen ? 150.0 : 180.0;
    final promoWidth = isSmallScreen ? 250.0 : 280.0;
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar personalizada
            SliverAppBar(
              expandedHeight: isSmallScreen ? 150.0 : 180.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.blue[800],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue[800]!, Colors.blue[600]!],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "$_greeting, $_userName!",
                          style: TextStyle(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white.withOpacity(0.9), size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _loadingLocation ? "Carregando localização..." : _currentAddress,
                                style: TextStyle(
                                  fontSize: locationFontSize,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wb_sunny, 
                                  color: Colors.white.withOpacity(0.9), 
                                  size: 16
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _weatherInfo,
                                  style: TextStyle(
                                    fontSize: locationFontSize,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPassengerScreen()),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'logout') {
                      context.read<AuthBloc>().add(LoggedOut());
                    } else if (value == 'profile') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePassengerScreen()),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return const [
                      PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.black54),
                            SizedBox(width: 8),
                            Text('Meu Perfil'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.black54),
                            SizedBox(width: 8),
                            Text('Sair'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            
            // Conteúdo principal
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botão grande para solicitar corrida
                    GestureDetector(
                      onTap: () {
                        _navigateToMapScreen(null);
                      },
                      child: Container(
                        width: double.infinity,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[700]!, Colors.blue[900]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -10,
                              bottom: -10,
                              child: Icon(
                                Icons.motorcycle,
                                size: isSmallScreen ? 80 : 100,
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12, 
                                      vertical: 6
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.local_taxi,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "MOTOAPP",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Solicitar Corrida",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Chega rápido e com segurança",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Corridas rápidas frequentes
                    Text(
                      "Corridas Rápidas",
                      style: TextStyle(
                        fontSize: subHeaderFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: cardHeight,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickRides.length,
                        itemBuilder: (context, index) {
                          final ride = _quickRides[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: GestureDetector(
                              onTap: () {
                                _navigateToMapScreen(ride['address']);
                              },
                              child: Container(
                                width: quickRideWidth,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: ride['color']!.withOpacity(0.2),
                                        radius: isSmallScreen ? 18 : 20,
                                        child: Icon(
                                          ride['icon'],
                                          color: ride['color'],
                                          size: isSmallScreen ? 18 : 20,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        ride['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Toque para ir",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 10,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Promoções
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Ofertas e Promoções",
                          style: TextStyle(
                            fontSize: subHeaderFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navegar para tela de todas as promoções
                          },
                          child: Text(
                            "Ver todos",
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: promoHeight,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _promotions.length,
                        itemBuilder: (context, index) {
                          final promo = _promotions[index];
                          // Converter hexadecimal para Color
                          final color = Color(
                            int.parse(promo['color']!.substring(1, 7), radix: 16) + 0xFF000000
                          );
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Container(
                              width: promoWidth,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color.withOpacity(0.8),
                                    color.withOpacity(0.6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -20,
                                    bottom: -20,
                                    child: CircleAvatar(
                                      radius: isSmallScreen ? 60 : 80,
                                      backgroundColor: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  Positioned(
                                    left: -20,
                                    top: -20,
                                    child: CircleAvatar(
                                      radius: isSmallScreen ? 30 : 40,
                                      backgroundColor: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            "OFERTA ESPECIAL",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          promo['title']!,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 18 : 22,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          promo['description']!,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: isSmallScreen ? 12 : 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            "Aproveitar",
                                            style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Estatísticas do usuário
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Suas estatísticas",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                "12", 
                                "Corridas", 
                                Icons.motorcycle, 
                                Colors.blue[700]!,
                                isSmallScreen
                              ),
                              _buildStatItem(
                                "103km", 
                                "Percorridos", 
                                Icons.map, 
                                Colors.green[700]!,
                                isSmallScreen
                              ),
                              _buildStatItem(
                                "R\$159", 
                                "Economizados", 
                                Icons.savings, 
                                Colors.amber[700]!,
                                isSmallScreen
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RideHistoryScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Ver histórico de corridas"),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botão para mudar para motorista
                    GestureDetector(
                      onTap: () {
                        context.read<AuthBloc>().add(const SwitchUserType('driver'));
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber[700]!, Colors.amber[800]!],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: isSmallScreen ? 20 : 25,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              child: const Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Mudar para Motorista",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Ganhe dinheiro levando passageiros",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String value, String label, IconData icon, Color color, bool isSmallScreen) {
    return Column(
      children: [
        CircleAvatar(
          radius: isSmallScreen ? 20 : 25,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            icon,
            color: color,
            size: isSmallScreen ? 16 : 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isSmallScreen ? 10 : 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}