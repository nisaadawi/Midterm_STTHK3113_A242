import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double temperature = 26.0;
  double humidity = 70.0;
  bool relayOn = true;
  double tempThreshold = 28.0;
  double humThreshold = 75.0;
  String statusMessage = "Temperature is on average";
  List<double> tempTrend = [24, 25, 26, 27, 28, 27, 26, 28, 29, 30];
  List<double> humTrend = [60, 62, 65, 68, 70, 72, 74, 73, 71, 70];

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'DHT11 DASHBOARD',
          style: GoogleFonts.righteous(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFD600), Color(0xFFFFA000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        toolbarHeight: 120,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sensor Readings Header and Relay Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sensor Readings',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFA000),
                    ),
                  ),
                  Row(
                    children: [
                      const Text('Relay Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(width: 8),
                      Switch(
                        value: relayOn,
                        activeColor: const Color(0xFFFFD600),
                        onChanged: (val) => setState(() => relayOn = val),
                      ),
                      Text(relayOn ? 'ON' : 'OFF', style: TextStyle(color: relayOn ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Meters
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MeterWidget(
                    value: temperature,
                    min: 0,
                    max: 50,
                    label: 'Temperature',
                    unit: '°C',
                    color: const Color(0xFFFFA000),
                  ),
                  _MeterWidget(
                    value: humidity,
                    min: 0,
                    max: 100,
                    label: 'Humidity',
                    unit: '%',
                    color: const Color(0xFFFFA000),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Current Threshold
              Text('Current Treshold', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.5))),
              const SizedBox(height: 8),
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFFD600), width: 1)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Temp ', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${tempThreshold.toInt()}c', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                          const SizedBox(width: 16),
                          Text('Hum ', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${humThreshold.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD600),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: _showThresholdDialog,
                            child: const Text('Change Treshold', style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Status Message', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black.withOpacity(0.5))),
                      Text(statusMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Statistical Trends
              Text('Statistical Trends', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFFFA000))),
              const SizedBox(height: 8),
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Temperature Line Graph
                      Row(
                        children: [
                          const RotatedBox(
                            quarterTurns: -1,
                            child: Text('Temperature', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFA000))),
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 100,
                              child: LineChart(
                                LineChartData(
                                  minY: 0,
                                  maxY: 50,
                                  gridData: FlGridData(show: true, horizontalInterval: 10, getDrawingHorizontalLine: (value) => FlLine(color: Colors.black12, strokeWidth: 1)),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          int index = value.toInt();
                                          if (index % 2 == 0 && index < tempTrend.length) {
                                            return Text('$index', style: const TextStyle(fontSize: 10, color: Colors.black));
                                          }
                                          return Container();
                                        },
                                        interval: 1,
                                        reservedSize: 32,
                                      ),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: tempTrend.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value)).toList(),
                                      isCurved: true,
                                      color: const Color(0xFFFFA000),
                                      barWidth: 3,
                                      dotData: FlDotData(show: true),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Humidity Line Graph
                      Row(
                        children: [
                          RotatedBox(
                            quarterTurns: -1,
                            child: Text('Humidity', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 100,
                              child: LineChart(
                                LineChartData(
                                  minY: 0,
                                  maxY: 100,
                                  gridData: FlGridData(show: true, horizontalInterval: 20, getDrawingHorizontalLine: (value) => FlLine(color: Colors.black12, strokeWidth: 1)),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          int index = value.toInt();
                                          if (index % 2 == 0 && index < humTrend.length) {
                                            return Text('$index', style: const TextStyle(fontSize: 10, color: Colors.black));
                                          }
                                          return Container();
                                        },
                                        interval: 1,
                                        reservedSize: 32,
                                      ),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: humTrend.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value)).toList(),
                                      isCurved: true,
                                      color: Colors.blue,
                                      barWidth: 3,
                                      dotData: FlDotData(show: true),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Meter Widget
class _MeterWidget extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String label;
  final String unit;
  final Color color;

  const _MeterWidget({
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.unit,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double percent = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.7)],
          center: Alignment.center,
          radius: 0.8,
        ),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, spreadRadius: 2)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _MeterPainter(percent: percent, color: color),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${value.toInt()}${unit}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double percent;
  final Color color;
  _MeterPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final startAngle = 3.14 * 0.75;
    final sweepAngle = 3.14 * 1.5 * percent;
    final bgPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    final fgPaint = Paint()
      ..shader = SweepGradient(
        colors: [color, color.withOpacity(0.2)],
        startAngle: startAngle,
        endAngle: startAngle + 3.14 * 1.5,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    // Draw background arc
    canvas.drawArc(rect.deflate(16), startAngle, 3.14 * 1.5, false, bgPaint);
    // Draw value arc
    canvas.drawArc(rect.deflate(16), startAngle, sweepAngle, false, fgPaint);
    // Draw pointer
    final pointerAngle = startAngle + sweepAngle;
    final pointerLength = size.width / 2 - 24;
    final pointerOffset = Offset(
      size.width / 2 + pointerLength * math.cos(pointerAngle),
      size.height / 2 + pointerLength * math.sin(pointerAngle),
    );
    final pointerPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(size.center(Offset.zero), pointerOffset, pointerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 