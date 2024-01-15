import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'color.dart';
import 'dart:async';

String customLink = '';


class GraphPage extends StatefulWidget {
  @override
  _GraphPageState createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  // List untuk menyimpan data sensor
  List<double> temperatures = [];
  List<double> turbidities = [];
  List<double> liters = [];

  // List untuk menyimpan perubahan data sensor
  List<double> temperatureChanges = [];
  List<double> turbidityChanges = [];
  List<double> literChanges = [];

  // List untuk menyimpan timestamp
  List<DateTime> timestamps = [];

  // Timer untuk pengambilan data secara berkala
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchDataFromAPI();

    // Timer yang memicu fungsi _fetchDataFromAPI setiap 30 detik
    _timer = Timer.periodic(Duration(seconds: 30), (Timer t) => _fetchDataFromAPI());
  }

  @override
  void dispose() {
    // Membatalkan timer untuk mencegah memory leak
    _timer.cancel();
    super.dispose();
  }

  // Fungsi untuk mengambil data dari API
  Future<void> _fetchDataFromAPI() async {
    //urlnya dari web yang kita buat, webnya sudah connect ke mqtt
    final url = Uri.parse(customLink.isNotEmpty ? customLink : 'https://f0cb-103-104-130-7.ngrok-free.app/api/sensordata');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          double latestTemperature = double.parse(data['latestTemperature'].toString());
          double latestTurbidity = double.parse(data['latestTurbidity'].toString());
          double latestLiter = double.parse(data['latestDistance'].toString());

          // Menambahkan data terbaru ke dalam list
          temperatures.add(latestTemperature);
          turbidities.add(latestTurbidity);
          liters.add(latestLiter);
          timestamps.add(DateTime.now()); // Menambahkan timestamp saat ini

          // Menghitung perubahan data dan menambahkannya ke dalam list perubahan
          if (temperatures.length > 1) {
            temperatureChanges.add(latestTemperature - temperatures[temperatures.length - 2]);
          }
          if (turbidities.length > 1) {
            turbidityChanges.add(latestTurbidity - turbidities[turbidities.length - 2]);
          }
          if (liters.length > 1) {
            literChanges.add(latestLiter - liters[liters.length - 2]);
          }
        });
      } else {
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fungsi untuk membangun UI grafik
    return Scaffold(
      appBar: AppBar(
        title: Text('Graphs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildLineGraph(
                temperatureChanges, AppColors.primaryColor, 'Temperature Change (°C)'),
            SizedBox(height: 20),
            _buildLineGraph(
                turbidityChanges, AppColors.accentColor, 'Turbidity Change (NTU)'),
            SizedBox(height: 20),
            _buildLineGraph(literChanges, AppColors.tertiaryColor, 'Liter Change (cm)'),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk membangun komponen grafik garis
  Widget _buildLineGraph(List<double> data, Color color, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: data
                        .asMap()
                        .entries
                        .map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    color: color,
                    barWidth: 4,
                    isCurved: true,
                    belowBarData: BarAreaData(show: false),
                    dotData: FlDotData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  show: false, // Ini akan menyembunyikan semua judul
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
