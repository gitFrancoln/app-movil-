import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, dynamic>? weatherData; // Mapa para almacenar los datos del clima
  bool isLoading = true; // Estado de carga

  @override
  void initState() {
    super.initState();
    fetchWeather(); // Llamar a la API al iniciar
  }

  // Función para obtener los datos desde la API
  Future<void> fetchWeather() async {
    final apiKey = 'f4c3f0a6b0744c1926834b252ed84c4d'; // Tu clave API
    final city = 'Buenos Aires'; // Ciudad que deseas consultar
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&lang=es&units=metric'); // URL de la API

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          weatherData = json
              .decode(response.body); // Decodificar JSON y almacenar los datos
          isLoading = false; // Los datos han llegado
        });
      } else {
        setState(() {
          weatherData = {'error': 'No se pudo obtener los datos del clima.'};
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        weatherData = {'error': 'Error de conexión. Intenta más tarde.'};
        isLoading = false;
      });
    }
  }

  // Función para determinar el color de fondo basado en la temperatura
  Color _getBackgroundColor(double temp) {
    if (temp > 30) {
      return Colors.orangeAccent; // Muy caliente
    } else if (temp > 20) {
      return Colors.blueAccent; // Temperatura agradable
    } else {
      return Colors.lightBlue; // Frío
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Clima en Flutter'),
          backgroundColor: Colors.teal,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator()) // Cargando
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: weatherData == null || weatherData!.containsKey('error')
                    ? Center(
                        child: Text(
                          weatherData?['error'] ?? 'Error desconocido.',
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color:
                              _getBackgroundColor(weatherData!['main']['temp']),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icono del clima
                                Image.network(
                                  'http://openweathermap.org/img/wn/${weatherData!['weather'][0]['icon']}@2x.png',
                                  width: 60,
                                  height: 60,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "${weatherData!['main']['temp']}°C",
                                  style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Text(
                              "${weatherData!['weather'][0]['description']}",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Humedad: ${weatherData!['main']['humidity']}%",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Ciudad: ${weatherData!['name']}",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
      ),
    );
  }
}
