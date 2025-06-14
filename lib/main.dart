import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ubicación Manual',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  String _estado = '';

  Future<void> _enviarUbicacion() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _estado = 'Por favor, ingresa una URL válida.';
      });
      return;
    }

    try {
      bool servicio = await Geolocator.isLocationServiceEnabled();
      if (!servicio) {
        setState(() {
          _estado = 'Activa los servicios de ubicación.';
        });
        return;
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          setState(() {
            _estado = 'Permiso de ubicación denegado.';
          });
          return;
        }
      }

      if (permiso == LocationPermission.deniedForever) {
        setState(() {
          _estado = 'Permiso denegado permanentemente.';
        });
        return;
      }

      Position posicion = await Geolocator.getCurrentPosition();
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"latitud": ${posicion.latitude}, "longitud": ${posicion.longitude}}',
      );

      setState(() {
        _estado = 'Respuesta del servidor: ${response.statusCode}';
      });
    } catch (e) {
      setState(() {
        _estado = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar Ubicación')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL del servidor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _enviarUbicacion,
              icon: const Icon(Icons.send),
              label: const Text('Enviar Ubicación'),
            ),
            const SizedBox(height: 20),
            Text(_estado),
          ],
        ),
      ),
    );
  }
}
