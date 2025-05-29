import 'package:flutter/material.dart' hide Threshold;
import 'package:flutter_dht11_apps/models/dashboard.dart';
import 'package:flutter_dht11_apps/myconfig.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_dht11_apps/models/threshold.dart';
import 'package:flutter_dht11_apps/views/dht_history_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double temperature = 0.0;
  double humidity = 0.0;
  String relayStatus = "Off";
  Timer? _timer;
  List<Dashboard> dashboards = [];
  double tempThreshold = 0;
  double humThreshold = 0.0;


  // Function to update thresholds in the database
  Future<void> updateThresholds(double temp, double hum) async {
    try {
      final response = await http.post(
        Uri.parse('${MyConfig.servername}/DHT11/update_threshold.php'),
        body: {
          'temp_treshold': temp.toString(),
          'hum_treshold': hum.toString(),
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          // Show success popup
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Thresholds updated successfully!',
                      style: GoogleFonts.righteous(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(10),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Update failed: ${jsonResponse['message']}',
                      style: GoogleFonts.righteous(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(10),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Server error: ${response.statusCode}',
                    style: GoogleFonts.righteous(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Error: $e',
                  style: GoogleFonts.righteous(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) => fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('${MyConfig.servername}/DHT11/fetch.php?device_id=103'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
          var data = jsonResponse['data'];
          List<Dashboard> dashboards = [];

          if (data is List) {
            dashboards = data.map((item) => Dashboard.fromJson(item)).toList();
          } else if (data is Map) {
            dashboards = [Dashboard.fromJson(data as Map<String, dynamic>)];
          }

        setState(() {
            this.dashboards = dashboards;

            if (dashboards.isNotEmpty) {
              temperature = dashboards.first.temperature;
              humidity = dashboards.first.humidity;
              relayStatus = dashboards.first.relayStatus;
            }
          });
        } else {
          print('API Error: ${jsonResponse['message']}');
        }
      } else {
        print('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch error: $e');
    }

    try {
      final thresholdResponse = await http.get(
        Uri.parse('${MyConfig.servername}/DHT11/fetch_threshold.php?'),
      );

      if (thresholdResponse.statusCode == 200) {
        final thresholdJsonResponse = json.decode(thresholdResponse.body);

        if (thresholdJsonResponse['status'] == 'success' && thresholdJsonResponse['data'] != null) {
          var thresholdData = thresholdJsonResponse['data'];
          if (thresholdData is Map<String, dynamic>) {
            Threshold threshold = Threshold.fromJson(thresholdData);
            setState(() {
              tempThreshold = threshold.temp_treshold;
              humThreshold = threshold.hum_treshold;
            });
          }
        } else {
          print('Threshold API Error: ${thresholdJsonResponse['message']}');
        }
      } else {
        print('Threshold Server error: ${thresholdResponse.statusCode}');
      }
    } catch (e) {
      print('Threshold Fetch error: $e');
    }
  }

   void _showThresholdDialog() {
    double newTemp = tempThreshold;
    double newHum = humThreshold;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Temp Threshold (°C)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => newTemp = double.tryParse(val) ?? tempThreshold,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Hum Threshold (%)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => newHum = double.tryParse(val) ?? humThreshold,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD600)),
            onPressed: () {
              setState(() {
                tempThreshold = newTemp;
                humThreshold = newHum;
              });
              updateThresholds(newTemp, newHum);
              Navigator.pop(context);
            },
            child: const Text('Set', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DHT11 DASHBOARD',
          style: GoogleFonts.righteous(
            fontSize:28 ,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),      
        ),
        centerTitle: true,
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bg/homepage.jpg'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
        ),
        toolbarHeight: 100,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DHTHistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:  SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color.fromARGB(255, 249, 232, 179), Color.fromARGB(255, 248, 204, 8)], // White, Soft Yellow, Yellow gradient
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sensor Readings Header and Relay Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      'Sensor Readings',
                      style: GoogleFonts.righteous(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFA000),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
                    child: Card(
                      color: relayStatus == 'On' ? const Color.fromARGB(255, 8, 168, 40) : Colors.red,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Column(
                          children: [
                            Text(
                              'Relay Status',
                              style: GoogleFonts.righteous(
                                fontSize: 12, 
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              relayStatus,
                              style: GoogleFonts.righteous(
                                fontSize: 14, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MeterWidget(
                    value: temperature,
                    min: 0,
                    max: 50,
                    label: 'Temperature',
                    unit: '°C',
                    color: Colors.deepOrange,
                  ),
                  _MeterWidget(
                    value: humidity,
                    min: 0,
                    max: 100,
                    label: 'Humidity',
                    unit: '%',
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
             
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(dashboards.isNotEmpty ? 'Last Updated: ${dashboards.first.timestamp}' : 'No Data Available',
                                style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ),
              // Current Threshold
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Current Threshold', style: GoogleFonts.righteous(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFFFFA000))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFFD600), width: 1)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD600), Color(0xFFFFA000)], // White to soft yellow gradient
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Temperature ', style: GoogleFonts.righteous(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                              Text('${tempThreshold.toInt()}°C', style: GoogleFonts.righteous(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.deepOrange)),
                              const SizedBox(width: 16),
                              Text('Humidity ', style: GoogleFonts.righteous(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                              Text('${humThreshold.toInt()}%', style: GoogleFonts.righteous(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.blue)),
                              const Spacer(),
                            ],
                          ),
                          Text('Status Message', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black54)),
                          Text(
                            temperature > tempThreshold && humidity > humThreshold
                                ? 'Temperature and Humidity Exceeding!'
                                : temperature > tempThreshold
                                    ? 'Temperature Exceeding!'
                                    : humidity > humThreshold
                                        ? 'Humidity Exceeding!'
                                        : 'Normal Temperature and Humidity',
                            style: TextStyle(
                              fontSize: 16,
                              color: temperature > tempThreshold || humidity > humThreshold
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Spacer(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 255, 255, 255)),
                                onPressed: _showThresholdDialog,
                                child: Text('Set Threshold', style: GoogleFonts.montserrat(color: const Color.fromARGB(255, 230, 169, 26), fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Statistic & Trends', style: GoogleFonts.righteous(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFFFFA000))),
              ),
              // Temperature Trend Graph
              Column(
                children: [
                  // Temperature Trend Graph Card
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.white,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        collapsedIconColor: Colors.deepOrange,
                        iconColor: Colors.deepOrange,
                        title: Row(
                          children: [
                            const Icon(Icons.thermostat, color: Colors.deepOrange, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Temperature Trend',
                              style: GoogleFonts.righteous(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            )
                          ],
                        ),
                        children: [
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true, horizontalInterval: 0.2, getDrawingHorizontalLine: (value) => FlLine(color: Colors.deepOrange.withOpacity(0.1), strokeWidth: 1)),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text('${value.toStringAsFixed(1)}', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12))),
                                      axisNameWidget: const Padding(
                                        padding: EdgeInsets.only(right: 6.0),
                                        child: Text('°C', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 12)),
                                      ),
                                      axisNameSize: 20,
                                    ),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          int index = value.toInt();
                                          if (index % 2 == 0 && index <= 20 && index < dashboards.length) {
                                            return Text('$index', style: const TextStyle(fontSize: 10, color: Colors.deepOrange));
                                          }
                                          return Container();
                                        },
                                        interval: 1,
                                        reservedSize: 24,
                                      ),
                                      axisNameWidget: const Padding(
                                        padding: EdgeInsets.only(top: 6.0),
                                        child: Text('Time (10s)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 12)),
                                      ),
                                      axisNameSize: 20,
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: dashboards.asMap().entries.map((entry) {
                                        return FlSpot(entry.key.toDouble(), entry.value.temperature);
                                      }).toList(),
                                      isCurved: true,
                                      color: Colors.deepOrange,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.deepOrange.withOpacity(0.2),
                                      ),
                                    ),
                                  ],
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                        return touchedBarSpots.map((barSpot) {
                                          final d = dashboards[barSpot.x.toInt()];
                                          return LineTooltipItem(
                                            'Temp: ${d.temperature}°C\nHum: ${d.humidity}%\n${d.timestamp}',
                                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceBetween,
                                  maxY: dashboards.map((d) => d.temperature).fold<double>(0, (prev, t) => t > prev ? t : prev) + 2,
                                  minY: dashboards.map((d) => d.temperature).fold<double>(100, (prev, t) => t < prev ? t : prev) - 2,
                                  gridData: FlGridData(show: true, horizontalInterval: 0.2, getDrawingHorizontalLine: (value) => FlLine(color: Colors.deepOrange.withOpacity(0.1), strokeWidth: 1)),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text('${value.toStringAsFixed(1)}', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12))),
                                      axisNameWidget: const Padding(
                                        padding: EdgeInsets.only(right: 6.0),
                                        child: Text('°C', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 12)),
                                      ),
                                      axisNameSize: 20,
                                    ),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          int index = value.toInt();
                                          if (index % 2 == 0 && index <= 20 && index < dashboards.length) {
                                            return Text('$index', style: const TextStyle(fontSize: 10, color: Colors.deepOrange));
                                          }
                                          return Container();
                                        },
                                        interval: 1,
                                        reservedSize: 24,
                                      ),
                                      axisNameWidget: const Padding(
                                        padding: EdgeInsets.only(top: 6.0),
                                        child: Text('Time (10s)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 12)),
                                      ),
                                      axisNameSize: 20,
                                    ),
                                  ),
                                  barGroups: dashboards.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    final d = entry.value;
                                    return BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: d.temperature,
                                          width: 10, // Adjusted bar width
                                          borderRadius: BorderRadius.circular(5), // Adjusted border radius
                                          gradient: const LinearGradient(
                                            colors: [Colors.deepOrange, Color.fromARGB(255, 251, 237, 217)],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                          rodStackItems: [],
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        final d = dashboards[group.x.toInt()];
                                        return BarTooltipItem(
                                          'Temp: ${d.temperature}°C\nHum: ${d.humidity}%\n${d.timestamp}',
                                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), // Adjusted font size
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  //Humidity Trend Graph Card
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.white,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        collapsedIconColor: Colors.blue,
                        iconColor: Colors.blue,
                        title: Row(
                          children: [
                            const Icon(Icons.water_drop, color: Colors.blue, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Humidity Trend',
                              style: GoogleFonts.righteous(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                           const SizedBox(
                              height: 8,
                            )
                          ],
                        ),
                        children: [
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true, horizontalInterval: 10, getDrawingHorizontalLine: (value) => FlLine(color: Colors.blue.withOpacity(0.1), strokeWidth: 1)),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text('${value.toStringAsFixed(0)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12))),
                                      axisNameWidget: const Padding(
                                        padding: EdgeInsets.only(right: 6.0),
                                        child: Text('%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                                      ),
                                      axisNameSize: 20,
                                    ),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          int index = value.toInt();
                                          if (index % 2 == 0 && index <= 20 && index < dashboards.length) {
                                            return Text('$index', style: const TextStyle(fontSize: 10, color: Colors.blue));
                                          }
                                          return Container();
                                        },
                                        interval: 1,
                                        reservedSize: 24,
                                      ),
                                      axisNameWidget: const Padding(
                                        padding: EdgeInsets.only(top: 6.0),
                                        child: Text('Time (10s)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                                      ),
                                      axisNameSize: 20,
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: dashboards.asMap().entries.map((entry) {
                                        return FlSpot(entry.key.toDouble(), entry.value.humidity);
                                      }).toList(),
                                      isCurved: true,
                                      color: Colors.blue,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.blue.withOpacity(0.2),
                                      ),
                                    ),
                                  ],
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                        return touchedBarSpots.map((barSpot) {
                                          final d = dashboards[barSpot.x.toInt()];
                                          return LineTooltipItem(
                                            'Temp: ${d.temperature}°C\nHum: ${d.humidity}%\n${d.timestamp}',
                                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceBetween,
                                  maxY: 100,
                                  minY: 0,
                                  gridData: FlGridData(show: true, horizontalInterval: 10, getDrawingHorizontalLine: (value) => FlLine(color: Colors.blue.withOpacity(0.1), strokeWidth: 1)),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text('${value.toStringAsFixed(0)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12))),
                                      axisNameWidget: const Padding(
                                        padding: EdgeInsets.only(right: 6.0),
                                        child: Text('%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                                      ),
                                      axisNameSize: 20,
                                    ),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          int index = value.toInt();
                                          if (index % 2 == 0 && index <= 20 && index < dashboards.length) {
                                            return Text('$index', style: const TextStyle(fontSize: 10, color: Colors.blue));
                                          }
                                          return Container();
                                        },
                                        interval: 1,
                                        reservedSize: 24,
                                      ),
                                      axisNameWidget: const Padding(
                                        padding: EdgeInsets.only(top: 6.0),
                                        child: Text('Time (10s)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                                      ),
                                      axisNameSize: 20,
                                    ),
                                  ),
                                  barGroups: dashboards.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    final d = entry.value;
                                    return BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: d.humidity,
                                          width: 10, // Adjusted bar width
                                          borderRadius: BorderRadius.circular(5), // Adjusted border radius
                                          gradient: const LinearGradient(
                                            colors: [Colors.blue, Colors.lightBlueAccent],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                          rodStackItems: [],
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        final d = dashboards[group.x.toInt()];
                                        return BarTooltipItem(
                                          'Temp: ${d.temperature}°C\nHum: ${d.humidity}%\n${d.timestamp}',
                                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), // Adjusted font size
                                        );
                                      },
                                    ),
                                  ),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
}

class _MeterWidget extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String label;
  final String unit;
  final Color color;

  const _MeterWidget({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.unit,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.white, color.withOpacity(0.3)], // White to accent color gradient
              begin: Alignment.center,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: min,
                  maximum: max,
                  interval: (max - min) / 2, // Interval for 0, max/2, max
                  showLabels: true,
                  showTicks: true,
                  startAngle: 180,
                  endAngle: 0,
                  axisLineStyle: AxisLineStyle(
                    thickness: 0.02,
                    thicknessUnit: GaugeSizeUnit.factor,
                    color: Colors.black.withOpacity(0.1),
                  ),
                  majorTickStyle: const MajorTickStyle(length: 0.15, thickness: 2, color: Colors.black54, lengthUnit: GaugeSizeUnit.factor),
                  minorTickStyle: const MinorTickStyle(length: 0.05, thickness: 1, color: Colors.black38, lengthUnit: GaugeSizeUnit.factor),
                  axisLabelStyle: const GaugeTextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: value,
                      width: 0.18,
                      sizeUnit: GaugeSizeUnit.factor,
                      color: color, // Use the passed color for the range
                      enableAnimation: true,
                      animationType: AnimationType.ease,
                      animationDuration: 800,
                      cornerStyle: CornerStyle.bothCurve,
                    ),
                    NeedlePointer(
                      value: value,
                      enableAnimation: true,
                      animationType: AnimationType.ease,
                      animationDuration: 800,
                      needleColor: Colors.black, // Black needle
                      needleLength: 0.7,
                      needleStartWidth: 1,
                      needleEndWidth: 4,
                      knobStyle: const KnobStyle(
                        color: Colors.black, // Solid black knob
                        knobRadius: 0.06,
                        sizeUnit: GaugeSizeUnit.factor,
                      ),
                      tailStyle: const TailStyle() // No tail
                    ),
                  ],
                   annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Text(
                        '${value.toStringAsFixed(1)}${unit}',
                        style: GoogleFonts.righteous(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      angle: 90,
                      positionFactor: 0.7,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8), // Space between gauge and value
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
