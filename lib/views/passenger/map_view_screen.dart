// Arquivo: lib/views/passenger/map_view_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapViewScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String title;

  const MapViewScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.title,
  }) : super(key: key);

  @override
  _MapViewScreenState createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final Set<Marker> _markers = {};
  late CameraPosition _initialPosition;
  
  @override
  void initState() {
    super.initState();
    
    // Configurar posição inicial
    _initialPosition = CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: 16.0,
    );
    
    // Adicionar marcador
    _markers.add(
      Marker(
        markerId: MarkerId('shared_location'),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(title: 'Localização compartilhada'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
        zoomControlsEnabled: true,
        compassEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          // Se necessário, manipular o controlador do mapa
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.directions),
        onPressed: () {
          // Lançar app de navegação externo com estas coordenadas
          _launchMapsNavigation();
        },
      ),
    );
  }
  
  void _launchMapsNavigation() {
    // Esta função seria implementada com o pacote url_launcher
    // para abrir o Google Maps ou Apple Maps com a navegação
    // para as coordenadas especificadas
    
    // Por enquanto, apenas mostrar um SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegação externa não implementada'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
    
    // Implementação real seria algo como:
    // final url = 'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}';
    // if (await canLaunch(url)) {
    //   await launch(url);
    // } else {
    //   throw 'Não foi possível abrir $url';
    // }
  }
}