import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TestMapScreen extends StatefulWidget {
  @override
  _TestMapScreenState createState() => _TestMapScreenState();
}

class _TestMapScreenState extends State<TestMapScreen> {
  GoogleMapController? mapController;
  bool _isMapLoaded = false;
  int _retryCount = 0;
  
  void _retryLoadMap() {
    if (_retryCount < 3) {
      setState(() {
        _retryCount++;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Teste de Mapa")),
      body: Stack(
        children: [
          // Fundo de backup
          Container(color: Colors.grey[200]),
          
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(-8.0476, -34.8770), // Centro de Recife
              zoom: 14.0,
            ),
            mapType: MapType.normal,
            zoomControlsEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            trafficEnabled: false,
            buildingsEnabled: true,
            indoorViewEnabled: true,
            onMapCreated: (controller) {
              setState(() {
                mapController = controller;
                _isMapLoaded = true;
                print("Mapa de teste criado com sucesso!");
              });
            },
          ),
          
          // Controles de depuração
          Positioned(
            bottom: 80,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "btn1",
                  child: Icon(Icons.refresh),
                  onPressed: () {
                    if (mapController != null) {
                      print("Recarregando mapa...");
                      mapController!.moveCamera(
                        CameraUpdate.newLatLng(LatLng(-8.0476, -34.8770))
                      );
                    }
                  },
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "btn2",
                  child: Icon(Icons.map),
                  onPressed: () {
                    if (mapController != null) {
                      print("Alternando tipo de mapa...");
                      setState(() {
                        // Alternar entre os tipos de mapa
                        _retryLoadMap();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}