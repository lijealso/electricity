import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Informação',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ElectricityInfoHome(),
    );
  }
}

class ElectricityInfoHome extends StatefulWidget {
  const ElectricityInfoHome({super.key});

  @override
  State<ElectricityInfoHome> createState() => _ElectricityInfoHomeState();
}

class _ElectricityInfoHomeState extends State<ElectricityInfoHome> {
  String _carbonIntensity = 'A carregar informação...';
  Map<String, dynamic> _powerBreakdown = {};
  String _lastUpdated = '';

  final String _apiKey = 'API-KEY';

  final Map<String, String> _powerSourceTranslations = {
    'biomass': 'Biomassa',
    'coal': 'Carvão',
    'gas': 'Gás',
    'geothermal': 'Geotérmica',
    'hydro': 'Hídrica',
    'nuclear': 'Nuclear',
    'oil': 'Petróleo',
    'solar': 'Solar',
    'wind': 'Eólica',
    'unknown': 'Desconhecido',
    'hydro discharge': 'Descarga hidráulica',
    '': '',
    // Add more as needed
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _fetchCarbonIntensity();
    await _fetchPowerBreakdown();
  }

  Future<void> _fetchCarbonIntensity() async {
    const zone = 'PT';
    final url = Uri.parse(
      'https://api.electricitymap.org/v3/carbon-intensity/latest?zone=$zone',
    );

    try {
      final response = await http.get(url, headers: {'auth-token': _apiKey});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _carbonIntensity = '${data['carbonIntensity']}';
          _lastUpdated = DateFormat.yMMMd().add_jm().format(
            DateTime.parse(data['datetime']),
          );
        });
      } else {
        setState(() {
          _carbonIntensity = 'Failed to load data';
        });
      }
    } catch (e) {
      setState(() {
        _carbonIntensity = 'Error: $e';
      });
    }
  }

  Future<void> _fetchPowerBreakdown() async {
    const zone = 'PT';
    final url = Uri.parse(
      'https://api.electricitymap.org/v3/power-breakdown/latest?zone=$zone',
    );

    try {
      final response = await http.get(url, headers: {'auth-token': _apiKey});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _powerBreakdown = data['powerProductionBreakdown'];
        });
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informação')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: const Text('Intensidade carbónica', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      _carbonIntensity,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Valor em gCO2eq/kWh',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Atualizado em: $_lastUpdated',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Power Breakdown',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              if (_powerBreakdown.isNotEmpty)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 260,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (_powerBreakdown.values.isNotEmpty)
                              ? (_powerBreakdown.values
                                        .map(
                                          (v) => v is num ? v.toDouble() : 0.0,
                                        )
                                        .reduce((a, b) => a > b ? a : b) *
                                    1.1)
                              : 100,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= _powerBreakdown.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final key = _powerBreakdown.keys
                                          .elementAt(index);
                                      final translated =
                                          _powerSourceTranslations[key] ?? key;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          translated.substring(0, 1),
                                          style: const TextStyle(fontSize: 10),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(_powerBreakdown.length, (i) {
                            final key = _powerBreakdown.keys.elementAt(i);
                            final value = _powerBreakdown[key];
                            final color =
                                Colors.primaries[i % Colors.primaries.length];
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: (value is num) ? value.toDouble() : 0.0,
                                  color: color,
                                  width: 18,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (_powerBreakdown.isEmpty)
                const Center(child: CircularProgressIndicator()),
              if (_powerBreakdown.isNotEmpty)
                ..._powerBreakdown.entries.map((entry) {
                  final translated =
                      _powerSourceTranslations[entry.key] ?? entry.key;
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(translated),
                      trailing: Text('${entry.value} MW'),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
