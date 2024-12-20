import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, dynamic>? weatherData;
  Map<String, dynamic>? forecastData; // Variable para el pronóstico de 5 días.
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El servicio de localización está desactivado.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de localización denegado.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Los permisos de localización están permanentemente denegados.');
    }

    var locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Opcional
    );

    return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings);
  }

  Future<void> fetchWeather() async {
    final apiKey = 'f4c3f0a6b0744c1926834b252ed84c4d';

    try {
      Position position = await _getCurrentLocation();
      final lat = position.latitude;
      final lon = position.longitude;

      // URL para obtener el clima actual
      final currentWeatherUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&lang=es&units=metric',
      );

      // URL para obtener el pronóstico de 5 días
      final forecastUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&lang=es&units=metric',
      );

      // solicita el clima actual
      final currentWeatherResponse = await http.get(currentWeatherUrl);
      if (currentWeatherResponse.statusCode == 200) {
        setState(() {
          weatherData = json.decode(currentWeatherResponse.body);
        });
      } else {
        setState(() {
          weatherData = {
            'error': 'No se pudo obtener los datos del clima actual.'
          };
        });
      }

      // solicita el pronóstico de 5 días
      final forecastResponse = await http.get(forecastUrl);
      if (forecastResponse.statusCode == 200) {
        setState(() {
          forecastData = json.decode(forecastResponse.body);
          isLoading = false;
        });
      } else {
        setState(() {
          forecastData = {
            'error': 'No se pudo obtener el pronóstico de 5 días.'
          };
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        weatherData = {'error': 'Error de conexión o permisos: $e'};
        forecastData = {'error': 'Error de conexión o permisos: $e'};
        isLoading = false;
      });
    }
  }

  Color _getBackgroundColor(double temp) {
    if (temp > 30) {
      return Colors.orangeAccent;
    } else if (temp > 20) {
      return Colors.blueAccent;
    } else {
      return Colors.lightBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Clima'),
          backgroundColor: Colors.blueAccent,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: weatherData == null || weatherData!.containsKey('error')
                    ? Center(
                        child: Text(
                          weatherData?['error'] ?? 'Error desconocido.',
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // clima actual
                            AnimatedContainer(
                              duration: Duration(seconds: 1),
                              decoration: BoxDecoration(
                                color: _getBackgroundColor(
                                    weatherData!['main']['temp']),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
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
                                    "${weatherData!['name']}, ${weatherData!['sys']['country']}",
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Sensación térmica: ${weatherData!['main']['feels_like']}°C",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "${weatherData!['weather'][0]['description']}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Humedad: ${weatherData!['main']['humidity']}%",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Viento: ${weatherData!['wind']['speed']} m/s",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 30),
                            // pronóstico de los próximos 5 días
                            Text(
                              "Pronóstico para los próximos 5 días:",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            SizedBox(height: 10),
                            // mostrar pronóstico para los próximos 5 días itero
                            for (var i = 0; i < 5; i++)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: _buildDayForecast(i),
                              ),
                          ],
                        ),
                      ),
              ),
      ),
    );
  }

  Widget _buildDayForecast(int index) {
    //  obtiene información para el pronóstico de cada día.
    var forecast = forecastData!['list']
        [index * 8]; // cada 8 elementos son un día (24 hs).
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${forecast['dt_txt']}",
            style: TextStyle(fontSize: 18),
          ),
          Row(
            children: [
              Image.network(
                'http://openweathermap.org/img/wn/${forecast['weather'][0]['icon']}@2x.png',
                width: 40,
                height: 40,
              ),
              SizedBox(width: 10),
              Text(
                "${forecast['main']['temp']}°C",
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
