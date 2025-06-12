import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapaPantalla(),
    );
  }
}

class MapaPantalla extends StatefulWidget {
  const MapaPantalla({super.key});

  @override
  State<MapaPantalla> createState() => _MapaPantallaState();
}

class _MapaPantallaState extends State<MapaPantalla> {
  LatLng? _ubicacionActual;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  Future<void> _obtenerUbicacion() async {
    var permiso = await Permission.location.request();
    if (permiso.isGranted) {
      Position posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _ubicacionActual = LatLng(posicion.latitude, posicion.longitude);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permiso de ubicación denegado")),
      );
    }
  }

  Future<void> _enviarUbicacionAlServidor() async {
    if (_ubicacionActual == null) return;

    final url = Uri.parse(
      "https://monitoreo-flotas.onrender.com/api/ubicacion",
    );

    final datos = {
      "latitud": _ubicacionActual!.latitude,
      "longitud": _ubicacionActual!.longitude,
      "dispositivo": "celular_juan",
      "timestamp": DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final respuesta = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(datos),
      );

      if (respuesta.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ubicación enviada con éxito")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error del servidor: ${respuesta.statusCode}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error de red: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi ubicación en el mapa")),
      body: _ubicacionActual == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(center: _ubicacionActual, zoom: 15),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.ejemplo.ubicacionmapa',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _ubicacionActual!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _enviarUbicacionAlServidor,
        icon: const Icon(Icons.send),
        label: const Text("Enviar"),
      ),
    );
  }
}
